import 'dart:io';

import 'package:bangla_voice_clock/core/settings/app_settings.dart';
import 'package:bangla_voice_clock/core/settings/settings_store.dart';
import 'package:bangla_voice_clock/core/speech/bangla_phrase_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('round-trips through JSON', () {
    const s = AppSettings(
      muted: true,
      intervalMinutes: 30,
      style: AnnouncementStyle.exact,
      voiceId: 'bn_classic',
      volume: 0.4,
      chime: false,
      notify: false,
      quietHoursEnabled: true,
      quietStartHour: 22,
      quietEndHour: 6,
      menuBarShows: MenuBarShows.logo,
      language: AppLanguage.en,
      appearance: Appearance.dark,
      sayBeje: false,
      welcomed: true,
    );
    expect(AppSettings.fromJson(s.toJson()).toJson(), s.toJson());
  });

  test('bad or missing values fall back to the defaults', () {
    final s = AppSettings.fromJson({
      'intervalMinutes': 7,
      'style': 'shouting',
      'volume': 3,
      'muted': 'yes',
    });
    const d = AppSettings();
    expect(s.intervalMinutes, d.intervalMinutes);
    expect(s.style, d.style);
    expect(s.volume, 1.0);
    expect(s.muted, d.muted);
  });

  test('reads the old menu-bar switch', () {
    expect(
      AppSettings.fromJson({'showClockInMenuBar': false}).menuBarShows,
      MenuBarShows.logo,
    );
    expect(AppSettings.fromJson({}).language, AppLanguage.bn);
  });

  test('quiet hours only apply when enabled', () {
    expect(const AppSettings().schedule.quietHours, isNull);
    expect(
      const AppSettings(quietHoursEnabled: true).schedule.quietHours,
      isNotNull,
    );
  });

  group('SettingsStore', () {
    late Directory dir;
    setUp(() async => dir = await Directory.systemTemp.createTemp('settings'));
    tearDown(() => dir.delete(recursive: true));

    test('saves and loads', () async {
      final store = SettingsStore(File('${dir.path}/a/settings.json'));
      expect((await store.load()).intervalMinutes, 15);
      await store.save(const AppSettings(intervalMinutes: 60));
      expect((await store.load()).intervalMinutes, 60);
    });

    test('overlapping saves keep the last one', () async {
      final store = SettingsStore(File('${dir.path}/settings.json'));
      await Future.wait([
        for (var i = 1; i <= 20; i++) store.save(AppSettings(volume: i / 20)),
      ]);
      expect((await store.load()).volume, 1.0);
    });

    test('a damaged file gives the defaults', () async {
      final file = File('${dir.path}/settings.json')..writeAsStringSync('{');
      expect((await SettingsStore(file).load()).voiceId, 'bn_ai');
    });
  });
}
