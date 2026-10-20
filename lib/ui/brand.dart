import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/clock/announcement_schedule.dart';
import '../core/speech/bangla_phrase_builder.dart';
import '../core/speech/bangla_words.dart';

/// The brand's colours: a clear morning sky, with coral for "now".
abstract final class Sky {
  static const blue = Color(0xFF2F74D0);
  static const blueNight = Color(0xFF8AB8F5);
  static const coral = Color(0xFFFF8A65);

  /// Edge for the coral now dot, so it holds 3:1 against the pale band.
  static const coralEdge = Color(0xFFC7471F);
  static const ink = Color(0xFF172338);
  static const inkNight = Color(0xFFE8EFFA);
  static const ground = Color(0xFFF5F9FF);
  static const groundNight = Color(0xFF0F1724);
  static const band = Color(0xFFE1EEFD);
  static const bandNight = Color(0xFF172A45);
  static const tile = Color(0xFFEEF5FF);
}

/// The logo: a clock face of twelve dots, the four quarter hours larger and
/// the twelve in coral, with hands at ten o'clock. The dots are the same
/// fingertip dots the dial in the app uses for announcements.
class DotDialPainter extends CustomPainter {
  const DotDialPainter({
    this.color = Sky.blue,
    this.accent = Sky.coral,
    this.weight = 1,
    this.quartersOnly = false,
  });

  /// The menu-bar version: one colour and a heavier drawing. At 1x
  /// ([tiny], 18 pixels) the eight small dots vanish, so only the quarter
  /// hours are drawn.
  const DotDialPainter.template({this.color = Colors.black, bool tiny = false})
    : accent = null,
      weight = tiny ? 1.45 : 1.2,
      quartersOnly = tiny;

  final Color color;

  /// Colour of the twelve o'clock dot, or null for a single-colour mark.
  final Color? accent;

  /// Drawing weight relative to the app icon's.
  final double weight;
  final bool quartersOnly;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide / 2;
    final c = size.center(Offset.zero);
    final fill = Paint()..color = color;
    for (var i = 0; i < 12; i++) {
      final quarter = i % 3 == 0;
      if (!quarter && quartersOnly) continue;
      final at = _at(c, r * 0.8, -math.pi / 2 + i * math.pi / 6);
      final radius = (quarter ? 0.1 : 0.062) * r * weight;
      canvas.drawCircle(
        at,
        radius,
        i == 0 && accent != null ? (Paint()..color = accent!) : fill,
      );
    }
    final hand = Paint()
      ..color = color
      ..strokeWidth = r * 0.12 * weight
      ..strokeCap = StrokeCap.round;
    // Minute hand up to twelve, hour hand to ten. At small sizes the
    // minute hand stops short, so a clear gap keeps it from merging with
    // the twelve dot into one bar, and the hour hand grows to match, or it
    // shrinks to a smudge beside the hub.
    final minute = quartersOnly ? 0.42 : 0.5;
    final hour = quartersOnly ? 0.44 : 0.36;
    canvas
      ..drawLine(c, _at(c, r * minute, -math.pi / 2), hand)
      ..drawLine(c, _at(c, r * hour, -math.pi / 2 - math.pi / 3), hand)
      ..drawCircle(c, r * 0.1 * weight, fill);
  }

  @override
  bool shouldRepaint(DotDialPainter old) =>
      old.color != color ||
      old.accent != accent ||
      old.weight != weight ||
      old.quartersOnly != quartersOnly;
}

/// Draws the current half of the day as a 12-hour clock face, twelve at
/// the top, so the coral dot at [now] sits where a clock's hour hand would:
/// the parts of the day in this half as arcs, and a dot for every scheduled
/// announcement (none in quiet hours, hollow when muted, dimmed once made).
class DayDialPainter extends CustomPainter {
  DayDialPainter({
    required this.now,
    required this.schedule,
    required this.muted,
    this.speaking = false,
    required this.zoneLabels,
    required this.labelStyle,
    required this.color,
    required this.background,
    DayZones? zones,
  }) : zones = zones ?? DayZones.standard;

  final DateTime now;
  final AnnouncementSchedule schedule;
  final bool muted;

  /// Lights the now dot while the clock is speaking.
  final bool speaking;
  final DayZones zones;

  /// The label for each part of the day, in the interface language.
  final String Function(DayZone zone) zoneLabels;
  final TextStyle labelStyle;

  /// Colour of the arcs and dots, and of the band behind the dial.
  final Color color;
  final Color background;

  /// The first minute of the half of the day the dial shows: midnight
  /// before noon, noon after.
  int get _start => now.hour < 12 ? 0 : 12 * 60;

  /// The angle of [minuteOfDay] on the 12-hour face.
  double angleOf(num minuteOfDay) =>
      -math.pi / 2 + (minuteOfDay - _start) / (12 * 60) * 2 * math.pi;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide / 2;
    final c = size.center(Offset.zero);
    final line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // The parts of the day, each its own arc with a small gap between.
    final arcRect = Rect.fromCircle(center: c, radius: r * 0.66);
    for (final (start, end, zone) in _zoneSpans()) {
      const gap = 0.035;
      canvas.drawArc(
        arcRect,
        angleOf(start) + gap,
        angleOf(end) - angleOf(start) - 2 * gap,
        false,
        line
          ..strokeWidth = r * 0.022
          ..color = color.withValues(alpha: 0.45),
      );
      _label(canvas, c, r * 0.84, angleOf((start + end) / 2), zoneLabels(zone));
    }

    // A fingertip dot for every announcement of the day, sized to its
    // spacing so neighbours never merge and each one can be counted.
    final perDay = 12 * 60 ~/ schedule.intervalMinutes;
    final pitch = 2 * math.pi * r * 0.76 / perDay;
    final dot = math.min(r * 0.022, pitch * 0.22);
    for (var m = _start; m < _start + 12 * 60; m++) {
      final t = DateTime(now.year, now.month, now.day, m ~/ 60, m % 60);
      if (!schedule.announcesAt(t)) continue;
      final p = _at(c, r * 0.76, angleOf(m));
      final size = m % 60 == 0 ? math.min(dot * 1.45, pitch * 0.34) : dot;
      // Announcements already made today are dimmed, so the next one
      // stands out.
      final past = m < now.hour * 60 + now.minute;
      final ink = past ? color.withValues(alpha: 0.35) : color;
      if (muted) {
        canvas.drawCircle(
          p,
          size,
          Paint()
            ..color = ink.withValues(alpha: ink.a * 0.8)
            ..style = PaintingStyle.stroke
            ..strokeWidth = dot * 0.5,
        );
      } else {
        canvas.drawCircle(p, size, Paint()..color = ink);
      }
    }

    // Now, haloed in coral while the clock speaks.
    final nowAt = _at(c, r * 0.76, angleOf(now.hour * 60 + now.minute));
    if (speaking) {
      canvas.drawCircle(
        nowAt,
        r * 0.13,
        Paint()
          ..color = Sky.coral.withValues(alpha: 0.4)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.04),
      );
    }
    canvas
      ..drawCircle(nowAt, r * 0.07, Paint()..color = background)
      ..drawCircle(nowAt, r * 0.055, Paint()..color = Sky.coralEdge)
      ..drawCircle(nowAt, r * 0.042, Paint()..color = Sky.coral);
  }

  /// Each part of the day in the half on show, as (start minute, end
  /// minute, zone), cut at noon and midnight.
  List<(int, int, DayZone)> _zoneSpans() {
    final spans = <(int, int, DayZone)>[];
    final first = _start ~/ 60;
    var start = first;
    for (var h = first + 1; h <= first + 12; h++) {
      if (h == first + 12 || zones.forHour(h) != zones.forHour(start)) {
        spans.add((start * 60, h * 60, zones.forHour(start)));
        start = h;
      }
    }
    return spans;
  }

  void _label(
    Canvas canvas,
    Offset c,
    double radius,
    double angle,
    String text,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: labelStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    // Push the label out by half its extent along the radius, so its near
    // edge, not its centre, sits at [radius] and clears the dot row.
    final reach =
        (math.cos(angle).abs() * painter.width +
            math.sin(angle).abs() * painter.height) /
        2;
    final p = _at(c, radius + reach, angle);
    painter.paint(canvas, p - Offset(painter.width / 2, painter.height / 2));
  }

  @override
  bool shouldRepaint(DayDialPainter old) =>
      old.now != now ||
      old.muted != muted ||
      old.speaking != speaking ||
      old.schedule.intervalMinutes != schedule.intervalMinutes ||
      old.schedule.quietHours != schedule.quietHours ||
      old.labelStyle != labelStyle ||
      old.color != color ||
      old.background != background;
}

Offset _at(Offset c, double radius, double angle) =>
    c + Offset(math.cos(angle), math.sin(angle)) * radius;
