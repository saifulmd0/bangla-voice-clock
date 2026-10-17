import 'bangla_words.dart';
import 'speech_token.dart';

enum AnnouncementStyle {
  /// সোয়া / সাড়ে / পৌনে, the way people say the time aloud.
  /// Only valid on the quarter hour.
  traditional,

  /// "দশটা বেজে সাত মিনিট", valid for any minute.
  exact,
}

/// Which part of the day each hour belongs to.
///
/// Defaults follow the original Bangla Voice Clock: ভোর 4–6, সকাল 7–11,
/// দুপুর 12–15, বিকাল 16–17, সন্ধ্যা 18–19, রাত 20–3.
class DayZones {
  /// [startHours] maps the hour (0–23) at which each zone begins.
  DayZones(Map<int, DayZone> startHours) : _byHour = _expand(startHours);

  static List<DayZone> _expand(Map<int, DayZone> startHours) {
    if (startHours.isEmpty) {
      throw ArgumentError.value(startHours, 'startHours', 'is empty');
    }
    for (final hour in startHours.keys) {
      RangeError.checkValueInInterval(hour, 0, 23, 'startHours key');
    }
    return List.generate(24, (hour) {
      // The zone that started most recently, wrapping past midnight.
      for (var back = 0; back < 24; back++) {
        final zone = startHours[(hour - back) % 24];
        if (zone != null) return zone;
      }
      throw StateError('unreachable');
    });
  }

  static final standard = DayZones(const {
    4: DayZone.bhor,
    7: DayZone.sokal,
    12: DayZone.dupur,
    16: DayZone.bikal,
    18: DayZone.sondha,
    20: DayZone.raat,
  });

  final List<DayZone> _byHour;

  DayZone forHour(int hour24) => _byHour[hour24];
}

/// Builds the words of a Bangla time announcement.
///
/// For 10:15 in the morning it produces "এখন সময় সকাল সোয়া দশটা".
class BanglaPhraseBuilder {
  BanglaPhraseBuilder({
    DayZones? zones,
    this.includeStarter = true,
    this.sayBeje = true,
  }) : zones = zones ?? DayZones.standard;

  final DayZones zones;
  final bool includeStarter;

  /// Whether the exact style says "দশটা বেজে সাত মিনিট" or, like the
  /// original 1998 voice, "দশটা সাত মিনিট".
  final bool sayBeje;

  /// Whether [style] can announce a time with this [minute].
  static bool supports(AnnouncementStyle style, int minute) =>
      style == AnnouncementStyle.exact || minute % 15 == 0;

  List<SpeechToken> build(
    int hour,
    int minute, {
    AnnouncementStyle style = AnnouncementStyle.traditional,
  }) {
    RangeError.checkValueInInterval(hour, 0, 23, 'hour');
    RangeError.checkValueInInterval(minute, 0, 59, 'minute');
    if (!supports(style, minute)) {
      throw ArgumentError.value(
        minute,
        'minute',
        'traditional style needs a quarter hour (0, 15, 30 or 45)',
      );
    }

    // The part of the day follows the actual time, so 11:45 is still
    // "সকাল পৌনে বারোটা" even though it names the next hour.
    final zone = zones.forHour(hour);
    return [
      if (includeStarter) const SpeechToken(ClipKeys.starter, starterWord),
      SpeechToken(ClipKeys.zone(zone), zone.word),
      ...switch (style) {
        AnnouncementStyle.traditional => _traditional(hour, minute),
        AnnouncementStyle.exact => _exact(hour, minute),
      },
    ];
  }

  List<SpeechToken> _traditional(int hour, int minute) {
    final h12 = _to12(hour);
    final next12 = _to12((hour + 1) % 24);
    return switch (minute) {
      0 => [_hour(h12)],
      15 => [const SpeechToken(ClipKeys.sowa, sowaWord), _hour(h12)],
      30 when h12 == 1 => [
        const SpeechToken(
          ClipKeys.der,
          derWord,
          fallback: [ClipKeys.sare, 'hour.1'],
        ),
      ],
      30 when h12 == 2 => [
        const SpeechToken(
          ClipKeys.arai,
          araiWord,
          fallback: [ClipKeys.sare, 'hour.2'],
        ),
      ],
      30 => [const SpeechToken(ClipKeys.sare, sareWord), _hour(h12)],
      45 => [const SpeechToken(ClipKeys.poune, pouneWord), _hour(next12)],
      _ => throw StateError('unreachable'),
    };
  }

  List<SpeechToken> _exact(int hour, int minute) => [
    _hour(_to12(hour)),
    if (minute > 0) ...[
      if (sayBeje)
        const SpeechToken(ClipKeys.beje, bejeWord, optional: true)
      else
        const SpeechToken(ClipKeys.open, '', optional: true),
      SpeechToken(ClipKeys.number(minute), numberWords[minute]),
      const SpeechToken(ClipKeys.minute, minuteWord),
    ],
  ];

  static SpeechToken _hour(int h12) =>
      SpeechToken(ClipKeys.hour(h12), hourWords[h12]);

  static int _to12(int hour24) => hour24 % 12 == 0 ? 12 : hour24 % 12;
}
