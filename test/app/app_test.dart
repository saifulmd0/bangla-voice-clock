import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:bangla_voice_clock/app/app_controller.dart';
import 'package:bangla_voice_clock/app/platform.dart';
import 'package:bangla_voice_clock/core/audio/wav.dart';
import 'package:bangla_voice_clock/core/settings/app_settings.dart';
import 'package:bangla_voice_clock/core/settings/settings_store.dart';
import 'package:bangla_voice_clock/core/speech/bangla_phrase_builder.dart';
import 'package:bangla_voice_clock/core/speech/speech_token.dart';
import 'package:bangla_voice_clock/main.dart';
import 'package:bangla_voice_clock/ui/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakePlatform implements AppPlatform {
  final menu = StreamController<String>.broadcast();
  final played = <Uint8List>[];
  final notifications = <String>[];
  final opened = <String>[];
  String title = '';
  List<MenuEntry> entries = [];
  var windowShown = 0;

  @override
  Stream<String> get menuSelections => menu.stream;
  @override
  Stream<void> get clockDisturbed => const Stream.empty();
  @override
  Future<void> play(Uint8List wav, {double volume = 1}) async =>
      played.add(wav);
  @override
  Future<void> setStatusTitle(String title) async => this.title = title;
  @override
  Future<void> setMenu(List<MenuEntry> entries) async => this.entries = entries;
  @override
  Future<void> showWindow() async => windowShown++;
  @override
  Future<void> notify(String title, String body) async =>
      notifications.add('$title|$body');
  @override
  Future<void> openUrl(String url) async => opened.add(url);
  @override
  Future<bool?> launchAtLogin() async => false;
  @override
  Future<bool> setLaunchAtLogin(bool enabled) async => true;
  @override
  Future<void> quit() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dir;
  late FakePlatform platform;
  final at1015 = DateTime(2026, 1, 1, 10, 15, 0, 100);

  Future<AppController> controller({DateTime? now}) => AppController.create(
    platform: platform,
    store: SettingsStore(File('${dir.path}/settings.json')),
    now: () => now ?? at1015,
  );

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('app_test');
    platform = FakePlatform();
  });
  tearDown(() => dir.delete(recursive: true));

  test('loads both bundled voices', () async {
    final c = await controller();
    expect(c.voices.keys, ['bn_ai', 'bn_classic']);
    expect(c.voice.id, 'bn_ai');
  });

  test('first start shows the window, the clock and the menu', () async {
    final c = await controller();
    await c.start();
    expect(platform.windowShown, 1);
    expect(platform.title, '১০:১৫');
    expect(platform.entries.first.title, 'সকাল ১০:১৫');
    expect(c.settings.welcomed, isTrue);

    final again = await controller();
    await again.start();
    expect(platform.windowShown, 1, reason: 'only on first launch');
    c.dispose();
    again.dispose();
  });

  test('Speak now plays the chime and the announcement', () async {
    final c = await controller();
    await c.speakNow();
    expect(platform.played, hasLength(1));
    final audio = decodeWav(platform.played.single);
    expect(audio.duration.inMilliseconds, greaterThan(2000));
    expect(platform.notifications.single, contains('সোয়া দশটা'));
  });

  test('off the quarter hour, Speak now says the exact minute', () async {
    final c = await controller(now: DateTime(2026, 1, 1, 21, 27));
    expect(
      c.announcementAt(DateTime(2026, 1, 1, 21, 27)).text,
      'এখন সময় রাত নয়টা বেজে সাতাশ মিনিট',
    );
    // The classic voice only says quarter hours, the original's way.
    await c.update(c.settings.copyWith(voiceId: 'bn_classic'));
    final classic = c.announcementAt(DateTime(2026, 1, 1, 21, 27));
    expect(classic.text, 'এখন সময় রাত নয়টা বেজে পনেরো মিনিট');
    expect(c.voice.clipKeysFor(classic), [
      'starter',
      'zone.raat',
      'hour.9',
      'num.15 exact.minute',
    ]);
  });

  test('menu changes are saved', () async {
    final c = await controller();
    await c.start();
    platform.menu.add('interval:60');
    await pumpEventQueue();
    expect(c.settings.intervalMinutes, 60);
    // Saving is real file IO, which pumpEventQueue doesn't wait for.
    final store = SettingsStore(File('${dir.path}/settings.json'));
    for (var i = 0; i < 100; i++) {
      if ((await store.load()).intervalMinutes == 60) break;
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    final reloaded = await controller();
    expect(reloaded.settings.intervalMinutes, 60);
    c.dispose();
  });

  test('English interface and logo in the menu bar', () async {
    final c = await controller();
    await c.start();
    await c.update(
      c.settings.copyWith(
        language: AppLanguage.en,
        menuBarShows: MenuBarShows.logo,
      ),
    );
    expect(platform.title, isEmpty, reason: 'empty title shows the logo');
    expect(platform.entries.first.title, '10:15 AM');
    expect(platform.entries[1].title, 'Speak the time now');
    expect(platform.entries.last.title, 'Quit');
    expect(platform.entries.map((e) => e.id), contains('credits'));
    await c.speakNow();
    // The announcement itself stays in Bangla.
    expect(platform.notifications.single, '10:15 AM|এখন সময় সকাল সোয়া দশটা');
    c.dispose();
  });

  void tallWindow(WidgetTester tester) {
    tester.view
      ..physicalSize = const Size(960, 3600)
      ..devicePixelRatio = 2;
    addTearDown(tester.view.reset);
  }

  testWidgets('voice labels, footer and credits', (tester) async {
    tallWindow(tester);
    final c = await tester.runAsync(controller);
    await tester.pumpWidget(BanglaVoiceClockApp(controller: c!));
    expect(find.text('Areeba AI (ElevenLabs) - by Saiful'), findsOneWidget);
    expect(
      find.text('Classic (1998) - by Moshfekah Ferdaus Mahita'),
      findsOneWidget,
    );
    await tester.tap(find.text('ডেভেলপ করেছেন সাইফুল ইসলাম'));
    expect(platform.opened, ['https://github.com/saifulmd0']);
    await tester.tap(find.text('কৃতজ্ঞতা'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Schedule Voice Clock'),
      100,
      scrollable: find.descendant(
        of: find.byType(CreditsPage),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(find.text('Schedule Voice Clock'));
    expect(platform.opened.last, contains('schedule-voice-clock'));
  });

  testWidgets('the menu bar opens the credits page', (tester) async {
    tallWindow(tester);
    final c = await tester.runAsync(controller);
    await tester.runAsync(c!.start);
    await tester.pumpWidget(BanglaVoiceClockApp(controller: c));
    platform.menu.add('credits');
    await tester.runAsync(() => pumpEventQueue());
    await tester.pumpAndSettle();
    expect(find.byType(CreditsPage), findsOneWidget);
    expect(platform.windowShown, greaterThanOrEqualTo(1));
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(CreditsPage), findsNothing);
    c.dispose();
  });

  testWidgets('settings window', (tester) async {
    tallWindow(tester);
    final c = await tester.runAsync(controller);
    await tester.pumpWidget(BanglaVoiceClockApp(controller: c!));
    expect(find.text('সকাল ১০:১৫'), findsOneWidget);
    expect(find.text('এখনই সময় শুনুন'), findsOneWidget);
    expect(find.text('পরের ঘোষণা সকাল\u00A0১০:৩০'), findsOneWidget);

    await tester.tap(find.text('৩০ মিনিট'));
    await tester.runAsync(() => pumpEventQueue());
    await tester.pump();
    expect(c.settings.intervalMinutes, 30);
    expect(find.text('পরের ঘোষণা সকাল\u00A0১০:৩০'), findsOneWidget);

    await tester.tap(find.text('মিনিট ধরে'));
    await tester.pump();
    expect(c.settings.style, AnnouncementStyle.exact);
    expect(const AppSettings().style, AnnouncementStyle.traditional);
  });
}
