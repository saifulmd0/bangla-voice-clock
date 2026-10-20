import '../clock/announcement_schedule.dart';
import '../speech/bangla_phrase_builder.dart';

/// The interface language. Announcements are always spoken in Bangla.
enum AppLanguage {
  bn('বাংলা'),
  en('English');

  const AppLanguage(this.label);

  /// The language's name, written in itself.
  final String label;
}

/// What the menu-bar item shows: the time, the logo icon, or both.
enum MenuBarShows { time, logo, both }

/// Light or dark, or following macOS.
enum Appearance { system, light, dark }

/// Everything the user can change, saved between launches.
class AppSettings {
  const AppSettings({
    this.muted = false,
    this.intervalMinutes = 15,
    this.style = AnnouncementStyle.exact,
    this.voiceId = 'bn_ai',
    this.volume = 1.0,
    this.chime = true,
    this.notify = true,
    this.quietHoursEnabled = false,
    this.quietStart = 23 * 60,
    this.quietEnd = 7 * 60,
    this.menuBarShows = MenuBarShows.time,
    this.language = AppLanguage.bn,
    this.appearance = Appearance.light,
    this.sayBeje = true,
    this.timerMinutes = 25,
    this.welcomed = false,
    this.outputDeviceId = '',
    this.outputDeviceName = '',
    this.checkUpdates = true,
    this.skippedVersion = '',
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    const d = AppSettings();
    T read<T>(String key, T fallback) {
      final value = json[key];
      return value is T ? value : fallback;
    }

    final interval = read('intervalMinutes', d.intervalMinutes);
    // Version 0.1 saved quiet hours as whole hours.
    int quiet(String key, String hourKey, int fallback) {
      final hour = json[hourKey];
      return read(key, hour is int ? hour * 60 : fallback) % minutesPerDay;
    }

    return AppSettings(
      muted: read('muted', d.muted),
      intervalMinutes: intervals.contains(interval)
          ? interval
          : d.intervalMinutes,
      style: AnnouncementStyle.values.asNameMap()[json['style']] ?? d.style,
      voiceId: read('voiceId', d.voiceId),
      volume: read<num>('volume', d.volume).toDouble().clamp(0.0, 1.0),
      chime: read('chime', d.chime),
      notify: read('notify', d.notify),
      quietHoursEnabled: read('quietHoursEnabled', d.quietHoursEnabled),
      quietStart: quiet('quietStart', 'quietStartHour', d.quietStart),
      quietEnd: quiet('quietEnd', 'quietEndHour', d.quietEnd),
      menuBarShows:
          MenuBarShows.values.asNameMap()[json['menuBarShows']] ??
          // Before 1.1 this was a switch, off meaning the icon.
          (json['showClockInMenuBar'] == false
              ? MenuBarShows.logo
              : d.menuBarShows),
      language: AppLanguage.values.asNameMap()[json['language']] ?? d.language,
      appearance:
          Appearance.values.asNameMap()[json['appearance']] ?? d.appearance,
      sayBeje: read('sayBeje', d.sayBeje),
      timerMinutes: read('timerMinutes', d.timerMinutes).clamp(1, 180),
      welcomed: read('welcomed', d.welcomed),
      outputDeviceId: read('outputDeviceId', d.outputDeviceId),
      outputDeviceName: read('outputDeviceName', d.outputDeviceName),
      checkUpdates: read('checkUpdates', d.checkUpdates),
      skippedVersion: read('skippedVersion', d.skippedVersion),
    );
  }

  /// The announcement intervals on offer, in minutes.
  static const intervals = [15, 30, 60];

  final bool muted;
  final int intervalMinutes;
  final AnnouncementStyle style;
  final String voiceId;

  /// Playback volume, 0–1.
  final double volume;
  final bool chime;
  final bool notify;
  final bool quietHoursEnabled;

  /// When quiet hours begin and end, in minutes from midnight.
  final int quietStart;
  final int quietEnd;
  final MenuBarShows menuBarShows;
  final AppLanguage language;

  /// Light by default, the look the brand was designed in.
  final Appearance appearance;

  /// Whether exact times say "দশটা বেজে সাত মিনিট" or "দশটা সাত মিনিট".
  final bool sayBeje;

  /// The length last chosen for the timer, in minutes.
  final int timerMinutes;

  /// Whether the settings window has been shown once, on first launch.
  final bool welcomed;

  /// The sound output chosen for announcements, empty for the system's
  /// default. The name is kept to show while the device is unplugged.
  final String outputDeviceId;
  final String outputDeviceName;

  /// Whether to look for a newer version once a day.
  final bool checkUpdates;

  /// A version the user chose not to be told about again.
  final String skippedVersion;

  AnnouncementSchedule get schedule => AnnouncementSchedule(
    intervalMinutes: intervalMinutes,
    quietHours: quietHoursEnabled
        ? QuietHours(start: quietStart, end: quietEnd)
        : null,
  );

  AppSettings copyWith({
    bool? muted,
    int? intervalMinutes,
    AnnouncementStyle? style,
    String? voiceId,
    double? volume,
    bool? chime,
    bool? notify,
    bool? quietHoursEnabled,
    int? quietStart,
    int? quietEnd,
    MenuBarShows? menuBarShows,
    AppLanguage? language,
    Appearance? appearance,
    bool? sayBeje,
    int? timerMinutes,
    bool? welcomed,
    String? outputDeviceId,
    String? outputDeviceName,
    bool? checkUpdates,
    String? skippedVersion,
  }) => AppSettings(
    muted: muted ?? this.muted,
    intervalMinutes: intervalMinutes ?? this.intervalMinutes,
    style: style ?? this.style,
    voiceId: voiceId ?? this.voiceId,
    volume: volume ?? this.volume,
    chime: chime ?? this.chime,
    notify: notify ?? this.notify,
    quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
    quietStart: quietStart ?? this.quietStart,
    quietEnd: quietEnd ?? this.quietEnd,
    menuBarShows: menuBarShows ?? this.menuBarShows,
    language: language ?? this.language,
    appearance: appearance ?? this.appearance,
    sayBeje: sayBeje ?? this.sayBeje,
    timerMinutes: timerMinutes ?? this.timerMinutes,
    welcomed: welcomed ?? this.welcomed,
    outputDeviceId: outputDeviceId ?? this.outputDeviceId,
    outputDeviceName: outputDeviceName ?? this.outputDeviceName,
    checkUpdates: checkUpdates ?? this.checkUpdates,
    skippedVersion: skippedVersion ?? this.skippedVersion,
  );

  Map<String, dynamic> toJson() => {
    'muted': muted,
    'intervalMinutes': intervalMinutes,
    'style': style.name,
    'voiceId': voiceId,
    'volume': volume,
    'chime': chime,
    'notify': notify,
    'quietHoursEnabled': quietHoursEnabled,
    'quietStart': quietStart,
    'quietEnd': quietEnd,
    'menuBarShows': menuBarShows.name,
    'language': language.name,
    'appearance': appearance.name,
    'sayBeje': sayBeje,
    'timerMinutes': timerMinutes,
    'welcomed': welcomed,
    'outputDeviceId': outputDeviceId,
    'outputDeviceName': outputDeviceName,
    'checkUpdates': checkUpdates,
    'skippedVersion': skippedVersion,
  };
}
