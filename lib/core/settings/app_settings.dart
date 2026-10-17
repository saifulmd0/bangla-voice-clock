import '../clock/announcement_schedule.dart';
import '../speech/bangla_phrase_builder.dart';

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
    this.showClockInMenuBar = true,
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
      showClockInMenuBar: read('showClockInMenuBar', d.showClockInMenuBar),
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
  final bool showClockInMenuBar;

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
    bool? showClockInMenuBar,
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
    showClockInMenuBar: showClockInMenuBar ?? this.showClockInMenuBar,
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
    'showClockInMenuBar': showClockInMenuBar,
    'welcomed': welcomed,
  };
}
