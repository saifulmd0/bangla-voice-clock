// Makes an AI voice pack with the ElevenLabs API.
//
//   dart run tool/elevenlabs.dart design [--description TEXT] [--text TEXT]
//       Designs three preview voices and saves them for listening.
//   dart run tool/elevenlabs.dart save --id GENERATED_VOICE_ID [--name NAME]
//       Keeps one preview in your ElevenLabs voice library.
//   dart run tool/elevenlabs.dart sample --voice VOICE_ID [--text TEXT]
//       Speaks one line, to try a voice before generating a whole pack.
//   dart run tool/elevenlabs.dart generate --voice VOICE_ID --out DIR
//       [--model eleven_v3] [--pack-id ID] [--pack-name NAME] [--force]
//       [--dry-run]
//       Records every line of the voice script into a voice pack.
//
// The API key comes from ELEVENLABS_API_KEY, or from a line
// `ELEVENLABS_API_KEY=...` in a `.env` file here (git ignores it).
// `generate` skips clips that already exist, so an interrupted run can be
// resumed without paying for the same clips twice.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bangla_voice_clock/core/audio/pcm_audio.dart';
import 'package:bangla_voice_clock/core/audio/wav.dart';
import 'package:bangla_voice_clock/core/speech/voice_pack.dart';
import 'package:bangla_voice_clock/core/speech/voice_script.dart';

const _defaultDescription =
    'A cheerful young Bangladeshi girl, around 9 to 11 years old, speaking '
    'clear standard Bangla with a Bangladeshi (Dhaka) accent, not a Kolkata '
    'accent. Bright, sweet and friendly, with a calm, steady pace and clear '
    'pronunciation. Clean studio recording with no background noise.';

const _defaultPreviewText =
    'এখন সময় সকাল সোয়া দশটা। এখন সময় দুপুর সাড়ে বারোটা। '
    'এখন সময় সন্ধ্যা পৌনে সাতটা। এখন সময় রাত নয়টা বেজে সাতাশ মিনিট।';

/// ElevenLabs returns raw 16-bit mono PCM at this rate, which needs no
/// decoder and becomes WAV directly.
const _sampleRate = 24000;

Future<void> main(List<String> args) async {
  String? option(String name) {
    final i = args.indexOf(name);
    return i >= 0 && i + 1 < args.length ? args[i + 1] : null;
  }

  final command = args.isEmpty ? null : args.first;
  try {
    await _run(command, option, args);
  } on _ApiException catch (e) {
    stderr.writeln(e);
    exit(1);
  } finally {
    _api.close();
  }
}

Future<void> _run(
  String? command,
  String? Function(String) option,
  List<String> args,
) async {
  switch (command) {
    case 'design':
      await _design(
        description: option('--description') ?? _defaultDescription,
        text: option('--text') ?? _defaultPreviewText,
        outDir: option('--out') ?? 'voices_local/previews',
      );
    case 'save':
      final id = option('--id') ?? _usage();
      await _save(
        generatedVoiceId: id,
        name: option('--name') ?? 'Bangla Voice Clock girl',
        description: option('--description') ?? _defaultDescription,
      );
    case 'sample':
      final voiceId = option('--voice') ?? _usage();
      final out = option('--out') ?? 'voices_local/samples/$voiceId.wav';
      final audio = await _speak(
        voiceId,
        option('--model') ?? 'eleven_v3',
        option('--text') ?? 'এখন সময় রাত নয়টা বেজে সাতাশ মিনিট।',
      );
      await File(out).parent.create(recursive: true);
      await File(out).writeAsBytes(encodeWav(audio));
      stdout.writeln('Saved $out');
    case 'generate':
      await _generate(
        voiceId:
            option('--voice') ?? (args.contains('--dry-run') ? '' : _usage()),
        outDir: option('--out') ?? _usage(),
        model: option('--model') ?? 'eleven_v3',
        packId: option('--pack-id') ?? 'bn_ai_girl',
        packName: option('--pack-name') ?? 'শিশু কণ্ঠ (AI)',
        force: args.contains('--force'),
        dryRun: args.contains('--dry-run'),
      );
    default:
      _usage();
  }
}

Never _usage() {
  stderr.writeln(
    'Usage:\n'
    '  dart run tool/elevenlabs.dart design [--description TEXT] [--text TEXT] [--out DIR]\n'
    '  dart run tool/elevenlabs.dart save --id GENERATED_VOICE_ID [--name NAME]\n'
    '  dart run tool/elevenlabs.dart sample --voice VOICE_ID [--text TEXT] [--out FILE]\n'
    '  dart run tool/elevenlabs.dart generate --voice VOICE_ID --out DIR\n'
    '      [--model eleven_v3] [--pack-id ID] [--pack-name NAME] [--force] [--dry-run]',
  );
  exit(64);
}

Future<void> _design({
  required String description,
  required String text,
  required String outDir,
}) async {
  final response = await _api.postJson('/v1/text-to-voice/design', {
    'voice_description': description,
    'text': text,
    'model_id': 'eleven_ttv_v3',
  });
  final previews = (response['previews'] as List).cast<Map<String, dynamic>>();
  await Directory(outDir).create(recursive: true);
  for (final (i, preview) in previews.indexed) {
    final id = preview['generated_voice_id'] as String;
    final ext = (preview['media_type'] as String? ?? '').contains('wav')
        ? 'wav'
        : 'mp3';
    final path = '$outDir/preview_${i + 1}.$ext';
    await File(path).writeAsBytes(base64Decode(preview['audio_base_64']));
    stdout.writeln('Preview ${i + 1}: $path');
    stdout.writeln('  generated_voice_id: $id');
  }
  stdout.writeln(
    '\nListen with `afplay <file>`, then keep one with:\n'
    '  dart run tool/elevenlabs.dart save --id <generated_voice_id>',
  );
}

Future<void> _save({
  required String generatedVoiceId,
  required String name,
  required String description,
}) async {
  final response = await _api.postJson('/v1/text-to-voice', {
    'voice_name': name,
    'voice_description': description,
    'generated_voice_id': generatedVoiceId,
  });
  stdout.writeln('Saved. voice_id: ${response['voice_id']}');
}

Future<void> _generate({
  required String voiceId,
  required String outDir,
  required String model,
  required String packId,
  required String packName,
  required bool force,
  required bool dryRun,
}) async {
  final script = banglaVoiceScript();
  if (dryRun) {
    for (final line in script) {
      stdout.writeln('${_clipPath(line.key)}  ${line.text}');
    }
    final chars = script.fold(0, (sum, line) => sum + line.text.length);
    stdout.writeln('\n${script.length} clips, $chars characters.');
    return;
  }

  final clips = <String, String>{};
  final failed = <String>[];
  for (final (i, line) in script.indexed) {
    final path = _clipPath(line.key);
    final file = File('$outDir/$path');
    stdout.write('[${i + 1}/${script.length}] ${line.text} ');
    if (!force && file.existsSync()) {
      stdout.writeln('(exists)');
      clips[line.key] = path;
      continue;
    }
    try {
      final audio = await _speak(voiceId, model, line.text);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(encodeWav(audio));
      clips[line.key] = path;
      stdout.writeln('ok');
    } on _ApiException catch (e) {
      stdout.writeln('FAILED');
      stderr.writeln('  $e');
      failed.add(line.key);
    }
  }

  final manifest = VoicePackManifest(
    id: packId,
    name: packName,
    language: 'bn',
    credits:
        'AI voice designed and generated with ElevenLabs ($model, '
        'voice $voiceId).',
    clips: clips,
  );
  await File(
    '$outDir/${VoicePackManifest.fileName}',
  ).writeAsString('${const JsonEncoder.withIndent('  ').convert(manifest)}\n');
  stdout.writeln('\nWrote ${clips.length} clips to $outDir.');
  if (failed.isNotEmpty) {
    stderr.writeln(
      '${failed.length} failed; run the same command again to retry them.',
    );
    exit(1);
  }
}

/// Speaks [text], trimmed and level-normalised.
Future<PcmAudio> _speak(String voiceId, String model, String text) async {
  final pcm = await _api.post(
    '/v1/text-to-speech/$voiceId',
    {
      'text': text,
      'model_id': model,
      // Same seed and settings for every line keeps the takes alike.
      'seed': 1,
      'voice_settings': {'stability': 0.5, 'similarity_boost': 0.8},
    },
    query: {'output_format': 'pcm_$_sampleRate'},
  );
  return PcmAudio(
    pcm.buffer.asInt16List(pcm.offsetInBytes, pcm.lengthInBytes ~/ 2),
    _sampleRate,
  ).trimSilence().normalized();
}

/// Words go in `clips/`, phrases in `phrases/`, named after their keys.
String _clipPath(String key) {
  final name = key.replaceAll('.', '_').replaceAll(' ', '__');
  return '${key.contains(' ') ? 'phrases' : 'clips'}/$name.wav';
}

final _api = _ElevenLabs();

class _ApiException implements Exception {
  _ApiException(this.status, this.body);

  final int status;
  final String body;

  @override
  String toString() => 'ElevenLabs API error $status: $body';
}

class _ElevenLabs {
  final _client = HttpClient();
  late final String _key = _findKey();

  void close() => _client.close();

  static String _findKey() {
    final fromEnv = Platform.environment['ELEVENLABS_API_KEY'];
    if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
    final env = File('.env');
    if (env.existsSync()) {
      for (final line in env.readAsLinesSync()) {
        final match = RegExp(r'^\s*ELEVENLABS_API_KEY\s*=\s*"?([^"\s]+)"?\s*$')
            .firstMatch(line);
        if (match != null) return match.group(1)!;
      }
    }
    stderr.writeln(
      'No API key. Set ELEVENLABS_API_KEY, or put '
      'ELEVENLABS_API_KEY=... in a .env file in the project folder.',
    );
    exit(78);
  }

  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, Object?> body,
  ) async =>
      jsonDecode(utf8.decode(await post(path, body))) as Map<String, dynamic>;

  Future<Uint8List> post(
    String path,
    Map<String, Object?> body, {
    Map<String, String> query = const {},
  }) async {
    final uri = Uri.https(
      'api.elevenlabs.io',
      path,
      query.isEmpty ? null : query,
    );
    final request = await _client.postUrl(uri);
    request.headers
      ..set('xi-api-key', _key)
      ..contentType = ContentType.json;
    request.add(utf8.encode(jsonEncode(body)));
    final response = await request.close();
    final bytes = BytesBuilder(copy: false);
    await response.forEach(bytes.add);
    final data = bytes.toBytes();
    if (response.statusCode ~/ 100 != 2) {
      throw _ApiException(
        response.statusCode,
        utf8.decode(data, allowMalformed: true),
      );
    }
    return data;
  }
}
