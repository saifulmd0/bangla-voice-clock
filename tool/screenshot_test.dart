// Renders the settings window to PNGs for design review, with the real
// fonts, in light and dark and in both interface languages.
//
//   flutter test tool/screenshot_test.dart
//
// Writes .impeccable/review/*.png (git ignores that folder).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:bangla_voice_clock/app/app_controller.dart';
import 'package:bangla_voice_clock/app/platform.dart';
import 'package:bangla_voice_clock/core/settings/app_settings.dart';
import 'package:bangla_voice_clock/core/settings/settings_store.dart';
import 'package:bangla_voice_clock/core/speech/bangla_phrase_builder.dart';
import 'package:bangla_voice_clock/main.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _QuietPlatform implements AppPlatform {
  @override
  Stream<String> get menuSelections => const Stream.empty();
  @override
  Stream<void> get clockDisturbed => const Stream.empty();
  @override
  Future<void> play(Uint8List wav, {double volume = 1}) async {}
  @override
  Future<void> setStatusTitle(String title) async {}
  @override
  Future<void> setMenu(List<MenuEntry> entries) async {}
  @override
  Future<void> showWindow() async {}
  @override
  Future<void> notify(String title, String body) async {}
  @override
  Future<void> openUrl(String url) async {}
  @override
  Future<void> setAppearance(Appearance appearance) async {}
  @override
  Future<bool?> launchAtLogin() async => false;
  @override
  Future<bool> setLaunchAtLogin(bool enabled) async => true;
  @override
  Future<void> quit() async {}
}

Future<void> _loadFont(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final f in files) {
    loader.addFont(File(f).readAsBytes().then((b) => ByteData.view(b.buffer)));
  }
  await loader.load();
}

void main() {
  testWidgets('screenshots', (tester) async {
    await tester.runAsync(() async {
      await _loadFont('HindSiliguri', [
        for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold'])
          'assets/fonts/hind_siliguri/HindSiliguri-$w.ttf',
      ]);
      await _loadFont('MaterialIcons', [
        '${Platform.environment['FLUTTER_ROOT']}/bin/cache/artifacts/'
            'material_fonts/MaterialIcons-Regular.otf',
      ]);
    });
    // Render macOS controls (adaptive switches, sliders), as the app shows.
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    tester.view
      ..physicalSize = const Size(960, 3300)
      ..devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final dir = Directory.systemTemp.createTempSync('shots');

    for (final (name, settings, brightness) in [
      (
        'bn-light',
        const AppSettings(quietHoursEnabled: true),
        Brightness.light,
      ),
      (
        'en-dark',
        const AppSettings(
          language: AppLanguage.en,
          quietHoursEnabled: true,
          appearance: Appearance.dark,
          style: AnnouncementStyle.exact,
        ),
        Brightness.dark,
      ),
      (
        'bn-muted',
        const AppSettings(muted: true, intervalMinutes: 60),
        Brightness.light,
      ),
      (
        'bn-classic',
        const AppSettings(voiceId: 'bn_classic'),
        Brightness.light,
      ),
    ]) {
      final store = SettingsStore(File('${dir.path}/$name.json'));
      await tester.runAsync(
        () => store.save(settings.copyWith(welcomed: true)),
      );
      final c = (await tester.runAsync(
        () => AppController.create(
          platform: _QuietPlatform(),
          store: store,
          now: () => DateTime(2026, 10, 18, 10, 20),
        ),
      ))!;
      tester.platformDispatcher.platformBrightnessTestValue = brightness;
      // A fresh app for each capture, so no page carries over.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        RepaintBoundary(
          key: const ValueKey('shot'),
          child: BanglaVoiceClockApp(controller: c),
        ),
      );
      await tester.pumpAndSettle();
      if (name == 'en-dark') {
        // Show the halo the now dot wears while the clock speaks.
        await tester.runAsync(c.speakNow);
        await tester.pump();
      }
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('shot')),
      );
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        await Directory('.impeccable/review').create(recursive: true);
        await File('.impeccable/review/$name.png')
            .writeAsBytes(png!.buffer.asUint8List());
      });
      if (name == 'bn-light') {
        await tester.tap(find.text('কৃতজ্ঞতা'));
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 2);
          final png = await image.toByteData(format: ui.ImageByteFormat.png);
          await File('.impeccable/review/bn-credits.png')
              .writeAsBytes(png!.buffer.asUint8List());
        });
      }
    }
    tester.platformDispatcher.clearPlatformBrightnessTestValue();
    debugDefaultTargetPlatformOverride = null;
  });
}
