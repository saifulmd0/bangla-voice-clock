#ifndef RUNNER_NATIVE_BRIDGE_H_
#define RUNNER_NATIVE_BRIDGE_H_

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>
#include <libayatana-appindicator/app-indicator.h>

#include <string>

// The Linux side of lib/app/platform.dart: the panel (tray) icon and its
// menu, sound and its output device, notifications, opening at login, the
// window's light or dark look, and wake and clock-change events.
class NativeBridge {
 public:
  NativeBridge(GtkApplication* app, GtkWindow* window,
               FlBinaryMessenger* messenger);
  ~NativeBridge();

  NativeBridge(const NativeBridge&) = delete;
  NativeBridge& operator=(const NativeBridge&) = delete;

  // Shows the window and brings it to the front.
  void ShowWindow();

  // Whether the desktop's panel shows tray icons. Without one (GNOME with
  // no AppIndicator extension) opening the app is the only way in.
  bool has_tray() const { return has_tray_; }

  // Tells Dart the window closed with no panel icon to reopen it by.
  void ClosedWithoutIcon();

 private:
  static void OnMethodCall(FlMethodChannel* channel, FlMethodCall* call,
                           gpointer self);
  static void OnMenuItem(GtkMenuItem* item, gpointer self);
  static void OnPrepareForSleep(GDBusConnection* bus, const gchar* sender,
                                const gchar* path, const gchar* interface,
                                const gchar* signal, GVariant* parameters,
                                gpointer self);
  static gboolean OnClockChanged(gint fd, GIOCondition condition,
                                 gpointer self);

  void HandleCall(FlMethodCall* call);
  GtkWidget* BuildMenu(FlValue* entries);
  void SetLaunchAtLogin(bool enabled);
  bool LaunchAtLogin() const;
  void UpdateLaunchAtLogin();
  void WatchClock();
  void ClockDisturbed();

  GtkApplication* app_;
  GtkWindow* window_;
  FlMethodChannel* channel_ = nullptr;
  AppIndicator* indicator_ = nullptr;
  bool has_tray_ = false;
  GDBusConnection* system_bus_ = nullptr;
  guint sleep_watch_ = 0;
  int clock_fd_ = -1;
  guint clock_watch_ = 0;
};

#endif  // RUNNER_NATIVE_BRIDGE_H_
