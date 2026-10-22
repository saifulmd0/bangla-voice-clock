// Renders the README's product media from the real app: scenes of the
// settings window framed with a caption, the sounds the app plays in them,
// the GitHub social preview, and plain window screenshots for software
// centres (docs/media/window-*.png, listed in the Linux metainfo).
//
//   flutter test tool/showcase_test.dart && tool/make_demo.sh
//
// Writes the scenes and their sounds to build/showcase/ for
// tool/make_demo.sh, which makes the demo video, GIF and screenshots, and
// the social preview to docs/media/.
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:bangla_voice_clock/app/app_controller.dart';
import 'package:bangla_voice_clock/app/host_os.dart';
import 'package:bangla_voice_clock/app/platform.dart';
import 'package:bangla_voice_clock/core/audio/wav.dart';
import 'package:bangla_voice_clock/core/settings/app_settings.dart';
import 'package:bangla_voice_clock/core/settings/settings_store.dart';
import 'package:bangla_voice_clock/core/speech/timer_phrases.dart';
import 'package:bangla_voice_clock/main.dart';
import 'package:bangla_voice_clock/ui/brand.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Keeps the last sound the app played, instead of playing it.
class _RecordingPlatform implements AppPlatform {
  Uint8List? lastSound;

  @override
  Stream<String> get menuSelections => const Stream.empty();
  @override
  Stream<void> get clockDisturbed => const Stream.empty();
  @override
  Stream<void> get closedWithoutIcon => const Stream.empty();
  @override
  Future<bool> hasStatusIcon() async => true;
  @override
  Future<void> play(
    Uint8List wav, {
    double volume = 1,
    String device = '',
  }) async => lastSound = wav;
  @override
  Future<List<AudioDevice>> outputDevices() async => const [];
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
  Future<bool?> launchAtLogin() async => true;
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

const _width = 1280.0;
const _height = 800.0;

/// A macOS window around the app, as it sits on the desktop, or a GNOME
/// one for the Linux store screenshots.
class _Window extends StatelessWidget {
  const _Window({required this.dark, required this.child, this.gnome = false});

  final bool dark;
  final bool gnome;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      RepaintBoundary(key: const ValueKey('window'), child: _frame());

  Widget _frame() => Container(
    width: 480,
    height: 680,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: dark ? Sky.groundNight : Sky.ground,
      borderRadius: BorderRadius.circular(gnome ? 8 : 12),
      border: Border.all(
        color: dark ? const Color(0xFF34435C) : const Color(0x1F172338),
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x2E0B1A33),
          blurRadius: 48,
          offset: Offset(0, 20),
        ),
        BoxShadow(color: Color(0x140B1A33), blurRadius: 4),
      ],
    ),
    child: Column(
      children: [
        if (gnome)
          _gnomeBar()
        else
          Container(
            height: 30,
            color: dark ? const Color(0xFF1A2537) : const Color(0xFFEDF2F9),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                for (final c in const [
                  Color(0xFFFF5F57),
                  Color(0xFFFEBC2E),
                  Color(0xFF28C840),
                ]) ...[
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    'বাংলা ভয়েস ক্লক',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'HindSiliguri',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: dark ? Sky.inkNight : Sky.ink,
                    ),
                  ),
                ),
                const SizedBox(width: 60),
              ],
            ),
          ),
        Expanded(child: child),
      ],
    ),
  );

  /// Adwaita's header bar: the title centred, a round close button.
  Widget _gnomeBar() {
    final ink = dark ? const Color(0xFFFFFFFF) : const Color(0xFF2E3436);
    return Container(
      height: 46,
      color: dark ? const Color(0xFF303030) : const Color(0xFFEBEBEB),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          const SizedBox(width: 24),
          Expanded(
            child: Text(
              'বাংলা ভয়েস ক্লক',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'HindSiliguri',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: ink,
              ),
            ),
          ),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dark ? const Color(0x1FFFFFFF) : const Color(0x14000000),
            ),
            child: Icon(Icons.close, size: 14, color: ink),
          ),
        ],
      ),
    );
  }
}

/// The logo on its tile, as the app icon shows it.
Widget _logo(double size) => SizedBox.square(
  dimension: size,
  child: DecoratedBox(
    decoration: BoxDecoration(
      color: Sky.tile,
      borderRadius: BorderRadius.circular(size * 0.23),
      boxShadow: const [BoxShadow(color: Color(0x1A0B1A33), blurRadius: 8)],
    ),
    child: Padding(
      padding: EdgeInsets.all(size * 0.15),
      child: const CustomPaint(painter: DotDialPainter()),
    ),
  ),
);

TextStyle _text(double size, FontWeight weight, Color color) => TextStyle(
  fontFamily: 'HindSiliguri',
  fontSize: size,
  fontWeight: weight,
  color: color,
  height: 1.3,
);

/// The sky behind every scene.
BoxDecoration _sky(bool dark) => BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: dark
        ? const [Color(0xFF1C3354), Color(0xFF0F1724)]
        : const [Color(0xFFDCEBFC), Color(0xFFF7FAFF)],
  ),
);

/// A scene: the caption on the left, the window on the right.
Widget _scene({
  required bool dark,
  required String headline,
  required String line,
  required Widget window,
}) => Container(
  width: _width,
  height: _height,
  decoration: _sky(dark),
  padding: const EdgeInsets.symmetric(horizontal: 96),
  child: Row(
    children: [
      Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _logo(40),
                const SizedBox(width: 12),
                Text(
                  'Bangla Voice Clock',
                  style: _text(
                    20,
                    FontWeight.w600,
                    dark ? Sky.inkNight : Sky.ink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            Text(
              headline,
              style: _text(50, FontWeight.w700, dark ? Sky.inkNight : Sky.ink),
            ),
            const SizedBox(height: 16),
            Text(
              line,
              style: _text(
                24,
                FontWeight.w500,
                dark ? const Color(0xFFA9B7CC) : const Color(0xFF4A5A73),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(width: 64),
      window,
    ],
  ),
);

/// The closing card: the name, what it costs, and where to get it.
Widget _endCard() => Container(
  width: _width,
  height: _height,
  decoration: _sky(false),
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      _logo(160),
      const SizedBox(height: 32),
      Text('Bangla Voice Clock', style: _text(56, FontWeight.w700, Sky.ink)),
      Text(
        'বাংলা ভয়েস ক্লক',
        style: _text(34, FontWeight.w600, const Color(0xFF2B5A9E)),
      ),
      const SizedBox(height: 24),
      Text(
        'Free for macOS, Windows and Linux',
        style: _text(26, FontWeight.w500, const Color(0xFF4A5A73)),
      ),
      const SizedBox(height: 6),
      Text(
        'github.com/saifulmd0/bangla-voice-clock',
        style: _text(22, FontWeight.w600, Sky.blue),
      ),
    ],
  ),
);

/// GitHub's link preview, 1280×640: name and promise beside the window.
Widget _socialPreview(Widget window) => Container(
  width: 1280,
  height: 640,
  decoration: _sky(false),
  padding: const EdgeInsets.symmetric(horizontal: 88),
  child: Row(
    children: [
      Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _logo(96),
            const SizedBox(height: 28),
            Text(
              'Bangla Voice Clock',
              style: _text(58, FontWeight.w700, Sky.ink),
            ),
            Text(
              'বাংলা ভয়েস ক্লক',
              style: _text(34, FontWeight.w600, const Color(0xFF2B5A9E)),
            ),
            const SizedBox(height: 18),
            Text(
              'A free talking clock that tells the time aloud in Bangla.\n'
              'macOS, Windows and Linux.',
              style: _text(24, FontWeight.w500, const Color(0xFF4A5A73)),
            ),
          ],
        ),
      ),
      const SizedBox(width: 48),
      // Only the top of the window fits the preview's height.
      SizedBox(
        width: 480,
        height: 640,
        child: OverflowBox(
          alignment: Alignment.topCenter,
          maxHeight: 680,
          child: Padding(
            padding: const EdgeInsets.only(top: 72),
            child: window,
          ),
        ),
      ),
    ],
  ),
);

void main() {
  testWidgets('product media', (tester) async {
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
    // The app's own macOS controls, and real shadows rather than the test
    // renderer's outlines.
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    debugDisableShadows = false;
    tester.view
      ..physicalSize = const Size(_width * 2, _height * 2)
      ..devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final dir = Directory.systemTemp.createTempSync('showcase');
    final media = Directory('docs/media')..createSync(recursive: true);
    final sounds = Directory('build/showcase')..createSync(recursive: true);

    Future<void> capture(String key, String path) => tester.runAsync(() async {
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(ValueKey(key)),
      );
      final image = await boundary.toImage(pixelRatio: 2);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      await File(path).writeAsBytes(png!.buffer.asUint8List());
    });
    Future<void> save(String name) =>
        capture('canvas', '${sounds.path}/$name.png');

    Future<(AppController, _RecordingPlatform)> app(AppSettings s) async {
      final store = SettingsStore(File('${dir.path}/${s.hashCode}.json'));
      await tester.runAsync(() => store.save(s.copyWith(welcomed: true)));
      final platform = _RecordingPlatform();
      final c = (await tester.runAsync(
        () => AppController.create(
          platform: platform,
          store: store,
          now: () => DateTime(2026, 10, 21, 10, 20),
        ),
      ))!;
      return (c, platform);
    }

    Future<void> show(Widget canvas) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: RepaintBoundary(
              key: const ValueKey('canvas'),
              child: canvas,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> scene(
      String name, {
      AppSettings settings = const AppSettings(),
      required String headline,
      required String line,
      String? windowShot,
      Future<void> Function(AppController, _RecordingPlatform)? then,
    }) async {
      // Once as on a Mac for the README, then as the Linux app looks in a
      // GNOME window for the software centre's screenshot.
      for (final linux in [false, if (windowShot != null) true]) {
        hostOs = linux ? HostOs.linux : HostOs.macos;
        final (c, platform) = await app(settings);
        final dark = settings.appearance == Appearance.dark;
        tester.platformDispatcher.platformBrightnessTestValue = dark
            ? Brightness.dark
            : Brightness.light;
        await show(
          _scene(
            dark: dark,
            headline: headline,
            line: line,
            window: _Window(
              dark: dark,
              gnome: linux,
              child: BanglaVoiceClockApp(controller: c),
            ),
          ),
        );
        await then?.call(c, platform);
        if (linux) {
          await capture('window', '${media.path}/window-$windowShot.png');
        } else {
          await save(name);
        }
        c.dispose();
      }
      hostOs = HostOs.macos;
    }

    Future<void> scrollTo(String text) async {
      await tester.ensureVisible(find.text(text));
      await tester.pumpAndSettle();
    }

    await scene(
      'scene-1-clock',
      windowShot: 'clock',
      headline: 'সময় বলে দেয়,\nবাংলায়',
      line: 'A menu bar clock that tells\nthe time aloud, in Bangla.',
    );
    await scene(
      'scene-2-speak',
      headline: 'এখন সময় সকাল\nদশটা বেজে বিশ মিনিট',
      line: 'Every 15, 30 or 60 minutes,\nthe way it is said in Bangladesh.',
      then: (c, platform) async {
        await tester.runAsync(c.speakNow);
        await tester.pump();
        await tester.runAsync(
          () =>
              File('${sounds.path}/speak.wav')
                  .writeAsBytes(platform.lastSound!),
        );
      },
    );
    await scene(
      'scene-3-voices',
      windowShot: 'voices',
      settings: const AppSettings(voiceId: 'bn_classic'),
      headline: 'দুটি কণ্ঠ',
      line:
          'Areeba AI, with a Bangladeshi accent,\n'
          'and the original voice from 1998.',
      then: (c, platform) async {
        await scrollTo('কণ্ঠ');
        await tester.runAsync(c.speakNow);
        await tester.runAsync(
          () =>
              File('${sounds.path}/classic.wav')
                  .writeAsBytes(platform.lastSound!),
        );
      },
    );
    await scene(
      'scene-4-dark',
      windowShot: 'dark',
      settings: const AppSettings(
        language: AppLanguage.en,
        appearance: Appearance.dark,
      ),
      headline: 'বাংলা বা English,\nআলো বা অন্ধকার',
      line: 'A Bangla or English window,\nin light or dark.',
    );
    await scene(
      'scene-5-quiet',
      settings: const AppSettings(quietHoursEnabled: true),
      headline: 'নীরব সময়,\nমিনিট ধরে',
      line: 'Quiet hours to the minute,\nso nights stay silent.',
      then: (c, _) async {
        await scrollTo('নীরব সময়');
        await tester.tap(find.text('রাত ১১:০০'));
        await tester.pumpAndSettle();
      },
    );
    await scene(
      'scene-6-timer',
      windowShot: 'timer',
      headline: 'কথা বলা টাইমার',
      line: 'A timer that says the time left\nevery minute, then "সময় শেষ".',
      then: (c, _) async {
        await tester.tap(find.text('টাইমার'));
        await tester.pumpAndSettle();
        await tester.runAsync(() => c.startTimer(10));
        await tester.pump();
        final speech = await tester.runAsync(
          () => c.voice.render(timeLeftTokens(9)),
        );
        await tester.runAsync(
          () =>
              File('${sounds.path}/timer.wav').writeAsBytes(encodeWav(speech!)),
        );
        await c.stopTimer();
      },
    );

    await show(_endCard());
    await save('scene-7-end');

    final (c, _) = await app(const AppSettings());
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    await show(
      _socialPreview(
        _Window(dark: false, child: BanglaVoiceClockApp(controller: c)),
      ),
    );
    await tester.runAsync(() async {
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('canvas')),
      );
      final image = await boundary.toImage(pixelRatio: 1);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('${media.path}/social-preview.png')
          .writeAsBytes(png!.buffer.asUint8List());
    });
    c.dispose();

    await tester.pumpWidget(const SizedBox());
    tester.platformDispatcher.clearPlatformBrightnessTestValue();
    debugDisableShadows = true;
    debugDefaultTargetPlatformOverride = null;
  });
}
