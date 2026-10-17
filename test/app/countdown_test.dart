import 'package:bangla_voice_clock/app/countdown.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('says each minute left, then finishes', () {
    fakeAsync((async) {
      final clock = async.getClock(DateTime(2026, 1, 1, 10));
      final said = <int>[];
      var done = 0;
      final countdown = Countdown(
        onMinute: said.add,
        onDone: () => done++,
        onTick: () {},
        now: clock.now,
      )..start(const Duration(minutes: 3));
      expect(said, [3]);
      async.elapse(const Duration(seconds: 61));
      expect(said, [3, 2]);
      async.elapse(const Duration(minutes: 2));
      expect(said, [3, 2, 1]);
      expect(done, 1);
      expect(countdown.running, isFalse);
    });
  });

  test('stop ends it quietly', () {
    fakeAsync((async) {
      final clock = async.getClock(DateTime(2026, 1, 1, 10));
      var done = 0;
      final said = <int>[];
      final countdown = Countdown(
        onMinute: said.add,
        onDone: () => done++,
        onTick: () {},
        now: clock.now,
      )..start(const Duration(minutes: 5));
      countdown.stop();
      async.elapse(const Duration(minutes: 10));
      expect(said, [5]);
      expect(done, 0);
    });
  });
}
