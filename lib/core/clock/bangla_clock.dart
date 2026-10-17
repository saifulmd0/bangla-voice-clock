import '../speech/bangla_phrase_builder.dart';

const _digits = '০১২৩৪৫৬৭৮৯';

/// Writes the ASCII digits in [value] as Bangla digits: 10 → "১০".
String banglaDigits(Object value) => value.toString().replaceAllMapped(
  RegExp('[0-9]'),
  (m) => _digits[m[0]!.codeUnitAt(0) - 0x30],
);

/// The 12-hour clock face, such as "১০:০৫".
String banglaClockFace(DateTime time) {
  final h12 = time.hour % 12 == 0 ? 12 : time.hour % 12;
  return banglaDigits('$h12:${time.minute.toString().padLeft(2, '0')}');
}

/// The clock face with its part of the day, such as "সকাল ১০:০৫".
String banglaClockWithZone(DateTime time, {DayZones? zones}) =>
    '${(zones ?? DayZones.standard).forHour(time.hour).word} '
    '${banglaClockFace(time)}';
