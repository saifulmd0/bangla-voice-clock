import 'dart:math' as math;

import 'package:bangla_voice_clock/core/audio/chime.dart';
import 'package:bangla_voice_clock/core/clock/announcement_schedule.dart';
import 'package:bangla_voice_clock/core/clock/bangla_clock.dart';
import 'package:bangla_voice_clock/ui/brand.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Bangla clock', () {
    test('digits', () {
      expect(banglaDigits(1234567890), '১২৩৪৫৬৭৮৯০');
      expect(banglaDigits('10:05'), '১০:০৫');
    });

    test('12-hour face with the part of the day', () {
      expect(banglaClockFace(DateTime(2026, 1, 1, 0, 5)), '১২:০৫');
      expect(banglaClockFace(DateTime(2026, 1, 1, 13, 30)), '১:৩০');
      expect(banglaClockWithZone(DateTime(2026, 1, 1, 10, 15)), 'সকাল ১০:১৫');
      expect(banglaClockWithZone(DateTime(2026, 1, 1, 21)), 'রাত ৯:০০');
    });
  });

  group('QuietHours', () {
    test('within a day', () {
      const q = QuietHours(startHour: 13, endHour: 15);
      expect(q.contains(DateTime(2026, 1, 1, 12, 59)), isFalse);
      expect(q.contains(DateTime(2026, 1, 1, 13)), isTrue);
      expect(q.contains(DateTime(2026, 1, 1, 14, 59)), isTrue);
      expect(q.contains(DateTime(2026, 1, 1, 15)), isFalse);
    });

    test('past midnight', () {
      const q = QuietHours(startHour: 23, endHour: 7);
      expect(q.contains(DateTime(2026, 1, 1, 22, 45)), isFalse);
      expect(q.contains(DateTime(2026, 1, 1, 23)), isTrue);
      expect(q.contains(DateTime(2026, 1, 1, 3)), isTrue);
      expect(q.contains(DateTime(2026, 1, 1, 7)), isFalse);
    });

    test('equal hours mean none', () {
      const q = QuietHours(startHour: 5, endHour: 5);
      expect(q.contains(DateTime(2026, 1, 1, 5)), isFalse);
    });
  });

  group('AnnouncementSchedule', () {
    test('announces on each interval from the top of the hour', () {
      const every30 = AnnouncementSchedule(intervalMinutes: 30);
      expect(every30.announcesAt(DateTime(2026, 1, 1, 9)), isTrue);
      expect(every30.announcesAt(DateTime(2026, 1, 1, 9, 15)), isFalse);
      expect(every30.announcesAt(DateTime(2026, 1, 1, 9, 30, 59)), isTrue);
    });

    test('next announcement', () {
      const every15 = AnnouncementSchedule(intervalMinutes: 15);
      expect(
        every15.nextAfter(DateTime(2026, 1, 1, 9, 0, 30)),
        DateTime(2026, 1, 1, 9, 15),
      );
      expect(
        every15.nextAfter(DateTime(2026, 1, 1, 23, 50)),
        DateTime(2026, 1, 2),
      );
    });

    test('skips quiet hours', () {
      const s = AnnouncementSchedule(
        intervalMinutes: 60,
        quietHours: QuietHours(startHour: 23, endHour: 7),
      );
      expect(s.announcesAt(DateTime(2026, 1, 1, 2)), isFalse);
      expect(
        s.nextAfter(DateTime(2026, 1, 1, 22, 10)),
        DateTime(2026, 1, 2, 7),
      );
    });
  });

  test('the dial is a 12-hour face for the half of the day on show', () {
    DayDialPainter at(DateTime now) => DayDialPainter(
      now: now,
      schedule: const AnnouncementSchedule(intervalMinutes: 15),
      muted: false,
      zoneLabels: (z) => z.word,
      labelStyle: const TextStyle(),
      color: Sky.blue,
      background: Sky.band,
    );
    const top = -math.pi / 2;
    // Twelve at the top, three to the right, before and after noon alike.
    expect(at(DateTime(2026, 1, 1, 10)).angleOf(0), closeTo(top, 1e-9));
    expect(at(DateTime(2026, 1, 1, 10)).angleOf(3 * 60), closeTo(0, 1e-9));
    expect(at(DateTime(2026, 1, 1, 22)).angleOf(15 * 60), closeTo(0, 1e-9));
    // 10:20 sits where 10:20 is on a clock.
    expect(
      at(DateTime(2026, 1, 1, 10, 20)).angleOf(10 * 60 + 20),
      closeTo(top + (620 / 720) * 2 * math.pi, 1e-9),
    );
  });

  test('chime is a short, quiet, click-free bell', () {
    final c = chime(24000);
    expect(c.duration.inMilliseconds, inInclusiveRange(1200, 1600));
    final peak = c.samples.map((s) => s.abs()).reduce((a, b) => a > b ? a : b);
    expect(peak, lessThan(0.3 * 32767));
    expect(c.samples.first, 0);
    expect(c.samples.last.abs(), lessThan(200));
  });
}
