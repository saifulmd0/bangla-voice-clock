import 'dart:io';

import 'package:bangla_voice_clock/app/version.dart';
import 'package:bangla_voice_clock/core/update/release.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, Object?> release(
  String tag, {
  bool draft = false,
  bool prerelease = true,
  List<Map<String, Object?>> assets = const [],
}) => {
  'tag_name': tag,
  'draft': draft,
  'prerelease': prerelease,
  'html_url':
      'https://github.com/saifulmd0/bangla-voice-clock/releases/tag/$tag',
  'body': '## New\n\n- **Quiet hours** to the minute\n\n| a | b |\n|---|---|',
  'assets': assets,
};

void main() {
  test('versions compare part by part', () {
    final v = Version.tryParse;
    expect(v('v0.10.0')! > v('0.9.9')!, isTrue);
    expect(v('1.0.0')! > v('1.0.0')!, isFalse);
    expect(v('v0.2.0'), v('0.2.0'));
    expect(v('0.2'), isNull);
    expect(v('nightly'), isNull);
  });

  test('the newest release counts pre-releases but not drafts', () {
    final newest = newestRelease([
      release('v0.2.0', prerelease: false),
      release('v0.4.0', draft: true),
      release('v0.3.0'),
      release('latest'),
    ]);
    expect(newest!.version, Version.tryParse('0.3.0'));
    expect(newest.page.path, endsWith('/tag/v0.3.0'));
    expect(newestRelease([]), isNull);
  });

  test('assets carry their checksum', () {
    final newest = newestRelease([
      release(
        'v0.3.0',
        assets: [
          {
            'name': 'BanglaVoiceClock-v0.3.0-windows-setup.exe',
            'browser_download_url': 'https://example.com/setup.exe',
            'size': 42,
            'digest': 'sha256:abc123',
          },
          {
            'name': 'BanglaVoiceClock-v0.3.0-macos.dmg',
            'browser_download_url': 'https://example.com/app.dmg',
            'size': 7,
            'digest': null,
          },
        ],
      ),
    ])!;
    final setup = newest.asset('-windows-setup.exe')!;
    expect((setup.size, setup.sha256), (42, 'abc123'));
    expect(newest.asset('-macos.dmg')!.sha256, isNull);
    expect(newest.asset('-linux.tar.gz'), isNull);
  });

  test('notes read as plain text', () {
    final newest = newestRelease([release('v0.3.0')])!;
    expect(newest.plainNotes, 'New\n\n• Quiet hours to the minute');
  });

  test('appVersion matches pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final version = RegExp(
      r'^version: (\S+)\+',
      multiLine: true,
    ).firstMatch(pubspec)![1];
    expect(appVersion, version);
  });
}
