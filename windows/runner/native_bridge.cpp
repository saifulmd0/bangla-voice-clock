#include "native_bridge.h"

#include <appmodel.h>
#include <dwmapi.h>
#include <flutter/standard_method_codec.h>
#include <mmdeviceapi.h>
#include <mmsystem.h>
#include <objbase.h>

#include <winrt/Windows.ApplicationModel.h>
#include <winrt/Windows.Foundation.h>

#include <algorithm>
#include <cstring>
#include <thread>

#include "resource.h"

namespace {

constexpr UINT kTrayMessage = WM_APP + 1;
// Also posted by the installer to close a running clock before it updates
// or removes it; see windows/installer/BanglaVoiceClock.iss.
constexpr UINT kQuitMessage = WM_APP + 2;
// Carries a StartupTask answer from its worker thread back to the window.
constexpr UINT kLoginTaskMessage = WM_APP + 3;
constexpr UINT kFirstMenuId = 1000;
constexpr wchar_t kAppName[] = L"Bangla Voice Clock";
constexpr wchar_t kRunKey[] =
    L"Software\\Microsoft\\Windows\\CurrentVersion\\Run";
// windows/msix/AppxManifest.xml declares this task.
constexpr wchar_t kLoginTaskId[] = L"BanglaVoiceClockAtLogin";
// DWMWA_USE_IMMERSIVE_DARK_MODE, missing from older SDK headers.
constexpr DWORD kDarkModeAttribute = 20;

// From mmddk.h: a waveOut device's audio endpoint ID, which stays the same
// across restarts, unlike its index.
#ifndef DRV_QUERYFUNCTIONINSTANCEID
#define DRV_QUERYFUNCTIONINSTANCEID (DRV_RESERVED + 17)
#define DRV_QUERYFUNCTIONINSTANCEIDSIZE (DRV_RESERVED + 18)
#endif

// PKEY_Device_FriendlyName, such as "Headphones (Realtek Audio)".
constexpr PROPERTYKEY kFriendlyName = {
    {0xa45c254e, 0xdf1c, 0x4efd, {0x80, 0x20, 0x67, 0xd1, 0x46, 0xa8, 0x50, 0xe0}},
    14};

// Whether this copy runs from the Microsoft Store's MSIX package. Windows
// keeps a packaged app's registry apart, so the Run key can't open it at
// login; its StartupTask does.
bool Packaged() {
  UINT32 length = 0;
  return GetCurrentPackageFullName(&length, nullptr) !=
         APPMODEL_ERROR_NO_PACKAGE;
}

std::wstring Wide(const std::string& text) {
  if (text.empty()) return std::wstring();
  int length = MultiByteToWideChar(CP_UTF8, 0, text.data(),
                                   static_cast<int>(text.size()), nullptr, 0);
  std::wstring wide(length, L'\0');
  MultiByteToWideChar(CP_UTF8, 0, text.data(), static_cast<int>(text.size()),
                      wide.data(), length);
  return wide;
}

std::string Narrow(const std::wstring& text) {
  if (text.empty()) return std::string();
  int length = WideCharToMultiByte(CP_UTF8, 0, text.data(),
                                   static_cast<int>(text.size()), nullptr, 0,
                                   nullptr, nullptr);
  std::string narrow(length, '\0');
  WideCharToMultiByte(CP_UTF8, 0, text.data(), static_cast<int>(text.size()),
                      narrow.data(), length, nullptr, nullptr);
  return narrow;
}

struct OutputDevice {
  UINT index;
  std::wstring id;
  std::wstring name;
};

std::wstring EndpointId(UINT index) {
  auto device = reinterpret_cast<HWAVEOUT>(static_cast<UINT_PTR>(index));
  ULONG bytes = 0;
  if (waveOutMessage(device, DRV_QUERYFUNCTIONINSTANCEIDSIZE,
                     reinterpret_cast<DWORD_PTR>(&bytes),
                     0) != MMSYSERR_NOERROR ||
      bytes == 0) {
    return std::wstring();
  }
  std::wstring id(bytes / sizeof(wchar_t), L'\0');
  if (waveOutMessage(device, DRV_QUERYFUNCTIONINSTANCEID,
                     reinterpret_cast<DWORD_PTR>(id.data()),
                     bytes) != MMSYSERR_NOERROR) {
    return std::wstring();
  }
  id.resize(wcsnlen(id.c_str(), id.size()));
  return id;
}

// The endpoint's full name; waveOut's own names stop at 31 characters.
std::wstring FriendlyName(IMMDeviceEnumerator* devices,
                          const std::wstring& id) {
  std::wstring name;
  IMMDevice* device = nullptr;
  if (devices && SUCCEEDED(devices->GetDevice(id.c_str(), &device))) {
    IPropertyStore* store = nullptr;
    if (SUCCEEDED(device->OpenPropertyStore(STGM_READ, &store))) {
      PROPVARIANT value;
      PropVariantInit(&value);
      if (SUCCEEDED(store->GetValue(kFriendlyName, &value)) &&
          value.vt == VT_LPWSTR) {
        name = value.pwszVal;
      }
      PropVariantClear(&value);
      store->Release();
    }
    device->Release();
  }
  return name;
}

// Every device that can play sound.
std::vector<OutputDevice> OutputDevices() {
  std::vector<OutputDevice> result;
  IMMDeviceEnumerator* devices = nullptr;
  CoCreateInstance(__uuidof(MMDeviceEnumerator), nullptr, CLSCTX_ALL,
                   __uuidof(IMMDeviceEnumerator),
                   reinterpret_cast<void**>(&devices));
  UINT count = waveOutGetNumDevs();
  for (UINT i = 0; i < count; ++i) {
    std::wstring id = EndpointId(i);
    if (id.empty()) continue;
    std::wstring name = FriendlyName(devices, id);
    if (name.empty()) {
      WAVEOUTCAPSW caps = {};
      if (waveOutGetDevCapsW(i, &caps, sizeof(caps)) == MMSYSERR_NOERROR) {
        name = caps.szPname;
      }
    }
    result.push_back({i, id, name.empty() ? id : name});
  }
  if (devices) devices->Release();
  return result;
}

const flutter::EncodableValue* Field(const flutter::EncodableMap& map,
                                     const char* key) {
  auto it = map.find(flutter::EncodableValue(key));
  return it == map.end() ? nullptr : &it->second;
}

std::string StringField(const flutter::EncodableMap& map, const char* key) {
  const auto* value = Field(map, key);
  const auto* text = value ? std::get_if<std::string>(value) : nullptr;
  return text ? *text : std::string();
}

bool BoolField(const flutter::EncodableMap& map, const char* key,
               bool fallback) {
  const auto* value = Field(map, key);
  const auto* flag = value ? std::get_if<bool>(value) : nullptr;
  return flag ? *flag : fallback;
}

}  // namespace

NativeBridge::NativeBridge(flutter::BinaryMessenger* messenger, HWND window)
    : window_(window) {
  channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      messenger, "bangla_voice_clock/platform",
      &flutter::StandardMethodCodec::GetInstance());
  channel_->SetMethodCallHandler([this](const auto& call, auto result) {
    HandleCall(call, std::move(result));
  });
  // Explorer sends this when it restarts; the tray icon must be added again.
  taskbar_created_ = RegisterWindowMessageW(L"TaskbarCreated");
  AddTrayIcon();
}

NativeBridge::~NativeBridge() {
  StopSound();
  Shell_NotifyIconW(NIM_DELETE, &tray_);
}

void NativeBridge::AddTrayIcon() {
  tray_.cbSize = sizeof(NOTIFYICONDATAW);
  tray_.hWnd = window_;
  tray_.uID = 1;
  tray_.uFlags = NIF_ICON | NIF_MESSAGE | NIF_TIP;
  tray_.uCallbackMessage = kTrayMessage;
  tray_.hIcon = static_cast<HICON>(LoadImageW(
      GetModuleHandle(nullptr), MAKEINTRESOURCEW(IDI_APP_ICON), IMAGE_ICON,
      GetSystemMetrics(SM_CXSMICON), GetSystemMetrics(SM_CYSMICON), 0));
  if (tray_.szTip[0] == L'\0') {
    wcsncpy_s(tray_.szTip, kAppName, _TRUNCATE);
  }
  Shell_NotifyIconW(NIM_ADD, &tray_);
}

void NativeBridge::HandleCall(
    const flutter::MethodCall<flutter::EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const std::string& method = call.method_name();
  const flutter::EncodableValue* args = call.arguments();
  const auto* map = args ? std::get_if<flutter::EncodableMap>(args) : nullptr;
  const auto* text = args ? std::get_if<std::string>(args) : nullptr;

  if (method == "play") {
    const auto* wav = map ? Field(*map, "wav") : nullptr;
    const auto* bytes = wav ? std::get_if<std::vector<uint8_t>>(wav) : nullptr;
    if (!bytes) return result->Error("bad_arguments", "play needs wav bytes");
    const auto* volume = Field(*map, "volume");
    const auto* level = volume ? std::get_if<double>(volume) : nullptr;
    double gain = level ? *level : 1.0;
    std::wstring chosen = Wide(StringField(*map, "device"));
    // Stop any sound still playing before its buffer is replaced.
    StopSound();
    sound_ = *bytes;
    bool played = false;
    if (!chosen.empty()) {
      for (const auto& device : OutputDevices()) {
        if (device.id == chosen) {
          played = PlayOnDevice(device.index, gain);
          break;
        }
      }
    }
    // The system default, also when the chosen device is unplugged.
    if (!played) {
      DWORD channel = static_cast<DWORD>(gain * 0xFFFF);
      waveOutSetVolume(nullptr, channel | (channel << 16));
      PlaySoundW(reinterpret_cast<LPCWSTR>(sound_.data()), nullptr,
                 SND_MEMORY | SND_ASYNC | SND_NODEFAULT);
    }
    result->Success();
  } else if (method == "outputDevices") {
    flutter::EncodableList list;
    for (const auto& device : OutputDevices()) {
      list.push_back(flutter::EncodableValue(flutter::EncodableMap{
          {flutter::EncodableValue("id"),
           flutter::EncodableValue(Narrow(device.id))},
          {flutter::EncodableValue("name"),
           flutter::EncodableValue(Narrow(device.name))},
      }));
    }
    result->Success(flutter::EncodableValue(list));
  } else if (method == "setStatus") {
    // The tray shows only an icon, so the time goes in its tooltip.
    std::wstring title = map ? Wide(StringField(*map, "title")) : L"";
    std::wstring tip = title.empty() ? kAppName : title + L" — " + kAppName;
    tray_.uFlags = NIF_TIP;
    wcsncpy_s(tray_.szTip, tip.c_str(), _TRUNCATE);
    Shell_NotifyIconW(NIM_MODIFY, &tray_);
    result->Success();
  } else if (method == "setMenu") {
    const auto* list = args ? std::get_if<flutter::EncodableList>(args) : nullptr;
    if (!list) return result->Error("bad_arguments", "setMenu needs a list");
    menu_entries_ = *list;
    result->Success();
  } else if (method == "showWindow") {
    ShowWindowInFront();
    result->Success();
  } else if (method == "notify") {
    if (!map) return result->Error("bad_arguments", "notify needs a map");
    tray_.uFlags = NIF_INFO;
    tray_.dwInfoFlags = NIIF_INFO | NIIF_NOSOUND;
    wcsncpy_s(tray_.szInfoTitle, Wide(StringField(*map, "title")).c_str(),
              _TRUNCATE);
    wcsncpy_s(tray_.szInfo, Wide(StringField(*map, "body")).c_str(),
              _TRUNCATE);
    Shell_NotifyIconW(NIM_MODIFY, &tray_);
    result->Success();
  } else if (method == "openUrl") {
    if (!text) return result->Error("bad_arguments", "openUrl needs a URL");
    ShellExecuteW(nullptr, L"open", Wide(*text).c_str(), nullptr, nullptr,
                  SW_SHOWNORMAL);
    result->Success();
  } else if (method == "setAppearance") {
    SetAppearance(text ? *text : "system");
    result->Success();
  } else if (method == "launchAtLogin" && Packaged()) {
    UseLoginTask(std::nullopt, std::move(result));
  } else if (method == "setLaunchAtLogin" && Packaged()) {
    const auto* on = args ? std::get_if<bool>(args) : nullptr;
    UseLoginTask(on && *on, std::move(result));
  } else if (method == "launchAtLogin") {
    bool enabled = RegGetValueW(HKEY_CURRENT_USER, kRunKey, kAppName,
                                RRF_RT_REG_SZ, nullptr, nullptr,
                                nullptr) == ERROR_SUCCESS;
    result->Success(flutter::EncodableValue(enabled));
  } else if (method == "setLaunchAtLogin") {
    const auto* on = args ? std::get_if<bool>(args) : nullptr;
    LSTATUS status;
    if (on && *on) {
      wchar_t path[MAX_PATH];
      GetModuleFileNameW(nullptr, path, MAX_PATH);
      std::wstring command = L"\"" + std::wstring(path) + L"\"";
      status = RegSetKeyValueW(
          HKEY_CURRENT_USER, kRunKey, kAppName, REG_SZ, command.c_str(),
          static_cast<DWORD>((command.size() + 1) * sizeof(wchar_t)));
    } else {
      status = RegDeleteKeyValueW(HKEY_CURRENT_USER, kRunKey, kAppName);
      if (status == ERROR_FILE_NOT_FOUND) status = ERROR_SUCCESS;
    }
    result->Success(flutter::EncodableValue(status == ERROR_SUCCESS));
  } else if (method == "quit") {
    result->Success();
    // Destroy the window after this reply has been sent.
    PostMessageW(window_, kQuitMessage, 0, 0);
  } else {
    result->NotImplemented();
  }
}

void NativeBridge::UseLoginTask(
    std::optional<bool> enable,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  // StartupTask answers asynchronously, so wait for it on a worker thread
  // rather than block the window.
  auto* pending = result.release();
  HWND window = window_;
  std::thread([window, enable, pending] {
    using winrt::Windows::ApplicationModel::StartupTask;
    using winrt::Windows::ApplicationModel::StartupTaskState;
    bool on = false;
    winrt::init_apartment();
    try {
      StartupTask task = StartupTask::GetAsync(kLoginTaskId).get();
      if (enable == true) {
        task.RequestEnableAsync().get();
      } else if (enable == false) {
        task.Disable();
      }
      StartupTaskState state = task.State();
      on = state == StartupTaskState::Enabled ||
           state == StartupTaskState::EnabledByPolicy;
    } catch (const winrt::hresult_error&) {
    }
    winrt::uninit_apartment();
    // A change answers whether it took effect, a read whether it's on.
    bool answer = enable ? on == *enable : on;
    PostMessageW(window, kLoginTaskMessage, answer,
                 reinterpret_cast<LPARAM>(pending));
  }).detach();
}

std::optional<LRESULT> NativeBridge::HandleMessage(HWND hwnd, UINT message,
                                                   WPARAM wparam,
                                                   LPARAM lparam) {
  if (message == kLoginTaskMessage) {
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result(
        reinterpret_cast<flutter::MethodResult<flutter::EncodableValue>*>(
            lparam));
    result->Success(flutter::EncodableValue(wparam != 0));
    return 0;
  }
  if (message == kTrayMessage) {
    switch (LOWORD(lparam)) {
      case WM_LBUTTONUP:
      case WM_RBUTTONUP:
        ShowTrayMenu();
        break;
      case WM_LBUTTONDBLCLK:
        ShowWindowInFront();
        break;
    }
    return 0;
  }
  if (message == kQuitMessage) {
    Shell_NotifyIconW(NIM_DELETE, &tray_);
    DestroyWindow(hwnd);
    return 0;
  }
  if (taskbar_created_ != 0 && message == taskbar_created_) {
    AddTrayIcon();
    return 0;
  }
  switch (message) {
    case MM_WOM_DONE:
      // A stale notice from a sound StopSound already cut off is ignored.
      if (reinterpret_cast<HWAVEOUT>(wparam) == wave_out_ &&
          (wave_header_.dwFlags & WHDR_DONE)) {
        CloseWaveOut();
      }
      return 0;
    case WM_POWERBROADCAST:
      if (wparam == PBT_APMRESUMEAUTOMATIC || wparam == PBT_APMRESUMESUSPEND) {
        channel_->InvokeMethod("clockDisturbed", nullptr);
      }
      break;
    case WM_TIMECHANGE:
      channel_->InvokeMethod("clockDisturbed", nullptr);
      break;
    case WM_ENDSESSION:
      // Signing out, or the installer closing the clock to update it.
      if (wparam) {
        Shell_NotifyIconW(NIM_DELETE, &tray_);
        DestroyWindow(hwnd);
      }
      return 0;
  }
  return std::nullopt;
}

void NativeBridge::ShowTrayMenu() {
  menu_ids_.clear();
  HMENU menu = BuildMenu(menu_entries_);
  POINT point;
  GetCursorPos(&point);
  // Without this the menu would not close when the user clicks elsewhere.
  SetForegroundWindow(window_);
  UINT command = TrackPopupMenu(menu, TPM_RETURNCMD | TPM_RIGHTBUTTON,
                                point.x, point.y, 0, window_, nullptr);
  PostMessageW(window_, WM_NULL, 0, 0);
  DestroyMenu(menu);
  auto it = menu_ids_.find(command);
  if (it != menu_ids_.end()) {
    channel_->InvokeMethod(
        "menuItemSelected",
        std::make_unique<flutter::EncodableValue>(it->second));
  }
}

HMENU NativeBridge::BuildMenu(const flutter::EncodableList& entries) {
  HMENU menu = CreatePopupMenu();
  for (const auto& value : entries) {
    const auto* entry = std::get_if<flutter::EncodableMap>(&value);
    if (!entry) continue;
    if (BoolField(*entry, "separator", false)) {
      AppendMenuW(menu, MF_SEPARATOR, 0, nullptr);
      continue;
    }
    std::wstring title = Wide(StringField(*entry, "title"));
    UINT flags = MF_STRING;
    if (!BoolField(*entry, "enabled", true)) flags |= MF_GRAYED;
    if (BoolField(*entry, "checked", false)) flags |= MF_CHECKED;
    const auto* children = Field(*entry, "children");
    const auto* list =
        children ? std::get_if<flutter::EncodableList>(children) : nullptr;
    if (list && !list->empty()) {
      AppendMenuW(menu, flags | MF_POPUP,
                  reinterpret_cast<UINT_PTR>(BuildMenu(*list)), title.c_str());
      continue;
    }
    UINT command = kFirstMenuId + static_cast<UINT>(menu_ids_.size());
    menu_ids_[command] = StringField(*entry, "id");
    AppendMenuW(menu, flags, command, title.c_str());
  }
  return menu;
}

void NativeBridge::ShowWindowInFront() {
  ShowWindow(window_, SW_SHOWNORMAL);
  SetForegroundWindow(window_);
}

void NativeBridge::SetAppearance(const std::string& appearance) {
  BOOL dark = FALSE;
  if (appearance == "dark") {
    dark = TRUE;
  } else if (appearance == "system") {
    DWORD light = 1;
    DWORD size = sizeof(light);
    RegGetValueW(HKEY_CURRENT_USER,
                 L"Software\\Microsoft\\Windows\\CurrentVersion\\Themes\\"
                 L"Personalize",
                 L"AppsUseLightTheme", RRF_RT_REG_DWORD, nullptr, &light,
                 &size);
    dark = light == 0;
  }
  DwmSetWindowAttribute(window_, kDarkModeAttribute, &dark, sizeof(dark));
}

bool NativeBridge::PlayOnDevice(UINT index, double volume) {
  // The app's own WAVs: a "fmt " chunk, then the samples in "data".
  WAVEFORMATEX format = {};
  size_t data = 0, size = 0;
  for (size_t at = 12; at + 8 <= sound_.size();) {
    uint32_t length;
    memcpy(&length, &sound_[at + 4], sizeof(length));
    size_t body = at + 8;
    if (memcmp(&sound_[at], "fmt ", 4) == 0 && body + 16 <= sound_.size()) {
      memcpy(&format, &sound_[body], 16);
    } else if (memcmp(&sound_[at], "data", 4) == 0) {
      data = body;
      size = std::min<size_t>(length, sound_.size() - body);
      break;
    }
    at = body + length + (length & 1);
  }
  if (format.wFormatTag != WAVE_FORMAT_PCM || size == 0) return false;
  if (waveOutOpen(&wave_out_, index, &format,
                  reinterpret_cast<DWORD_PTR>(window_), 0,
                  CALLBACK_WINDOW) != MMSYSERR_NOERROR) {
    wave_out_ = nullptr;
    return false;
  }
  DWORD channel = static_cast<DWORD>(volume * 0xFFFF);
  waveOutSetVolume(wave_out_, channel | (channel << 16));
  wave_header_ = {};
  wave_header_.lpData = reinterpret_cast<LPSTR>(sound_.data() + data);
  wave_header_.dwBufferLength = static_cast<DWORD>(size);
  if (waveOutPrepareHeader(wave_out_, &wave_header_, sizeof(WAVEHDR)) !=
          MMSYSERR_NOERROR ||
      waveOutWrite(wave_out_, &wave_header_, sizeof(WAVEHDR)) !=
          MMSYSERR_NOERROR) {
    CloseWaveOut();
    return false;
  }
  return true;
}

void NativeBridge::StopSound() {
  PlaySoundW(nullptr, nullptr, 0);
  if (wave_out_) {
    waveOutReset(wave_out_);
    CloseWaveOut();
  }
}

void NativeBridge::CloseWaveOut() {
  if (!wave_out_) return;
  waveOutUnprepareHeader(wave_out_, &wave_header_, sizeof(WAVEHDR));
  waveOutClose(wave_out_);
  wave_out_ = nullptr;
}
