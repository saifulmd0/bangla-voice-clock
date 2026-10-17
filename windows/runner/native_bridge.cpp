#include "native_bridge.h"

#include <dwmapi.h>
#include <flutter/standard_method_codec.h>
#include <mmsystem.h>

#include "resource.h"

namespace {

constexpr UINT kTrayMessage = WM_APP + 1;
constexpr UINT kQuitMessage = WM_APP + 2;
constexpr UINT kFirstMenuId = 1000;
constexpr wchar_t kAppName[] = L"Bangla Voice Clock";
constexpr wchar_t kRunKey[] =
    L"Software\\Microsoft\\Windows\\CurrentVersion\\Run";
// DWMWA_USE_IMMERSIVE_DARK_MODE, missing from older SDK headers.
constexpr DWORD kDarkModeAttribute = 20;

std::wstring Wide(const std::string& text) {
  if (text.empty()) return std::wstring();
  int length = MultiByteToWideChar(CP_UTF8, 0, text.data(),
                                   static_cast<int>(text.size()), nullptr, 0);
  std::wstring wide(length, L'\0');
  MultiByteToWideChar(CP_UTF8, 0, text.data(), static_cast<int>(text.size()),
                      wide.data(), length);
  return wide;
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
  PlaySoundW(nullptr, nullptr, 0);
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
    // Stop any sound still playing before its buffer is replaced.
    PlaySoundW(nullptr, nullptr, 0);
    sound_ = *bytes;
    DWORD channel = static_cast<DWORD>((level ? *level : 1.0) * 0xFFFF);
    waveOutSetVolume(nullptr, channel | (channel << 16));
    PlaySoundW(reinterpret_cast<LPCWSTR>(sound_.data()), nullptr,
               SND_MEMORY | SND_ASYNC | SND_NODEFAULT);
    result->Success();
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

std::optional<LRESULT> NativeBridge::HandleMessage(HWND hwnd, UINT message,
                                                   WPARAM wparam,
                                                   LPARAM lparam) {
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
    case WM_POWERBROADCAST:
      if (wparam == PBT_APMRESUMEAUTOMATIC || wparam == PBT_APMRESUMESUSPEND) {
        channel_->InvokeMethod("clockDisturbed", nullptr);
      }
      break;
    case WM_TIMECHANGE:
      channel_->InvokeMethod("clockDisturbed", nullptr);
      break;
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
