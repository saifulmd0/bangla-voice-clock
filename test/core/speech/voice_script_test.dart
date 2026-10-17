import 'dart:typed_data';

import 'package:bangla_voice_clock/core/speech/bangla_phrase_builder.dart';
import 'package:bangla_voice_clock/core/speech/speech_token.dart';
import 'package:bangla_voice_clock/core/speech/timer_phrases.dart';
import 'package:bangla_voice_clock/core/speech/voice_pack.dart';
import 'package:bangla_voice_clock/core/speech/voice_script.dart';
import 'package:flutter_test/flutter_test.dart';

class _NoFiles implements ClipSource {
  @override
  Future<Uint8List> read(String path) => throw UnimplementedError();
}

VoicePack _packOf(List<ScriptLine> script) => VoicePack(
  VoicePackManifest(
    id: 'script',
    name: 'Script',
    language: 'bn',
    clips: {for (final line in script) line.key: 'x.wav'},
  ),
  _NoFiles(),
);

void main() {
  final builder = BanglaPhraseBuilder();
  final script = banglaVoiceScript();

  test('every line has its own key', () {
    expect(script.map((l) => l.key).toSet().length, script.length);
  });

  test('records 85 words, 96 announcements and 48 + 59 exact parts', () {
    expect(banglaVoiceScript(phrases: false), hasLength(85));
    expect(script, hasLength(85 + 96 + 24 + 24 + 59 + 124));
  });

  test('a full pack counts down any timer in at most two takes', () {
    final pack = _packOf(script);
    for (var m = 1; m <= maxTimerMinutes; m++) {
      expect(
        pack.clipKeysFor(timeLeftTokens(m)),
        hasLength(m < 60 || m % 60 == 0 ? 1 : 2),
        reason: '$m',
      );
    }
    expect(timeLeftTokens(70).text, 'আর এক ঘণ্টা দশ মিনিট বাকি');
    expect(pack.clipKeysFor(timerDoneTokens), ['timer.done']);
  });

  test('without বেজে, exact minutes are still two takes', () {
    final pack = _packOf(script);
    final noBeje = BanglaPhraseBuilder(sayBeje: false);
    final tokens = noBeje.build(10, 7, style: AnnouncementStyle.exact);
    expect(tokens.text, 'এখন সময় সকাল দশটা সাত মিনিট');
    expect(pack.clipKeysFor(tokens), [
      'starter zone.sokal hour.10 exact.open',
      'num.7 exact.minute',
    ]);
  });

  test('announcement lines read as finished sentences', () {
    final line = script.firstWhere((l) => l.text.contains('সোয়া দশটা'));
    expect(line.text, 'এখন সময় সকাল সোয়া দশটা।');
  });

  test('a full pack says each quarter hour in one take', () {
    final pack = _packOf(script);
    for (var h = 0; h < 24; h++) {
      for (final m in [0, 15, 30, 45]) {
        expect(pack.clipKeysFor(builder.build(h, m)), hasLength(1));
      }
    }
  });

  test('a full pack says any exact minute in at most two takes', () {
    final pack = _packOf(script);
    for (var h = 0; h < 24; h++) {
      for (var m = 0; m < 60; m++) {
        final tokens = builder.build(h, m, style: AnnouncementStyle.exact);
        expect(pack.clipKeysFor(tokens), hasLength(m == 0 ? 1 : 2));
      }
    }
  });

  test('the words alone can say every minute', () {
    final pack = _packOf(banglaVoiceScript(phrases: false));
    for (var h = 0; h < 24; h++) {
      for (var m = 0; m < 60; m++) {
        final style = m % 15 == 0
            ? AnnouncementStyle.traditional
            : AnnouncementStyle.exact;
        expect(pack.canSpeak(builder.build(h, m, style: style)), isTrue);
      }
    }
  });
}
