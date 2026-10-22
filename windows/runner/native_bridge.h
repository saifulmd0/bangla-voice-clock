#ifndef RUNNER_NATIVE_BRIDGE_H_
#define RUNNER_NATIVE_BRIDGE_H_

#include <flutter/binary_messenger.h>
#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>
#include <windows.h>
#include <mmsystem.h>
#include <shellapi.h>

#include <map>
#include <memory>
#include <optional>
#include <string>
#include <vector>

// The Windows side of lib/app/platform.dart: the system-tray icon and its
// menu, sound and its output device, notifications, opening at login, the title bar's light or
// dark look, and wake and clock-change events.
class NativeBridge {
 public:
  NativeBridge(flutter::BinaryMessenger* messenger, HWND window);
  ~NativeBridge();

  // Handles tray, power and clock messages sent to the main window.
  std::optional<LRESULT> HandleMessage(HWND hwnd, UINT message, WPARAM wparam,
                                       LPARAM lparam);

 private:
  void HandleCall(
      const flutter::MethodCall<flutter::EncodableValue>& call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  void AddTrayIcon();
  void ShowTrayMenu();
  HMENU BuildMenu(const flutter::EncodableList& entries);
  void ShowWindowInFront();
  void SetAppearance(const std::string& appearance);
  // Reads, or with [enable] first changes, the Store package's StartupTask,
  // then answers [result] from the window's thread.
  void UseLoginTask(
      std::optional<bool> enable,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  // Plays sound_ on the waveOut device [index]; false if it can't.
  bool PlayOnDevice(UINT index, double volume);
  void StopSound();
  void CloseWaveOut();

  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
  HWND window_;
  NOTIFYICONDATAW tray_ = {};
  UINT taskbar_created_ = 0;
  flutter::EncodableList menu_entries_;
  std::map<UINT, std::string> menu_ids_;
  std::vector<uint8_t> sound_;
  // Open only while a sound plays on a chosen device, so an idle handle
  // never keeps the audio device (and the computer) awake.
  HWAVEOUT wave_out_ = nullptr;
  WAVEHDR wave_header_ = {};
};

#endif  // RUNNER_NATIVE_BRIDGE_H_
