// Turns the original Windows app's VClock.def + vclock.wav into a voice pack.
//
//   dart run tool/import_legacy_voice.dart <VClock.def> <vclock.wav> <out-dir>
import 'dart:io';

import 'package:bangla_voice_clock/core/audio/wav.dart';
import 'package:bangla_voice_clock/core/speech/legacy_voice_import.dart';

Future<void> main(List<String> args) async {
  if (args.length != 3) {
    stderr.writeln(
      'Usage: dart run tool/import_legacy_voice.dart '
      '<VClock.def> <vclock.wav> <out-dir>',
    );
    exit(64);
  }
  final [defPath, wavPath, outPath] = args;

  final blocks = parseLegacyVoiceDef(await File(defPath).readAsString());
  final bangla = blocks.where((b) => b.name == 'Bangla').firstOrNull;
  if (bangla == null) {
    stderr.writeln('No "Bangla { ... }" block in $defPath');
    exit(65);
  }

  final manifest = await importLegacyVoice(
    block: bangla,
    recording: decodeWav(await File(wavPath).readAsBytes()),
    keyMap: banglaLegacyKeyMap,
    outDir: Directory(outPath),
    id: 'bn_classic',
    name: 'ক্লাসিক (১৯৯৮)',
    language: 'bn',
    credits:
        'Voice of Moshfekah Ferdaus Mahita, from Bangla Voice Clock '
        '(1998-2002) by Q A M Khaled Ferdaus.',
  );
  stdout.writeln('Wrote ${manifest.clips.length} clips to $outPath');
}
