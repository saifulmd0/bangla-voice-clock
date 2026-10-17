/// Hours of the day when the clock stays silent, such as 23:00 to 07:00.
class QuietHours {
  const QuietHours({required this.startHour, required this.endHour})
    : assert(startHour >= 0 && startHour < 24),
      assert(endHour >= 0 && endHour < 24);

  final int startHour;
  final int endHour;

  /// Whether [time] falls inside, wrapping past midnight. Equal start and
  /// end hours mean no quiet time at all.
  bool contains(DateTime time) {
    final h = time.hour;
    if (startHour == endHour) return false;
    return startHour < endHour
        ? h >= startHour && h < endHour
        : h >= startHour || h < endHour;
  }
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
