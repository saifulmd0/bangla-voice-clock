import 'dart:io';
import 'dart:typed_data';

import 'package:bangla_voice_clock/core/audio/pcm_audio.dart';
import 'package:bangla_voice_clock/core/speech/bangla_words.dart';
import 'package:bangla_voice_clock/core/speech/legacy_voice_import.dart';
import 'package:bangla_voice_clock/core/speech/voice_pack.dart';
import 'package:flutter_test/flutter_test.dart';

// A made-up definition in the original VClock.def format.
const def = '''
# Comments and blank lines are ignored.

Bangla {
	language = Bangla;

	starter 100 400;	# এখন সময়
	hour[0]		500	800;	# 12
	hour[1]		900	1200;
	min[1]	1300	1600;	# 15 min
	zone[1]	1700	2000;	# Sokal
	ampm[0]	0	0; # disabled
}

English {
	language = English;
	starter		2100	2400;
	ampm[0]		2500	2800; 	# am
}
''';

void main() {
  group('parseLegacyVoiceDef', () {
    test('reads every block and entry', () {
      final blocks = parseLegacyVoiceDef(def);
      expect(blocks.map((b) => b.name), ['Bangla', 'English']);

      final bangla = blocks.first.entries;
      expect(bangla.keys, [
        'starter',
        'hour[0]',
        'hour[1]',
        'min[1]',
        'zone[1]',
      ]);
      expect(bangla['hour[1]']!.start, const Duration(milliseconds: 900));
      expect(bangla['hour[1]']!.end, const Duration(milliseconds: 1200));
    });

    test('drops entries disabled with 0 0', () {
      final bangla = parseLegacyVoiceDef(def).first;
      expect(bangla.entries.containsKey('ampm[0]'), isFalse);
    });

    test('rejects malformed files', () {
      expect(
        () => parseLegacyVoiceDef('Bangla {\n starter 1;\n}'),
        throwsFormatException,
      );
      expect(
        () => parseLegacyVoiceDef('Bangla {\n starter 1 2;\n'),
        throwsFormatException,
      );
      expect(() => parseLegacyVoiceDef('starter 1 2;'), throwsFormatException);
      expect(
        () => parseLegacyVoiceDef('B {\n hour[1] 500 400;\n}'),
        throwsFormatException,
      );
    });
  });

  test('Bangla key map covers every entry of the original', () {
    expect(banglaLegacyKeyMap['hour[0]'], ClipKeys.hour(12));
    expect(banglaLegacyKeyMap['hour[11]'], ClipKeys.hour(11));
    expect(banglaLegacyKeyMap['min[3]'], 'num.45 exact.minute');
    expect(banglaLegacyKeyMap['zone[5]'], ClipKeys.zone(DayZone.raat));
    expect(banglaLegacyKeyMap, hasLength(1 + 12 + 3 + 6));
  });

  test('importLegacyVoice writes a loadable, trimmed pack', () async {
    // 3 s of silence at 1 kHz with a 100 ms tone inside each clip range.
    const rate = 1000;
    final samples = Int16List(3000);
    for (final start in [200, 600, 1000, 1400, 1800]) {
      samples.fillRange(start, start + 100, 9000);
    }
    final dir = await Directory.systemTemp.createTemp('legacy_import_test');
    addTearDown(() => dir.delete(recursive: true));

    final manifest = await importLegacyVoice(
      block: parseLegacyVoiceDef(def).first,
      recording: PcmAudio(samples, rate),
      keyMap: banglaLegacyKeyMap,
      outDir: dir,
      id: 'bn_test',
      name: 'Test',
      language: 'bn',
    );
    expect(manifest.clips.keys, [
      ClipKeys.starter,
      ClipKeys.hour(12),
      ClipKeys.hour(1),
      'num.15 exact.minute',
      ClipKeys.zone(DayZone.sokal),
    ]);

    final pack = await VoicePack.loadDirectory(dir.path);
    final clip = await pack.clip(ClipKeys.hour(1));
    // The 300 ms range is trimmed to the 100 ms tone plus 40 ms either side.
    expect(clip.length, 180);
    expect(clip.sampleRate, rate);
  });
}
