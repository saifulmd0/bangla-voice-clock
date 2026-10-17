// Renders the app icon and the menu-bar logo from RosettePainter, so the
// icons always match the logo drawn in the app.
//
//   flutter test tool/generate_icons_test.dart
//
// Writes macos/Runner/Assets.xcassets/{AppIcon.appiconset,StatusIcon.imageset}
// and docs/brand/icon.png. Afterwards, re-embed each PNG's provenance with
// `impeccable embed-prompt <png> --prompt "Origin: ..."` (see docs/BRAND.md).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:bangla_voice_clock/ui/alpona.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _assets = 'macos/Runner/Assets.xcassets';

Future<void> _write(
  String path,
  int size,
  void Function(Canvas, Size) draw,
) async {
  final recorder = ui.PictureRecorder();
  draw(Canvas(recorder), Size.square(size.toDouble()));
  final image = await recorder.endRecording().toImage(size, size);
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  await File(path).parent.create(recursive: true);
  await File(path).writeAsBytes(png!.buffer.asUint8List());
}

/// The macOS icon: the rosette on a fired-earth tile, at Apple's icon grid
/// (an 824/1024 rounded square with a soft drop shadow).
void _appIcon(Canvas canvas, Size size) {
  final s = size.width;
  final tile = RRect.fromRectAndRadius(
    Rect.fromCenter(
      center: Offset(s / 2, s / 2),
      width: s * 0.8047,
      height: s * 0.8047,
    ),
    Radius.circular(s * 0.1807),
  );
  canvas.drawRRect(
    tile.shift(Offset(0, s * 0.01)),
    Paint()
      ..color = Colors.black.withValues(alpha: 0.28)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.012),
  );
  canvas.drawRRect(tile, Paint()..color = Alpona.earth);
  final mark = s * (s <= 64 ? 0.66 : 0.62);
  canvas.translate((s - mark) / 2, (s - mark) / 2);
  (s <= 64 ? const RosettePainter.small() : const RosettePainter()).paint(
    canvas,
    Size.square(mark),
  );
}

void _statusIcon(Canvas canvas, Size size) {
  final pad = size.width * 0.04;
  canvas.translate(pad, pad);
  RosettePainter.template(tiny: size.width < 24)
      .paint(canvas, Size.square(size.width - 2 * pad));
}

void main() {
  testWidgets('generate icons', (tester) async {
    await tester.runAsync(() async {
      for (final size in [16, 32, 64, 128, 256, 512, 1024]) {
        await _write(
          '$_assets/AppIcon.appiconset/app_icon_$size.png',
          size,
          _appIcon,
        );
      }
      await _write('docs/brand/icon.png', 512, _appIcon);
      await _write(
        '$_assets/StatusIcon.imageset/status_icon.png',
        18,
        _statusIcon,
      );
      await _write(
        '$_assets/StatusIcon.imageset/status_icon@2x.png',
        36,
        _statusIcon,
      );
      await File('$_assets/StatusIcon.imageset/Contents.json').writeAsString('''
{
  "images" : [
    { "filename" : "status_icon.png", "idiom" : "universal", "scale" : "1x" },
    { "filename" : "status_icon@2x.png", "idiom" : "universal", "scale" : "2x" }
  ],
  "info" : { "author" : "xcode", "version" : 1 },
  "properties" : { "template-rendering-intent" : "template" }
}
''');
    });
  });
}
