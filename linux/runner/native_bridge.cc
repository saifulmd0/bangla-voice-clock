#include "native_bridge.h"

#include <glib-unix.h>
#include <glib/gstdio.h>
#include <pulse/pulseaudio.h>
#include <pulse/simple.h>
#include <sys/timerfd.h>
#include <unistd.h>

#include <algorithm>
#include <atomic>
#include <cstdint>
#include <cstring>
#include <ctime>
#include <thread>
#include <utility>
#include <vector>

namespace {

constexpr char kChannel[] = "bangla_voice_clock/platform";
constexpr char kAppName[] = "Bangla Voice Clock";
// The monochrome panel icon; "-symbolic" lets the panel tint it.
constexpr char kTrayIcon[] = APPLICATION_ID "-symbolic";
constexpr char kPortal[] = "org.freedesktop.portal.Desktop";
constexpr char kPortalPath[] = "/org/freedesktop/portal/desktop";

bool InFlatpak() { return g_file_test("/.flatpak-info", G_FILE_TEST_EXISTS); }

// The folder holding the running executable (and its data/ and lib/).
std::string ExecutableDir() {
  g_autofree gchar* exe = g_file_read_link("/proc/self/exe", nullptr);
  if (!exe) return std::string();
  g_autofree gchar* dir = g_path_get_dirname(exe);
  return dir;
}

std::string StringArg(FlValue* map, const char* key) {
  FlValue* value = map ? fl_value_lookup_string(map, key) : nullptr;
  return value && fl_value_get_type(value) == FL_VALUE_TYPE_STRING
             ? fl_value_get_string(value)
             : std::string();
}

bool BoolArg(FlValue* map, const char* key, bool fallback) {
  FlValue* value = map ? fl_value_lookup_string(map, key) : nullptr;
  return value && fl_value_get_type(value) == FL_VALUE_TYPE_BOOL
             ? fl_value_get_bool(value)
             : fallback;
}

// Sound

// The app's own WAVs: 16-bit PCM in a "data" chunk after a "fmt " chunk.
struct Sound {
  std::vector<int16_t> samples;
  uint32_t rate = 0;
  uint8_t channels = 0;
};

bool ParseWav(const uint8_t* bytes, size_t size, double volume, Sound* sound) {
  if (size < 12 || memcmp(bytes, "RIFF", 4) != 0 ||
      memcmp(bytes + 8, "WAVE", 4) != 0) {
    return false;
  }
  uint16_t format = 0, bits = 0;
  for (size_t at = 12; at + 8 <= size;) {
    uint32_t length;
    memcpy(&length, bytes + at + 4, sizeof(length));
    size_t body = at + 8;
    if (memcmp(bytes + at, "fmt ", 4) == 0 && body + 16 <= size) {
      uint16_t channels;
      memcpy(&format, bytes + body, 2);
      memcpy(&channels, bytes + body + 2, 2);
      memcpy(&sound->rate, bytes + body + 4, 4);
      memcpy(&bits, bytes + body + 14, 2);
      sound->channels = static_cast<uint8_t>(channels);
    } else if (memcmp(bytes + at, "data", 4) == 0) {
      size_t available = std::min<size_t>(length, size - body);
      sound->samples.resize(available / 2);
      memcpy(sound->samples.data(), bytes + body, sound->samples.size() * 2);
      break;
    }
    at = body + length + (length & 1);
  }
  if (format != 1 || bits != 16 || sound->rate == 0 || sound->channels == 0 ||
      sound->samples.empty()) {
    return false;
  }
  // The volume slider scales the samples themselves.
  volume = std::max(0.0, std::min(volume, 1.0));
  for (auto& sample : sound->samples) {
    sample = static_cast<int16_t>(sample * volume);
  }
  return true;
}

// Each play takes the next number; a sound still playing stops when it
// sees a newer one, so a new announcement cuts off the last.
std::atomic<unsigned> g_playing{0};

void Play(Sound sound, std::string device) {
  unsigned mine = ++g_playing;
  std::thread([sound = std::move(sound), device = std::move(device), mine] {
    pa_sample_spec spec = {PA_SAMPLE_S16LE, sound.rate, sound.channels};
    int error = 0;
    pa_simple* out = nullptr;
    if (!device.empty()) {
      out = pa_simple_new(nullptr, kAppName, PA_STREAM_PLAYBACK,
                          device.c_str(), "Announcement", &spec, nullptr,
                          nullptr, &error);
    }
    // The system default, also when the chosen device is unplugged.
    if (!out) {
      out = pa_simple_new(nullptr, kAppName, PA_STREAM_PLAYBACK, nullptr,
                          "Announcement", &spec, nullptr, nullptr, &error);
    }
    if (!out) {
      g_warning("No sound output: %s", pa_strerror(error));
      return;
    }
    // A tenth of a second at a time, to notice a newer sound quickly.
    const size_t chunk = sound.rate / 10 * sound.channels;
    for (size_t at = 0; at < sound.samples.size() && g_playing == mine;
         at += chunk) {
      size_t count = std::min(chunk, sound.samples.size() - at);
      if (pa_simple_write(out, sound.samples.data() + at,
                          count * sizeof(int16_t), &error) < 0) {
        break;
      }
    }
    if (g_playing == mine) {
      pa_simple_drain(out, &error);
    } else {
      pa_simple_flush(out, &error);
    }
    pa_simple_free(out);
  }).detach();
}

struct OutputDevice {
  std::string id;
  std::string name;
};

void OnSink(pa_context*, const pa_sink_info* info, int eol, void* data) {
  if (eol || !info) return;
  static_cast<std::vector<OutputDevice>*>(data)->push_back(
      {info->name, info->description ? info->description : info->name});
}

// Every sound output, from PulseAudio (or PipeWire's stand-in for it).
std::vector<OutputDevice> OutputDevices() {
  std::vector<OutputDevice> devices;
  pa_mainloop* loop = pa_mainloop_new();
  pa_context* context = pa_context_new(pa_mainloop_get_api(loop), kAppName);
  if (pa_context_connect(context, nullptr, PA_CONTEXT_NOFLAGS, nullptr) >= 0) {
    pa_operation* listing = nullptr;
    gint64 give_up = g_get_monotonic_time() + 2 * G_USEC_PER_SEC;
    while (g_get_monotonic_time() < give_up) {
      pa_mainloop_iterate(loop, 0, nullptr);
      pa_context_state_t state = pa_context_get_state(context);
      if (!PA_CONTEXT_IS_GOOD(state)) break;
      if (state == PA_CONTEXT_READY && !listing) {
        listing = pa_context_get_sink_info_list(context, OnSink, &devices);
      }
      if (listing && pa_operation_get_state(listing) != PA_OPERATION_RUNNING) {
        break;
      }
      g_usleep(1000);
    }
    if (listing) pa_operation_unref(listing);
    pa_context_disconnect(context);
  }
  pa_context_unref(context);
  pa_mainloop_free(loop);
  return devices;
}

// Desktop

// Whether something on the session bus shows StatusNotifier (tray) icons.
bool HasTrayHost() {
  g_autoptr(GDBusConnection) bus =
      g_bus_get_sync(G_BUS_TYPE_SESSION, nullptr, nullptr);
  if (!bus) return false;
  g_autoptr(GVariant) reply = g_dbus_connection_call_sync(
      bus, "org.freedesktop.DBus", "/org/freedesktop/DBus",
      "org.freedesktop.DBus", "NameHasOwner",
      g_variant_new("(s)", "org.kde.StatusNotifierWatcher"),
      G_VARIANT_TYPE("(b)"), G_DBUS_CALL_FLAGS_NONE, 1000, nullptr, nullptr);
  gboolean owned = FALSE;
  if (reply) g_variant_get(reply, "(b)", &owned);
  return owned;
}

// The desktop's light or dark preference, through the settings portal.
bool SystemPrefersDark() {
  g_autoptr(GDBusConnection) bus =
      g_bus_get_sync(G_BUS_TYPE_SESSION, nullptr, nullptr);
  if (!bus) return false;
  g_autoptr(GVariant) reply = g_dbus_connection_call_sync(
      bus, kPortal, kPortalPath, "org.freedesktop.portal.Settings", "Read",
      g_variant_new("(ss)", "org.freedesktop.appearance", "color-scheme"),
      G_VARIANT_TYPE("(v)"), G_DBUS_CALL_FLAGS_NONE, 1000, nullptr, nullptr);
  if (!reply) return false;
  g_autoptr(GVariant) value = nullptr;
  g_variant_get(reply, "(v)", &value);
  // Older portals wrap the value in a second variant.
  while (value && g_variant_is_of_type(value, G_VARIANT_TYPE_VARIANT)) {
    GVariant* inner = g_variant_get_variant(value);
    g_variant_unref(value);
    value = inner;
  }
  return value && g_variant_is_of_type(value, G_VARIANT_TYPE_UINT32) &&
         g_variant_get_uint32(value) == 1;
}

// The XDG autostart entry used outside Flatpak.
std::string AutostartFile() {
  g_autofree gchar* path = g_build_filename(
      g_get_user_config_dir(), "autostart", APPLICATION_ID ".desktop", nullptr);
  return path;
}

// Inside Flatpak the portal keeps the autostart entry, out of the app's
// sight, so the app remembers what it last asked for here.
std::string FlatpakAutostartFlag() {
  g_autofree gchar* path = g_build_filename(
      g_get_user_config_dir(), "bangla-voice-clock", "autostart", nullptr);
  return path;
}

}  // namespace

NativeBridge::NativeBridge(GtkApplication* app, GtkWindow* window,
                           FlBinaryMessenger* messenger)
    : app_(app), window_(window) {
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  channel_ =
      fl_method_channel_new(messenger, kChannel, FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(channel_, OnMethodCall, this,
                                            nullptr);

  has_tray_ = HasTrayHost();
  indicator_ = app_indicator_new("bangla-voice-clock", kTrayIcon,
                                 APP_INDICATOR_CATEGORY_APPLICATION_STATUS);
  app_indicator_set_title(indicator_, kAppName);
  // A copy run from its folder, not installed, carries its own icons.
  if (!gtk_icon_theme_has_icon(gtk_icon_theme_get_default(), kTrayIcon)) {
    g_autofree gchar* icons = g_build_filename(
        ExecutableDir().c_str(), "data", "icons", nullptr);
    app_indicator_set_icon_theme_path(indicator_, icons);
  }
  app_indicator_set_status(indicator_, APP_INDICATOR_STATUS_ACTIVE);

  system_bus_ = g_bus_get_sync(G_BUS_TYPE_SYSTEM, nullptr, nullptr);
  if (system_bus_) {
    sleep_watch_ = g_dbus_connection_signal_subscribe(
        system_bus_, "org.freedesktop.login1", "org.freedesktop.login1.Manager",
        "PrepareForSleep", "/org/freedesktop/login1", nullptr,
        G_DBUS_SIGNAL_FLAGS_NONE, OnPrepareForSleep, this, nullptr);
  }
  WatchClock();
}

NativeBridge::~NativeBridge() {
  ++g_playing;
  if (sleep_watch_) g_dbus_connection_signal_unsubscribe(system_bus_, sleep_watch_);
  g_clear_object(&system_bus_);
  if (clock_watch_) g_source_remove(clock_watch_);
  if (clock_fd_ >= 0) close(clock_fd_);
  g_clear_object(&indicator_);
  g_clear_object(&channel_);
}

void NativeBridge::ShowWindow() {
  gtk_widget_show(GTK_WIDGET(window_));
  gtk_window_present(window_);
}

void NativeBridge::OnMethodCall(FlMethodChannel*, FlMethodCall* call,
                                gpointer self) {
  static_cast<NativeBridge*>(self)->HandleCall(call);
}

void NativeBridge::HandleCall(FlMethodCall* call) {
  const gchar* method = fl_method_call_get_name(call);
  FlValue* args = fl_method_call_get_args(call);
  FlValue* map =
      args && fl_value_get_type(args) == FL_VALUE_TYPE_MAP ? args : nullptr;
  g_autoptr(FlValue) result = nullptr;

  if (strcmp(method, "play") == 0) {
    FlValue* wav = map ? fl_value_lookup_string(map, "wav") : nullptr;
    FlValue* volume = map ? fl_value_lookup_string(map, "volume") : nullptr;
    Sound sound;
    if (!wav || fl_value_get_type(wav) != FL_VALUE_TYPE_UINT8_LIST ||
        !ParseWav(fl_value_get_uint8_list(wav), fl_value_get_length(wav),
                  volume && fl_value_get_type(volume) == FL_VALUE_TYPE_FLOAT
                      ? fl_value_get_float(volume)
                      : 1.0,
                  &sound)) {
      fl_method_call_respond_error(call, "bad_arguments",
                                   "play needs 16-bit PCM WAV bytes", nullptr,
                                   nullptr);
      return;
    }
    Play(std::move(sound), StringArg(map, "device"));
  } else if (strcmp(method, "outputDevices") == 0) {
    result = fl_value_new_list();
    for (const auto& device : OutputDevices()) {
      FlValue* entry = fl_value_new_map();
      fl_value_set_string_take(entry, "id",
                               fl_value_new_string(device.id.c_str()));
      fl_value_set_string_take(entry, "name",
                               fl_value_new_string(device.name.c_str()));
      fl_value_append_take(result, entry);
    }
  } else if (strcmp(method, "setStatus") == 0) {
    // The panel always shows the icon; the time goes beside it where the
    // panel shows labels (GNOME and Unity do, KDE puts it in the tooltip).
    std::string title = StringArg(map, "title");
    app_indicator_set_label(indicator_, title.c_str(), title.c_str());
    app_indicator_set_title(
        indicator_, title.empty() ? kAppName : (title + " · " + kAppName).c_str());
  } else if (strcmp(method, "setMenu") == 0) {
    if (!args || fl_value_get_type(args) != FL_VALUE_TYPE_LIST) {
      fl_method_call_respond_error(call, "bad_arguments",
                                   "setMenu needs a list", nullptr, nullptr);
      return;
    }
    app_indicator_set_menu(indicator_, GTK_MENU(BuildMenu(args)));
  } else if (strcmp(method, "showWindow") == 0) {
    ShowWindow();
  } else if (strcmp(method, "notify") == 0) {
    g_autoptr(GNotification) notification =
        g_notification_new(StringArg(map, "title").c_str());
    g_notification_set_body(notification, StringArg(map, "body").c_str());
    g_application_send_notification(G_APPLICATION(app_), "announcement",
                                    notification);
  } else if (strcmp(method, "openUrl") == 0) {
    if (args && fl_value_get_type(args) == FL_VALUE_TYPE_STRING) {
      gtk_show_uri_on_window(window_, fl_value_get_string(args),
                             GDK_CURRENT_TIME, nullptr);
    }
  } else if (strcmp(method, "setAppearance") == 0) {
    std::string look = args && fl_value_get_type(args) == FL_VALUE_TYPE_STRING
                           ? fl_value_get_string(args)
                           : "system";
    gboolean dark = look == "dark" || (look == "system" && SystemPrefersDark());
    g_object_set(gtk_settings_get_default(),
                 "gtk-application-prefer-dark-theme", dark, nullptr);
  } else if (strcmp(method, "launchAtLogin") == 0) {
    result = fl_value_new_bool(LaunchAtLogin());
  } else if (strcmp(method, "setLaunchAtLogin") == 0) {
    SetLaunchAtLogin(args && fl_value_get_type(args) == FL_VALUE_TYPE_BOOL &&
                     fl_value_get_bool(args));
    result = fl_value_new_bool(TRUE);
  } else if (strcmp(method, "quit") == 0) {
    fl_method_call_respond_success(call, nullptr, nullptr);
    g_application_quit(G_APPLICATION(app_));
    return;
  } else {
    fl_method_call_respond_not_implemented(call, nullptr);
    return;
  }
  fl_method_call_respond_success(call, result, nullptr);
}

GtkWidget* NativeBridge::BuildMenu(FlValue* entries) {
  GtkWidget* menu = gtk_menu_new();
  for (size_t i = 0; i < fl_value_get_length(entries); ++i) {
    FlValue* entry = fl_value_get_list_value(entries, i);
    if (fl_value_get_type(entry) != FL_VALUE_TYPE_MAP) continue;
    if (BoolArg(entry, "separator", false)) {
      gtk_menu_shell_append(GTK_MENU_SHELL(menu),
                            gtk_separator_menu_item_new());
      continue;
    }
    std::string title = StringArg(entry, "title");
    GtkWidget* item;
    if (BoolArg(entry, "checked", false)) {
      item = gtk_check_menu_item_new_with_label(title.c_str());
      gtk_check_menu_item_set_active(GTK_CHECK_MENU_ITEM(item), TRUE);
    } else {
      item = gtk_menu_item_new_with_label(title.c_str());
    }
    gtk_widget_set_sensitive(item, BoolArg(entry, "enabled", true));
    FlValue* children = fl_value_lookup_string(entry, "children");
    std::string id = StringArg(entry, "id");
    if (children && fl_value_get_type(children) == FL_VALUE_TYPE_LIST &&
        fl_value_get_length(children) > 0) {
      gtk_menu_item_set_submenu(GTK_MENU_ITEM(item), BuildMenu(children));
    } else if (!id.empty()) {
      g_object_set_data_full(G_OBJECT(item), "id", g_strdup(id.c_str()),
                             g_free);
      g_signal_connect(item, "activate", G_CALLBACK(OnMenuItem), this);
    }
    gtk_menu_shell_append(GTK_MENU_SHELL(menu), item);
  }
  gtk_widget_show_all(menu);
  return menu;
}

void NativeBridge::OnMenuItem(GtkMenuItem* item, gpointer self) {
  auto* bridge = static_cast<NativeBridge*>(self);
  const auto* id =
      static_cast<const gchar*>(g_object_get_data(G_OBJECT(item), "id"));
  g_autoptr(FlValue) value = fl_value_new_string(id);
  fl_method_channel_invoke_method(bridge->channel_, "menuItemSelected", value,
                                  nullptr, nullptr, nullptr);
}

bool NativeBridge::LaunchAtLogin() const {
  if (!InFlatpak()) {
    return g_file_test(AutostartFile().c_str(), G_FILE_TEST_EXISTS);
  }
  g_autofree gchar* flag = nullptr;
  return g_file_get_contents(FlatpakAutostartFlag().c_str(), &flag, nullptr,
                             nullptr) &&
         g_str_has_prefix(flag, "1");
}

void NativeBridge::SetLaunchAtLogin(bool enabled) {
  if (!InFlatpak()) {
    std::string path = AutostartFile();
    if (!enabled) {
      g_unlink(path.c_str());
      return;
    }
    g_autofree gchar* folder = g_path_get_dirname(path.c_str());
    g_mkdir_with_parents(folder, 0755);
    g_autofree gchar* exe = g_file_read_link("/proc/self/exe", nullptr);
    g_autofree gchar* entry = g_strdup_printf(
        "[Desktop Entry]\n"
        "Type=Application\n"
        "Name=%s\n"
        "Exec=\"%s\"\n"
        "Icon=" APPLICATION_ID "\n"
        "X-GNOME-Autostart-enabled=true\n",
        kAppName, exe ? exe : "bangla-voice-clock");
    g_file_set_contents(path.c_str(), entry, -1, nullptr);
    return;
  }
  // The Background portal adds or removes the autostart entry, asking the
  // user the first time.
  GVariantBuilder options;
  g_variant_builder_init(&options, G_VARIANT_TYPE_VARDICT);
  g_variant_builder_add(&options, "{sv}", "reason",
                        g_variant_new_string("Announce the time from login"));
  g_variant_builder_add(&options, "{sv}", "autostart",
                        g_variant_new_boolean(enabled));
  const gchar* command[] = {"bangla-voice-clock", nullptr};
  g_variant_builder_add(&options, "{sv}", "commandline",
                        g_variant_new_strv(command, -1));
  g_autoptr(GDBusConnection) bus =
      g_bus_get_sync(G_BUS_TYPE_SESSION, nullptr, nullptr);
  if (bus) {
    g_dbus_connection_call(bus, kPortal, kPortalPath,
                           "org.freedesktop.portal.Background",
                           "RequestBackground",
                           g_variant_new("(sa{sv})", "", &options),
                           G_VARIANT_TYPE("(o)"), G_DBUS_CALL_FLAGS_NONE, -1,
                           nullptr, nullptr, nullptr);
  } else {
    g_variant_builder_clear(&options);
  }
  std::string flag = FlatpakAutostartFlag();
  g_autofree gchar* folder = g_path_get_dirname(flag.c_str());
  g_mkdir_with_parents(folder, 0755);
  g_file_set_contents(flag.c_str(), enabled ? "1" : "0", -1, nullptr);
}

// A timer set far ahead that the kernel cancels whenever the clock is set.
void NativeBridge::WatchClock() {
  if (clock_fd_ < 0) {
    clock_fd_ = timerfd_create(CLOCK_REALTIME, TFD_NONBLOCK | TFD_CLOEXEC);
    if (clock_fd_ < 0) return;
    clock_watch_ = g_unix_fd_add(clock_fd_, G_IO_IN, OnClockChanged, this);
  }
  struct itimerspec far = {};
  far.it_value.tv_sec = time(nullptr) + 365 * 24 * 60 * 60;
  timerfd_settime(clock_fd_, TFD_TIMER_ABSTIME | TFD_TIMER_CANCEL_ON_SET, &far,
                  nullptr);
}

gboolean NativeBridge::OnClockChanged(gint fd, GIOCondition, gpointer self) {
  uint64_t expirations;
  // Fails with ECANCELED when the clock was set, which is the point.
  ssize_t ignored = read(fd, &expirations, sizeof(expirations));
  (void)ignored;
  auto* bridge = static_cast<NativeBridge*>(self);
  bridge->WatchClock();
  bridge->ClockDisturbed();
  return G_SOURCE_CONTINUE;
}

void NativeBridge::OnPrepareForSleep(GDBusConnection*, const gchar*,
                                     const gchar*, const gchar*, const gchar*,
                                     GVariant* parameters, gpointer self) {
  gboolean going_to_sleep = FALSE;
  g_variant_get(parameters, "(b)", &going_to_sleep);
  if (!going_to_sleep) static_cast<NativeBridge*>(self)->ClockDisturbed();
}

void NativeBridge::ClockDisturbed() {
  fl_method_channel_invoke_method(channel_, "clockDisturbed", nullptr, nullptr,
                                  nullptr, nullptr);
}
