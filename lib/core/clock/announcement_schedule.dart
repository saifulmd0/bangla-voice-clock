/// Minutes in a day; quiet hours are measured in minutes from midnight.
const minutesPerDay = 24 * 60;

/// The part of the day when the clock stays silent, such as 23:30 to 07:00,
/// as minutes from midnight.
class QuietHours {
  const QuietHours({required this.start, required this.end})
    : assert(start >= 0 && start < minutesPerDay),
      assert(end >= 0 && end < minutesPerDay);

  /// The first silent minute.
  final int start;

  /// The first minute that speaks again.
  final int end;

  /// Whether [time] falls inside, wrapping past midnight. Equal start and
  /// end mean no quiet time at all.
  bool contains(DateTime time) {
    final m = time.hour * 60 + time.minute;
    if (start == end) return false;
    return start < end ? m >= start && m < end : m >= start || m < end;
  }

  @override
  bool operator ==(Object other) =>
      other is QuietHours && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);
}

/// When the clock announces the time: every [intervalMinutes] from the top
/// of the hour, except during [quietHours].
class AnnouncementSchedule {
  const AnnouncementSchedule({required this.intervalMinutes, this.quietHours})
    : assert(intervalMinutes > 0 && 60 % intervalMinutes == 0);

  final int intervalMinutes;
  final QuietHours? quietHours;

  /// Whether the clock speaks during the minute that contains [time].
  bool announcesAt(DateTime time) =>
      time.minute % intervalMinutes == 0 &&
      !(quietHours?.contains(time) ?? false);

  /// The first announcement after the minute containing [time], or null if
  /// quiet hours cover every announcement of the day.
  DateTime? nextAfter(DateTime time) {
    var t = DateTime(time.year, time.month, time.day, time.hour, time.minute);
    for (var i = 0; i < 24 * 60; i++) {
      // Building from fields rather than adding a Duration keeps this on
      // wall-clock minutes across daylight-saving changes.
      t = DateTime(t.year, t.month, t.day, t.hour, t.minute + 1);
      if (announcesAt(t)) return t;
    }
    return null;
  }
}
