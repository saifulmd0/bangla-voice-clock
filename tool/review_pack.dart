// Joins a voice pack's clips into a few long files, for listening through
// a whole pack in one go.
//
//   dart run tool/review_pack.dart --pack <dir> [--out <dir>]
//
// Writes 1_words.wav (every single-word clip), 2_quarter_hours.wav (every
// quarter-hour announcement) and 3_exact.wav (one exact-time announcement
// per minute ending, cycling through the hours, so every opening and every
// ending is heard as the app will join them), each with a .txt cue list.
import 'dart:io';
import 'dart:typed_data';

import 'package:bangla_voice_clock/core/audio/pcm_audio.dart';
import 'package:bangla_voice_clock/core/audio/wav.dart';
import 'package:bangla_voice_clock/core/speech/bangla_phrase_builder.dart';
import 'package:bangla_voice_clock/core/speech/speech_token.dart';
import 'package:bangla_voice_clock/core/speech/voice_pack.dart';
import 'package:bangla_voice_clock/core/speech/voice_script.dart';

const _gap = Duration(milliseconds: 700);

Future<void> main(List<String> args) async {
  String? option(String name) {
    final i = args.indexOf(name);
    return i >= 0 && i + 1 < args.length ? args[i + 1] : null;
  }

  final packPath = option('--pack');
  if (packPath == null) {
    stderr.writeln(
      'Usage: dart run tool/review_pack.dart --pack <dir> [--out <dir>]',
    );
    exit(64);
  }
  final outDir = option('--out') ?? '${Directory.systemTemp.path}/voice_review';
  await Directory(outDir).create(recursive: true);
  final pack = await VoicePack.loadDirectory(packPath);
  final builder = BanglaPhraseBuilder();

  final words = banglaVoiceScript(phrases: false);
  await _write('$outDir/1_words', [
    for (final line in words)
      if (pack.has(line.key)) (line.text, () => pack.clip(line.key)),
  ]);

  await _write('$outDir/2_quarter_hours', [
    for (var h = 0; h < 24; h++)
      for (final m in const [0, 15, 30, 45])
        _announce(pack, builder.build(h, m), h, m),
  ]);

  await _write('$outDir/3_exact', [
    for (var m = 1; m < 60; m++)
      _announce(
        pack,
        builder.build(m % 24, m, style: AnnouncementStyle.exact),
        m % 24,
        m,
      ),
  ]);
  stdout.writeln('Wrote review files to $outDir');
}

(String, Future<PcmAudio> Function()) _announce(
  VoicePack pack,
  List<SpeechToken> tokens,
  int h,
  int m,
) => (
  '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}  ${tokens.text}',
  () => pack.render(tokens),
);

Future<void> _write(
  String base,
  List<(String, Future<PcmAudio> Function())> items,
) async {
  final parts = <PcmAudio>[];
  final cues = StringBuffer();
  var at = Duration.zero;
  for (final (label, load) in items) {
    final audio = await load();
    cues.writeln('${_time(at)}  $label');
    parts.add(audio);
    at += audio.duration + _gap;
  }
  if (parts.isEmpty) return;
  final rate = parts.first.sampleRate;
  final silence = PcmAudio.silence(_gap, rate).samples;
  final samples = [
    for (final part in parts) ...[...part.samples, ...silence],
  ];
  await File('$base.wav')
      .writeAsBytes(encodeWav(PcmAudio(Int16List.fromList(samples), rate)));
  await File('$base.txt').writeAsString(cues.toString());
  stdout.writeln(
    '${base.split('/').last}.wav: ${items.length} items, ${_time(at)}',
  );
}

String _time(Duration d) =>
    '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
