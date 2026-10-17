import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/clock/announcement_schedule.dart';
import '../core/speech/bangla_phrase_builder.dart';
import '../core/speech/bangla_words.dart';

/// The brand's colours, taken from alpona: rice-paste line on fired earth.
abstract final class Alpona {
  static const earth = Color(0xFF9C3D26);
  static const earthDeep = Color(0xFF7A2E1C);
  static const rice = Color(0xFFF6F0E4);
  static const turmeric = Color(0xFFE2A12B);
  static const leaf = Color(0xFF2F6B3F);
  static const soot = Color(0xFF231A16);
}

/// The logo: a twelve-petal alpona rosette, one petal for each hour on a
/// clock face, the top one lit in turmeric for the hour being spoken.
///
/// Below about 64 pixels the twelve petals blur together, so small sizes
/// draw [RosettePainter.small]: eight petals and no dots.
class RosettePainter extends CustomPainter {
  const RosettePainter({
    this.line = Alpona.rice,
    this.accent = Alpona.turmeric,
    this.weight = 1,
    this.petals = 12,
    this.dots = true,
  });

  const RosettePainter.small({
    this.line = Alpona.rice,
    this.accent = Alpona.turmeric,
  }) : weight = 1.7,
       petals = 8,
       dots = false;

  /// The menu-bar version: one colour, small-size drawing, no accent. At
  /// 1x (18 pixels) eight petals read as a cog, so [tiny] draws six.
  const RosettePainter.template({this.line = Colors.black, bool tiny = false})
    : accent = null,
      weight = tiny ? 2.1 : 1.5,
      petals = tiny ? 6 : 8,
      dots = false;

  final Color line;

  /// Fill for the top petal, or null for a single-colour mark.
  final Color? accent;

  /// Line weight relative to the logo's.
  final double weight;
  final int petals;
  final bool dots;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide / 2;
    final c = size.center(Offset.zero);
    final stroke = Paint()
      ..color = line
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.055 * weight
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = line;

    final step = 2 * math.pi / petals;
    for (var i = 0; i < petals; i++) {
      final angle = -math.pi / 2 + i * step;
      final petal = _petal(c, r, angle, spread: 2.4 / petals);
      if (i == 0 && accent != null) {
        canvas.drawPath(petal, Paint()..color = accent!);
      }
      canvas.drawPath(petal, stroke);
      // Fingertip dots between the petal tips.
      if (dots) {
        canvas.drawCircle(
          _at(c, r * 0.86, angle + step / 2),
          r * 0.045 * weight,
          fill,
        );
      }
    }
    canvas.drawCircle(c, r * 0.25, stroke);
    canvas.drawCircle(c, r * 0.1 * math.sqrt(weight), fill);
  }

  /// A teardrop petal from the inner ring to its tip, pointing at [angle].
  static Path _petal(
    Offset c,
    double r,
    double angle, {
    required double spread,
  }) {
    final base = _at(c, r * 0.32, angle);
    final tip = _at(c, r * 0.93, angle);
    return Path()
      ..moveTo(base.dx, base.dy)
      ..cubicTo(
        _at(c, r * 0.55, angle - spread * 1.6).dx,
        _at(c, r * 0.55, angle - spread * 1.6).dy,
        _at(c, r * 0.86, angle - spread * 0.5).dx,
        _at(c, r * 0.86, angle - spread * 0.5).dy,
        tip.dx,
        tip.dy,
      )
      ..cubicTo(
        _at(c, r * 0.86, angle + spread * 0.5).dx,
        _at(c, r * 0.86, angle + spread * 0.5).dy,
        _at(c, r * 0.55, angle + spread * 1.6).dx,
        _at(c, r * 0.55, angle + spread * 1.6).dy,
        base.dx,
        base.dy,
      )
      ..close();
  }

  @override
  bool shouldRepaint(RosettePainter old) =>
      old.line != line ||
      old.accent != accent ||
      old.weight != weight ||
      old.petals != petals ||
      old.dots != dots;
}

/// Draws today as an alpona ring, noon at the top and midnight at the
/// bottom: the six parts of the day as arcs, a dot for every scheduled
/// announcement (none in quiet hours, hollow when muted) and a turmeric
/// dot at [now].
class DayDialPainter extends CustomPainter {
  DayDialPainter({
    required this.now,
    required this.schedule,
    required this.muted,
    this.speaking = false,
    required this.zoneLabels,
    required this.labelStyle,
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

  /// The angle of [minuteOfDay] on the dial.
  static double angleOf(num minuteOfDay) =>
      math.pi / 2 + minuteOfDay / (24 * 60) * 2 * math.pi;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide / 2;
    final c = size.center(Offset.zero);
    final line = Paint()
      ..color = Alpona.rice
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
          ..color = Alpona.rice.withValues(alpha: 0.75),
      );
      _label(canvas, c, r * 0.84, angleOf((start + end) / 2), zoneLabels(zone));
    }

    // A fingertip dot for every announcement of the day, sized to its
    // spacing so neighbours never merge and each one can be counted.
    final perDay = 24 * 60 ~/ schedule.intervalMinutes;
    final pitch = 2 * math.pi * r * 0.76 / perDay;
    final dot = math.min(r * 0.022, pitch * 0.22);
    for (var m = 0; m < 24 * 60; m++) {
      final t = DateTime(now.year, now.month, now.day, m ~/ 60, m % 60);
      if (!schedule.announcesAt(t)) continue;
      final p = _at(c, r * 0.76, angleOf(m));
      final size = m % 60 == 0 ? math.min(dot * 1.45, pitch * 0.34) : dot;
      if (muted) {
        canvas.drawCircle(
          p,
          size,
          Paint()
            ..color = Alpona.rice.withValues(alpha: 0.7)
            ..style = PaintingStyle.stroke
            ..strokeWidth = dot * 0.5,
        );
      } else {
        canvas.drawCircle(p, size, Paint()..color = Alpona.rice);
      }
    }

    // Now, haloed in turmeric while the clock speaks.
    final nowAt = _at(c, r * 0.76, angleOf(now.hour * 60 + now.minute));
    if (speaking) {
      canvas.drawCircle(
        nowAt,
        r * 0.13,
        Paint()
          ..color = Alpona.turmeric.withValues(alpha: 0.35)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.04),
      );
    }
    canvas
      ..drawCircle(nowAt, r * 0.065, Paint()..color = Alpona.earth)
      ..drawCircle(nowAt, r * 0.05, Paint()..color = Alpona.turmeric);
  }

  /// Each part of the day as (start minute, end minute, zone), in order
  /// round the dial from midnight. A part that spans midnight (রাত) is one
  /// span running past 24:00.
  List<(int, int, DayZone)> _zoneSpans() {
    final spans = <(int, int, DayZone)>[];
    var start = 0;
    for (var h = 1; h <= 24; h++) {
      if (h == 24 || zones.forHour(h) != zones.forHour(start ~/ 60)) {
        spans.add((start, h * 60, zones.forHour(start ~/ 60)));
        start = h * 60;
      }
    }
    if (spans.length > 1 && spans.first.$3 == spans.last.$3) {
      final first = spans.removeAt(0);
      final last = spans.removeLast();
      spans.add((last.$1, first.$2 + 24 * 60, last.$3));
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
      old.schedule.quietHours?.startHour != schedule.quietHours?.startHour ||
      old.schedule.quietHours?.endHour != schedule.quietHours?.endHour ||
      old.labelStyle != labelStyle;
}

Offset _at(Offset c, double radius, double angle) =>
    c + Offset(math.cos(angle), math.sin(angle)) * radius;
