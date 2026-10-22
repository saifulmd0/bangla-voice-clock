// Renders the settings window to PNGs for design review, with the real
// fonts, in light and dark and in both interface languages.
//
//   flutter test tool/screenshot_test.dart
//
// Writes .impeccable/review/*.png (git ignores that folder).
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:bangla_voice_clock/app/app_controller.dart';
import 'package:bangla_voice_clock/app/host_os.dart';
import 'package:bangla_voice_clock/app/platform.dart';
import 'package:bangla_voice_clock/core/settings/app_settings.dart';
import 'package:bangla_voice_clock/core/settings/settings_store.dart';
import 'package:bangla_voice_clock/core/update/release.dart';
import 'package:bangla_voice_clock/main.dart';
import 'package:bangla_voice_clock/ui/settings_page.dart';
import 'package:bangla_voice_clock/ui/update_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _QuietPlatform implements AppPlatform {
  _QuietPlatform({this.help = PanelHelp.none});

  final PanelHelp help;

  @override
  Stream<String> get menuSelections => const Stream.empty();
  @override
  Stream<void> get clockDisturbed => const Stream.empty();
  @override
  Stream<void> get closedWithoutIcon => const Stream.empty();
  @override
  Future<bool> hasStatusIcon() async => help == PanelHelp.none;
  @override
  Stream<bool> get statusIconChanges => const Stream.empty();
  @override
  Future<PanelHelp> panelHelp() async => help;
  @override
  Future<PanelHelp> turnOnPanelIcon() async => PanelHelp.none;
  @override
  Future<void> play(
    Uint8List wav, {
    double volume = 1,
    String device = '',
  }) async {}
  @override
  Future<List<AudioDevice>> outputDevices() async => const [
    AudioDevice('speakers', 'Mac mini Speakers'),
    AudioDevice('buds', 'CMF Buds Pro 2'),
  ];
  @override
  Future<void> setStatus({required String title, required bool icon}) async {}
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

const _panes = {
  AppLanguage.bn: ['ঘোষণা', 'কণ্ঠ ও শব্দ', 'নীরব সময়', 'টাইমার', 'সাধারণ'],
  AppLanguage.en: [
    'Announcements',
    'Voice & sound',
    'Quiet hours',
    'Timer',
    'General',
  ],
};

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
    addTearDown(tester.view.reset);
    final dir = Directory.systemTemp.createTempSync('shots');
    Directory('.impeccable/review').createSync(recursive: true);

    // The running clock keeps asking for frames, so settle by time.
    Future<void> settle() async {
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
    }

    Future<void> capture(String file) async {
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('shot')),
      );
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('.impeccable/review/$file.png')
            .writeAsBytes(png!.buffer.asUint8List());
      });
    }

    Future<void> open(String pane) async {
      await tester.tap(find.widgetWithText(InkWell, pane).first);
      await settle();
    }

    for (final (name, settings, brightness, size, host, help) in [
      (
        'bn-light',
        const AppSettings(quietHoursEnabled: true, quietStart: 23 * 60 + 30),
        Brightness.light,
        const Size(760, 620),
        HostOs.macos,
        PanelHelp.none,
      ),
      (
        'en-dark',
        const AppSettings(
          language: AppLanguage.en,
          quietHoursEnabled: true,
          quietEnd: 6 * 60 + 45,
          appearance: Appearance.dark,
          outputDeviceId: 'buds',
          outputDeviceName: 'CMF Buds Pro 2',
        ),
        Brightness.dark,
        const Size(760, 620),
        HostOs.macos,
        PanelHelp.none,
      ),
      (
        'bn-classic',
        const AppSettings(voiceId: 'bn_classic'),
        Brightness.light,
        const Size(760, 620),
        HostOs.windows,
        PanelHelp.none,
      ),
      (
        'bn-gnome',
        const AppSettings(),
        Brightness.light,
        const Size(760, 620),
        HostOs.linux,
        PanelHelp.enable,
      ),
      (
        'bn-narrow',
        const AppSettings(muted: true, intervalMinutes: 60),
        Brightness.light,
        const Size(460, 700),
        HostOs.macos,
        PanelHelp.none,
      ),
    ]) {
      hostOs = host;
      tester.view
        ..physicalSize = size * 2
        ..devicePixelRatio = 2;
      final store = SettingsStore(File('${dir.path}/$name.json'));
      await tester.runAsync(
        () => store.save(settings.copyWith(welcomed: true)),
      );
      final c = (await tester.runAsync(
        () => AppController.create(
          platform: _QuietPlatform(help: help),
          store: store,
          now: () => DateTime(2026, 10, 18, 10, 20),
        ),
      ))!;
      await tester.runAsync(c.refreshStatusIcon);
      tester.platformDispatcher.platformBrightnessTestValue = brightness;
      // A fresh app for each capture, so no page carries over.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        RepaintBoundary(
          key: const ValueKey('shot'),
          child: BanglaVoiceClockApp(controller: c),
        ),
      );
      await settle();
      for (final (i, pane) in _panes[settings.language]!.indexed) {
        await open(pane);
        await capture('$name-${i + 1}');
      }
      // The quiet-hours time picker, open.
      if (name == 'bn-light' || name == 'en-dark') {
        await open(_panes[settings.language]![2]);
        await tester.tap(
          find.text(name == 'bn-light' ? 'রাত ১১:৩০' : '6:45 AM'),
        );
        await settle();
        await capture('$name-quiet-open');
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await settle();
      }
      if (name == 'bn-light') {
        unawaited(
          showUpdateDialog(
            tester.element(find.byType(SettingsPage)),
            c,
            Release(
              version: Version.tryParse('0.5.0')!,
              page: Uri.parse('https://example.com'),
              notes:
                  '## New\n\n- **Homebrew** on macOS.\n- Quiet hours to '
                  'the minute.\n\n## Fixed\n\n- বেজে at noon.',
              assets: const [],
            ),
          ),
        );
        await settle();
        await capture('bn-update');
        await tester.tap(find.text('পরে'));
        await settle();
        await tester.tap(find.text('কৃতজ্ঞতা'));
        await settle();
        await capture('bn-credits');
      }
      c.dispose();
    }
    hostOs = HostOs.macos;
    tester.platformDispatcher.clearPlatformBrightnessTestValue();
    debugDefaultTargetPlatformOverride = null;
  });
}
