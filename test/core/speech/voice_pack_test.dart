import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bangla_voice_clock/core/audio/audio_composer.dart';
import 'package:bangla_voice_clock/core/audio/pcm_audio.dart';
import 'package:bangla_voice_clock/core/audio/wav.dart';
import 'package:bangla_voice_clock/core/speech/bangla_phrase_builder.dart';
import 'package:bangla_voice_clock/core/speech/bangla_words.dart';
import 'package:bangla_voice_clock/core/speech/voice_pack.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory dir;

  /// Writes a pack whose clip for each key is [frames] samples long.
  Future<VoicePack> writePack(Map<String, int> frames) async {
    final clips = <String, String>{};
    await Directory('${dir.path}/clips').create();
    for (final MapEntry(key: key, value: n) in frames.entries) {
      final path = 'clips/$key.wav';
      final audio = PcmAudio(Int16List.fromList(List.filled(n, 1000)), 8000);
      await File('${dir.path}/$path').writeAsBytes(encodeWav(audio));
      clips[key] = path;
    }
    await File('${dir.path}/manifest.json').writeAsString(
      jsonEncode(
        const VoicePackManifest(
          id: 'test',
          name: 'Test',
          language: 'bn',
          clips: {},
        ).toJson()..['clips'] = clips,
      ),
    );
    return VoicePack.loadDirectory(dir.path);
  }

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('voice_pack_test');
  });
  tearDown(() => dir.delete(recursive: true));

  final builder = BanglaPhraseBuilder();
  final quarterPack = {
    ClipKeys.starter: 100,
    for (final z in DayZone.values) ClipKeys.zone(z): 100,
    for (var h = 1; h <= 12; h++) ClipKeys.hour(h): 100,
    ClipKeys.sowa: 100,
    ClipKeys.sare: 100,
    ClipKeys.poune: 100,
  };

  test('loads the manifest', () async {
    final pack = await writePack(quarterPack);
    expect(pack.id, 'test');
    expect(pack.manifest.language, 'bn');
    expect(pack.has(ClipKeys.sowa), isTrue);
  });

  test('uses fallback clips when দেড়টা is missing', () async {
    final pack = await writePack(quarterPack);
    expect(pack.clipKeysFor(builder.build(13, 30)), [
      ClipKeys.starter,
      ClipKeys.zone(DayZone.dupur),
      ClipKeys.sare,
      ClipKeys.hour(1),
    ]);
  });

  test('prefers its own দেড়টা clip when present', () async {
    final pack = await writePack({...quarterPack, ClipKeys.der: 100});
    expect(pack.clipKeysFor(builder.build(13, 30)).last, ClipKeys.der);
  });

  test('reports every missing clip', () async {
    final pack = await writePack(quarterPack);
    final tokens = builder.build(10, 7, style: AnnouncementStyle.exact);
    expect(pack.canSpeak(tokens), isFalse);
    expect(
      () => pack.clipKeysFor(tokens),
      throwsA(
        isA<MissingClipsException>().having((e) => e.keys, 'keys', [
          ClipKeys.beje,
          ClipKeys.number(7),
          ClipKeys.minute,
        ]),
      ),
    );
  });

  test('a quarter-hour pack speaks every quarter of the day', () async {
    final pack = await writePack(quarterPack);
    for (var h = 0; h < 24; h++) {
      for (final m in [0, 15, 30, 45]) {
        expect(pack.canSpeak(builder.build(h, m)), isTrue, reason: '$h:$m');
      }
    }
  });

  test('render joins the clips into one buffer', () async {
    final pack = await writePack({
      ...quarterPack,
      ClipKeys.starter: 300,
      ClipKeys.sowa: 200,
    });
    const composer = AudioComposer(gap: Duration(milliseconds: 10));
    final audio = await pack.render(builder.build(10, 15), composer: composer);
    // starter + zone + সোয়া + দশটা, with three 80-frame gaps at 8 kHz.
    expect(audio.length, 300 + 100 + 200 + 100 + 3 * 80);
    expect(audio.sampleRate, 8000);
  });

  test('rejects an unknown manifest format', () {
    expect(
      () => VoicePackManifest.fromJson({'format': 99}),
      throwsFormatException,
    );
  });
}
