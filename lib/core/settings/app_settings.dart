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

/// What the menu-bar item shows.
enum MenuBarShows { time, logo }

/// Light or dark, or following macOS.
enum Appearance { system, light, dark }

/// Everything the user can change, saved between launches.
class AppSettings {
  const AppSettings({
    this.muted = false,
    this.intervalMinutes = 15,
    this.style = AnnouncementStyle.traditional,
    this.voiceId = 'bn_ai',
    this.volume = 1.0,
    this.chime = true,
    this.notify = true,
    this.quietHoursEnabled = false,
    this.quietStartHour = 23,
    this.quietEndHour = 7,
    this.menuBarShows = MenuBarShows.time,
    this.language = AppLanguage.bn,
    this.appearance = Appearance.light,
    this.sayBeje = true,
    this.welcomed = false,
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    const d = AppSettings();
    T read<T>(String key, T fallback) {
      final value = json[key];
      return value is T ? value : fallback;
    }

    final interval = read('intervalMinutes', d.intervalMinutes);
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
      quietStartHour: read('quietStartHour', d.quietStartHour) % 24,
      quietEndHour: read('quietEndHour', d.quietEndHour) % 24,
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
      welcomed: read('welcomed', d.welcomed),
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
  final int quietStartHour;
  final int quietEndHour;
  final MenuBarShows menuBarShows;
  final AppLanguage language;

  /// Light by default, the look the brand was designed in.
  final Appearance appearance;

  /// Whether exact times say "দশটা বেজে সাত মিনিট" or "দশটা সাত মিনিট".
  final bool sayBeje;

  /// Whether the settings window has been shown once, on first launch.
  final bool welcomed;

  AnnouncementSchedule get schedule => AnnouncementSchedule(
    intervalMinutes: intervalMinutes,
    quietHours: quietHoursEnabled
        ? QuietHours(startHour: quietStartHour, endHour: quietEndHour)
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
    int? quietStartHour,
    int? quietEndHour,
    MenuBarShows? menuBarShows,
    AppLanguage? language,
    Appearance? appearance,
    bool? sayBeje,
    bool? welcomed,
  }) => AppSettings(
    muted: muted ?? this.muted,
    intervalMinutes: intervalMinutes ?? this.intervalMinutes,
    style: style ?? this.style,
    voiceId: voiceId ?? this.voiceId,
    volume: volume ?? this.volume,
    chime: chime ?? this.chime,
    notify: notify ?? this.notify,
    quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
    quietStartHour: quietStartHour ?? this.quietStartHour,
    quietEndHour: quietEndHour ?? this.quietEndHour,
    menuBarShows: menuBarShows ?? this.menuBarShows,
    language: language ?? this.language,
    appearance: appearance ?? this.appearance,
    sayBeje: sayBeje ?? this.sayBeje,
    welcomed: welcomed ?? this.welcomed,
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
    'quietStartHour': quietStartHour,
    'quietEndHour': quietEndHour,
    'menuBarShows': menuBarShows.name,
    'language': language.name,
    'appearance': appearance.name,
    'sayBeje': sayBeje,
    'welcomed': welcomed,
  };
}
