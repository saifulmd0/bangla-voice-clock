import 'package:bangla_voice_clock/app/announcer.dart';
import 'package:bangla_voice_clock/core/clock/announcement_schedule.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('MinuteTicker ticks at the start of each minute', () {
    fakeAsync((async) {
      final clock = async.getClock(DateTime(2026, 1, 1, 9, 59, 40));
      final ticks = <DateTime>[];
      MinuteTicker(ticks.add, now: clock.now).start();
      async.elapse(const Duration(minutes: 2));
      expect(ticks.map((t) => (t.hour, t.minute, t.second)), [
        (10, 0, 0),
        (10, 1, 0),
      ]);
    });
  });

  test('MinuteTicker.restart ticks at once', () {
    fakeAsync((async) {
      final clock = async.getClock(DateTime(2026, 1, 1, 9, 59, 40));
      final ticks = <DateTime>[];
      final ticker = MinuteTicker(ticks.add, now: clock.now)..start();
      async.elapse(const Duration(seconds: 5));
      ticker.restart();
      expect(ticks, hasLength(1));
      async.elapse(const Duration(seconds: 20));
      expect(ticks, hasLength(2));
    });
  });

  group('Announcer', () {
    final spoken = <DateTime>[];
    var muted = false;
    final announcer = Announcer(
      schedule: () => const AnnouncementSchedule(intervalMinutes: 15),
      muted: () => muted,
      speak: (t) async => spoken.add(t),
    );
    setUp(() {
      spoken.clear();
      muted = false;
    });

    test('speaks once per scheduled minute', () async {
      expect(
        await announcer.onMinute(DateTime(2026, 1, 1, 10, 15, 0, 50)),
        isTrue,
      );
      expect(
        await announcer.onMinute(DateTime(2026, 1, 1, 10, 15, 30)),
        isFalse,
      );
      expect(spoken, [DateTime(2026, 1, 1, 10, 15)]);
    });

    test('stays silent off schedule and when muted', () async {
      expect(await announcer.onMinute(DateTime(2026, 1, 1, 10, 16)), isFalse);
      muted = true;
      expect(await announcer.onMinute(DateTime(2026, 1, 1, 10, 30)), isFalse);
      expect(spoken, isEmpty);
    });
  });
}
