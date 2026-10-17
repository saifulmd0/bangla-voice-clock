// Speaks a time with a voice pack, for hearing the engine without the app.
//
//   dart run tool/speak.dart --pack <dir> [--time HH:MM] [--exact]
//                            [--out file.wav] [--no-play]
//
// Without --time it speaks the current time. It picks the words as the app
// does: exact minutes when traditional style can't say the time, and the
// quarter hour just passed when the pack can't say it either. Playback uses
// macOS `afplay`.
import 'dart:io';

import 'package:bangla_voice_clock/core/audio/pcm_audio.dart';
import 'package:bangla_voice_clock/core/audio/wav.dart';
import 'package:bangla_voice_clock/core/speech/announcement.dart';
import 'package:bangla_voice_clock/core/speech/bangla_phrase_builder.dart';
import 'package:bangla_voice_clock/core/speech/speech_token.dart';
import 'package:bangla_voice_clock/core/speech/voice_pack.dart';

Future<void> main(List<String> args) async {
  String? option(String name) {
    final i = args.indexOf(name);
    return i >= 0 && i + 1 < args.length ? args[i + 1] : null;
  }

  final packPath = option('--pack');
  if (packPath == null) {
    stderr.writeln(
      'Usage: dart run tool/speak.dart --pack <dir> [--time HH:MM] '
      '[--exact] [--out file.wav] [--no-play]',
    );
    exit(64);
  }

  final now = DateTime.now();
  var (hour, minute) = (now.hour, now.minute);
  final time = option('--time');
  if (time != null) {
    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(time);
    if (match == null) {
      stderr.writeln('--time must look like 10:15 (24-hour)');
      exit(64);
    }
    hour = int.parse(match.group(1)!);
    minute = int.parse(match.group(2)!);
  }

  final style = args.contains('--exact')
      ? AnnouncementStyle.exact
      : AnnouncementStyle.traditional;
  final pack = await VoicePack.loadDirectory(packPath);
  final tokens = announcementFor(
    DateTime(2000, 1, 1, hour, minute),
    style,
    pack,
  );
  stdout.writeln(tokens.text);

  final PcmAudio audio;
  try {
    audio = await pack.render(tokens);
  } on MissingClipsException catch (e) {
    stderr.writeln(e);
    exit(1);
  }
  final out =
      option('--out') ??
      '${Directory.systemTemp.path}/bangla_voice_clock_speak.wav';
  await File(out).writeAsBytes(encodeWav(audio));

  if (!args.contains('--no-play')) {
    await Process.run('afplay', [out]);
  } else {
    stdout.writeln('Saved $out');
  }
}
