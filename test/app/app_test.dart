import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:bangla_voice_clock/app/app_controller.dart';
import 'package:bangla_voice_clock/app/platform.dart';
import 'package:bangla_voice_clock/app/updater.dart';
import 'package:bangla_voice_clock/app/version.dart';
import 'package:bangla_voice_clock/core/audio/wav.dart';
import 'package:bangla_voice_clock/core/settings/app_settings.dart';
import 'package:bangla_voice_clock/core/settings/settings_store.dart';
import 'package:bangla_voice_clock/core/speech/bangla_phrase_builder.dart';
import 'package:bangla_voice_clock/core/speech/speech_token.dart';
import 'package:bangla_voice_clock/core/speech/timer_phrases.dart';
import 'package:bangla_voice_clock/core/update/release.dart';
import 'package:bangla_voice_clock/main.dart';
import 'package:bangla_voice_clock/ui/settings_page.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakePlatform implements AppPlatform {
  final menu = StreamController<String>.broadcast();
  final played = <Uint8List>[];
  final playedOn = <String>[];
  var outputs = const [AudioDevice('buds', 'CMF Buds Pro 2')];
  var loginEnabled = <bool>[];
  final notifications = <String>[];
  final opened = <String>[];
  String title = '';
  bool icon = false;
  List<MenuEntry> entries = [];
  var windowShown = 0;

  @override
  Stream<String> get menuSelections => menu.stream;
  @override
  Stream<void> get clockDisturbed => const Stream.empty();
  @override
  Future<void> play(
    Uint8List wav, {
    double volume = 1,
    String device = '',
  }) async {
    played.add(wav);
    playedOn.add(device);
  }

  @override
  Future<List<AudioDevice>> outputDevices() async => outputs;
  @override
  Future<void> setStatus({required String title, required bool icon}) async {
    this.title = title;
    this.icon = icon;
  }

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
  Future<void> setAppearance(Appearance appearance) async {}
  @override
  Future<bool?> launchAtLogin() async => false;
  @override
  Future<bool> setLaunchAtLogin(bool enabled) async {
    loginEnabled.add(enabled);
    return true;
  }

  @override
  Future<void> quit() async {}
}

/// Stands in for GitHub, offering whatever [latestVersion] says.
class FakeUpdates implements UpdateSource {
  String latestVersion = '0.3.0';
  var checks = 0;

  @override
  Future<Release?> latest() async {
    checks++;
    return Release(
      version: Version.tryParse(latestVersion)!,
      page: Uri.parse('https://example.com/v$latestVersion'),
      notes: '',
      assets: const [],
    );
  }

  @override
  bool get canInstall => false;

  @override
  Future<void> install(Release release, {void Function(double)? progress}) =>
      throw UnimplementedError();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dir;
  late FakePlatform platform;
  final at1015 = DateTime(2026, 1, 1, 10, 15, 0, 100);

  Future<AppController> controller({
    DateTime? now,
    UpdateSource? updates,
    bool openAtLogin = false,
  }) => AppController.create(
    platform: platform,
    store: SettingsStore(File('${dir.path}/settings.json')),
    now: () => now ?? at1015,
    updates: updates,
    openAtLoginOnFirstRun: openAtLogin,
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

  test('first launch turns on opening at login, when asked', () async {
    final c = await controller(openAtLogin: true);
    await c.start();
    expect(platform.loginEnabled, [true]);
    expect(c.launchAtLogin, isTrue);
    final again = await controller(openAtLogin: true);
    await again.start();
    expect(platform.loginEnabled, [true], reason: 'only on first launch');
    c.dispose();
    again.dispose();
  });

  test('announcements play through the chosen output', () async {
    final c = await controller();
    await c.speakNow();
    expect(platform.playedOn.last, '', reason: 'the system default');
    await c.refreshOutputs();
    expect(c.outputs.single.name, 'CMF Buds Pro 2');
    await c.chooseOutput(c.outputs.single);
    expect(
      (c.settings.outputDeviceId, c.settings.outputDeviceName),
      ('buds', 'CMF Buds Pro 2'),
    );
    await c.speakNow();
    expect(platform.playedOn.last, 'buds');
    await c.chooseOutput(null);
    await c.speakNow();
    expect(platform.playedOn.last, '');
  });

  test('a check finds only versions newer than this one', () async {
    final updates = FakeUpdates()..latestVersion = appVersion;
    final c = await controller(updates: updates);
    expect(await c.checkForUpdate(), isNull);
    updates.latestVersion = '99.0.0';
    expect((await c.checkForUpdate())!.version.toString(), '99.0.0');
  });

  test('the daily check offers a new version, but not a skipped one', () async {
    await SettingsStore(File('${dir.path}/settings.json'))
        .save(const AppSettings(welcomed: true, skippedVersion: '98.0.0'));
    final updates = FakeUpdates()..latestVersion = '98.0.0';
    final c = await controller(updates: updates);
    final offered = <String>[];
    fakeAsync((async) {
      c.updateRequests.listen((r) => offered.add('${r.version}'));
      c.start();
      async.elapse(AppController.firstUpdateCheck);
      expect(updates.checks, 1);
      expect(offered, isEmpty, reason: '98.0.0 was skipped');
      updates.latestVersion = '99.0.0';
      async.elapse(AppController.updateCheckEvery);
      expect(offered, ['99.0.0']);
      expect(platform.windowShown, 1);
      c.dispose();
    });
  });

  test('Speak now plays the chime and the announcement', () async {
    final c = await controller();
    await c.speakNow();
    expect(platform.played, hasLength(1));
    final audio = decodeWav(platform.played.single);
    expect(audio.duration.inMilliseconds, greaterThan(2000));
    expect(platform.notifications.single, contains('দশটা বেজে পনেরো মিনিট'));
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
    expect(platform.title, isEmpty);
    expect(platform.icon, isTrue);
    await c.update(c.settings.copyWith(menuBarShows: MenuBarShows.both));
    expect((platform.title, platform.icon), ('10:15', true));
    await c.update(c.settings.copyWith(menuBarShows: MenuBarShows.time));
    expect((platform.title, platform.icon), ('10:15', false));
    expect(platform.entries.first.title, '10:15 AM');
    expect(platform.entries[1].title, 'Speak the time now');
    expect(platform.entries.last.title, 'Quit');
    expect(platform.entries.map((e) => e.id), contains('credits'));
    await c.speakNow();
    // The announcement itself stays in Bangla.
    expect(
      platform.notifications.single,
      '10:15 AM|এখন সময় সকাল দশটা বেজে পনেরো মিনিট',
    );
    c.dispose();
  });

  void tallWindow(WidgetTester tester) {
    tester.view
      ..physicalSize = const Size(960, 4800)
      ..devicePixelRatio = 2;
    addTearDown(tester.view.reset);
  }

  testWidgets('voice labels, footer and credits', (tester) async {
    tallWindow(tester);
    final c = await tester.runAsync(controller);
    await tester.pumpWidget(BanglaVoiceClockApp(controller: c!));
    expect(
      find.text('Areeba AI (ElevenLabs) - by Saiful Islam'),
      findsOneWidget,
    );
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

  test('without বেজে the AI voice says দশটা সাত মিনিট in two takes', () async {
    final c = await controller();
    await c.update(c.settings.copyWith(sayBeje: false));
    final tokens = c.announcementAt(
      DateTime(2026, 1, 1, 10, 7),
      style: AnnouncementStyle.exact,
    );
    expect(tokens.text, 'এখন সময় সকাল দশটা সাত মিনিট');
    expect(c.voice.clipKeysFor(tokens), hasLength(2));
  });

  testWidgets('the classic voice offers no minute style', (tester) async {
    tallWindow(tester);
    final c = await tester.runAsync(controller);
    await tester.runAsync(
      () => c!.update(
        c.settings.copyWith(
          voiceId: 'bn_classic',
          style: AnnouncementStyle.exact,
        ),
      ),
    );
    await tester.pumpWidget(BanglaVoiceClockApp(controller: c!));
    expect(c.voiceSaysEveryMinute, isFalse);
    expect(find.textContaining('শুধু ১৫ মিনিট পরপর'), findsOneWidget);
    // The examples show what the classic voice really says.
    expect(find.text('সকাল দশটা পনেরো মিনিট'), findsWidgets);
    expect(find.text('"বেজে" বলুন'), findsNothing);
  });

  testWidgets('appearance follows the setting', (tester) async {
    tallWindow(tester);
    final c = await tester.runAsync(controller);
    await tester.pumpWidget(BanglaVoiceClockApp(controller: c!));
    MaterialApp app() => tester.widget(find.byType(MaterialApp));
    expect(app().themeMode, ThemeMode.light, reason: 'light by default');
    await tester.runAsync(
      () => c.update(c.settings.copyWith(appearance: Appearance.dark)),
    );
    await tester.pump();
    expect(app().themeMode, ThemeMode.dark);
  });

  test('the timer says the time left and takes the floor', () async {
    final c = await controller();
    await c.start();
    await c.startTimer(70);
    await pumpEventQueue();
    expect(platform.notifications.last, 'টাইমার|আর এক ঘণ্টা দশ মিনিট বাকি');
    expect(c.voice.clipKeysFor(timeLeftTokens(70)), hasLength(2));
    expect(platform.entries.map((e) => e.id), contains('timer-stop'));
    expect(c.settings.timerMinutes, 70, reason: 'remembered for next time');
    platform.menu.add('timer-stop');
    await pumpEventQueue();
    expect(c.countdown.running, isFalse);
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

    expect(const AppSettings().style, AnnouncementStyle.exact);
    await tester.tap(find.text('প্রচলিত'));
    await tester.pump();
    expect(c.settings.style, AnnouncementStyle.traditional);
  });
}
