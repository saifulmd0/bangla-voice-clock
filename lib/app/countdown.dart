import 'dart:async';

/// A countdown that calls [onMinute] with the whole minutes left as each
/// minute begins (straight away for the first), [onTick] about twice a
/// second for the display, and [onDone] at the end.
class Countdown {
  Countdown({
    required this.onMinute,
    required this.onDone,
    required this.onTick,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final void Function(int minutesLeft) onMinute;
  final void Function() onDone;
  final void Function() onTick;
  final DateTime Function() _now;

  DateTime? _end;
  Duration _total = Duration.zero;
  Timer? _timer;
  int? _lastMinute;

  bool get running => _end != null;
  Duration get total => _total;

  /// Time left, counted from the wall clock so it stays right after sleep.
  Duration get remaining {
    final end = _end;
    if (end == null) return Duration.zero;
    final left = end.difference(_now());
    return left.isNegative ? Duration.zero : left;
  }

  void start(Duration length) {
    stop();
    _total = length;
    _end = _now().add(length);
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) => _check());
    _check();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _end = null;
    _lastMinute = null;
  }

  void _check() {
    final left = remaining;
    if (left == Duration.zero) {
      stop();
      onTick();
      onDone();
      return;
    }
    // The minute now beginning: 25 at 25:00, 24 from 24:00 down to 23:00.01.
    final minute = (left.inMilliseconds / Duration.millisecondsPerMinute)
        .ceil();
    onTick();
    if (minute != _lastMinute) {
      _lastMinute = minute;
      onMinute(minute);
    }
  }
}
