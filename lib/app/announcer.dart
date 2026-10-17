import 'dart:async';

import '../core/clock/announcement_schedule.dart';

/// Calls [onTick] at the start of every minute.
///
/// The timer is re-armed from the wall clock each minute, so it corrects
/// itself after sleep, clock changes and daylight saving; call [restart] to
/// correct at once instead of at the next tick.
class MinuteTicker {
  MinuteTicker(this.onTick, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final void Function(DateTime now) onTick;
  final DateTime Function() _now;
  Timer? _timer;

  void start() => _arm();

  void restart() {
    _timer?.cancel();
    onTick(_now());
    _arm();
  }

  void stop() => _timer?.cancel();

  void _arm() {
    final now = _now();
    final next = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute + 1,
    );
    // A little past the boundary, so the tick never lands a hair early.
    _timer = Timer(next.difference(now) + const Duration(milliseconds: 50), () {
      onTick(_now());
      _arm();
    });
  }
}

/// Decides, on each minute tick, whether to speak.
class Announcer {
  Announcer({required this.schedule, required this.muted, required this.speak});

  final AnnouncementSchedule Function() schedule;
  final bool Function() muted;
  final Future<void> Function(DateTime minute) speak;
  DateTime? _last;

  /// Speaks if [now]'s minute is on the schedule, once per minute however
  /// often it's called. Returns whether it spoke.
  Future<bool> onMinute(DateTime now) async {
    final minute = DateTime(now.year, now.month, now.day, now.hour, now.minute);
    if (muted() || minute == _last || !schedule().announcesAt(minute)) {
      return false;
    }
    _last = minute;
    await speak(minute);
    return true;
  }
}
