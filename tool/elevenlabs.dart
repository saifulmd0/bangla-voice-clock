// Makes an AI voice pack with the ElevenLabs API.
//
//   dart run tool/elevenlabs.dart design [--description TEXT] [--text TEXT]
//       Designs three preview voices and saves them for listening.
//   dart run tool/elevenlabs.dart save --id GENERATED_VOICE_ID [--name NAME]
//       Keeps one preview in your ElevenLabs voice library.
//   dart run tool/elevenlabs.dart sample --voice VOICE_ID [--text TEXT]
//       Speaks one line, to try a voice before generating a whole pack.
//   dart run tool/elevenlabs.dart check --pack DIR [--only KEY_OR_PATH,...]
//       Transcribes every clip and lists the ones that don't say their line.
//   dart run tool/elevenlabs.dart generate --voice VOICE_ID --out DIR
//       [--model eleven_v4] [--pack-id ID] [--pack-name NAME] [--pack-author NAME]
//       [--redo KEY_OR_PATH,...] [--seed N] [--force] [--dry-run]
//       Records every line of the voice script into a voice pack.
//
// The API key comes from ELEVENLABS_API_KEY, or from a line
// `ELEVENLABS_API_KEY=...` in a `.env` file here (git ignores it).
//
// `generate` keeps each untrimmed take in voices_local/raw/<pack-id>/ and
// reuses it, so a rerun only pays for lines without a take yet (or listed
// in --redo), and re-trimming every clip is free. To replace a bad take,
// pass it to --redo with a new --seed; the same seed gives the same take.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bangla_voice_clock/core/audio/pcm_audio.dart';
import 'package:bangla_voice_clock/core/audio/wav.dart';
import 'package:bangla_voice_clock/core/speech/voice_pack.dart';
import 'package:bangla_voice_clock/core/speech/voice_script.dart';

const _defaultDescription =
    'A soft, cute and gentle young Bangladeshi woman in her early twenties, '
    'with a sweet, light, high and airy voice, speaking clear standard Bangla '
    'with a Bangladeshi (Dhaka) accent, not a Kolkata accent. Tender, warm and '
    'calm, with a slow, steady pace. Clean studio recording with no '
    'background noise.';

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
        name: option('--name') ?? 'Bangla Voice Clock',
        description: option('--description') ?? _defaultDescription,
      );
    case 'sample':
      final voiceId = option('--voice') ?? _usage();
      final out = option('--out') ?? 'voices_local/samples/$voiceId.wav';
      final audio = _clean(
        await _speak(
          voiceId,
          option('--model') ?? 'eleven_v4',
          option('--text') ?? 'এখন সময় রাত নয়টা বেজে সাতাশ মিনিট।',
        ),
      );
      await File(out).parent.create(recursive: true);
      await File(out).writeAsBytes(encodeWav(audio));
      stdout.writeln('Saved $out');
    case 'check':
      await _check(
        option('--pack') ?? _usage(),
        only: {...?option('--only')?.split(',').map((s) => s.trim())},
      );
    case 'generate':
      await _generate(
        voiceId:
            option('--voice') ?? (args.contains('--dry-run') ? '' : _usage()),
        outDir: option('--out') ?? _usage(),
        model: option('--model') ?? 'eleven_v4',
        packId: option('--pack-id') ?? 'bn_ai',
        packName: option('--pack-name') ?? 'Areeba AI (ElevenLabs)',
        packAuthor: option('--pack-author') ?? 'Saiful Islam',
        redo: {...?option('--redo')?.split(',').map((s) => s.trim())},
        seed: int.parse(option('--seed') ?? '1'),
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
    '  dart run tool/elevenlabs.dart check --pack DIR [--only KEY_OR_PATH,...]\n'
    '  dart run tool/elevenlabs.dart generate --voice VOICE_ID --out DIR\n'
    '      [--model eleven_v4] [--pack-id ID] [--pack-name NAME] [--pack-author NAME]\n'
    '      [--redo KEY_OR_PATH,...] [--seed N] [--force] [--dry-run]',
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
  required String packAuthor,
  required Set<String> redo,
  required int seed,
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

  final unknown = redo.where(
    (r) => !script.any((l) => l.key == r || _clipPath(l.key) == r),
  );
  if (unknown.isNotEmpty) {
    stderr.writeln('Not in the voice script: ${unknown.join(', ')}');
    exit(64);
  }

  final rawDir = 'voices_local/raw/$packId';
  final clips = <String, String>{};
  final failed = <String>[];
  for (final (i, line) in script.indexed) {
    final path = _clipPath(line.key);
    final raw = File('$rawDir/$path');
    final again = force || redo.contains(line.key) || redo.contains(path);
    stdout.write('[${i + 1}/${script.length}] ${line.text} ');
    try {
      final PcmAudio take;
      if (!again && raw.existsSync()) {
        take = decodeWav(await raw.readAsBytes());
        stdout.writeln('(kept)');
      } else {
        take = await _speak(voiceId, model, line.text, seed: seed);
        await raw.parent.create(recursive: true);
        await raw.writeAsBytes(encodeWav(take));
        stdout.writeln('ok');
      }
      final clip = File('$outDir/$path');
      await clip.parent.create(recursive: true);
      await clip.writeAsBytes(encodeWav(_clean(take)));
      clips[line.key] = path;
    } on _ApiException catch (e) {
      stdout.writeln('FAILED');
      stderr.writeln('  $e');
      failed.add(line.key);
    }
  }

  final manifest = VoicePackManifest(
    id: packId,
    name: packName,
    author: packAuthor,
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

/// Transcribes each clip of the pack at [packDir] and reports any whose
/// words differ from its script line. Speech-to-text isn't perfect, so a
/// mismatch means "listen to this one", not "this one is wrong".
///
/// With [only], checks just those keys or clip paths.
Future<void> _check(String packDir, {Set<String> only = const {}}) async {
  final pack = await VoicePack.loadDirectory(packDir);
  // Compare letters only: speech-to-text may write য় as য + ় and split
  // compound numbers into two words.
  String words(String text) => text
      .replaceAll('\u09AF\u09BC', '\u09DF')
      .replaceAll('\u09A1\u09BC', '\u09DC')
      .replaceAll('\u09A2\u09BC', '\u09DD')
      .replaceAll(RegExp(r'[\s।,.!?]'), '');
  final suspects = <String>[];
  final script = banglaVoiceScript()
      .where((l) => pack.has(l.key))
      .where(
        (l) =>
            only.isEmpty ||
            only.contains(l.key) ||
            only.contains(_clipPath(l.key)),
      )
      .toList();
  for (final (i, line) in script.indexed) {
    final path = pack.manifest.clips[line.key]!;
    final heard = await _api.transcribe(
      await File('$packDir/$path').readAsBytes(),
    );
    final ok = words(heard) == words(line.text);
    stdout.writeln(
      '[${i + 1}/${script.length}] ${ok ? 'ok  ' : 'DIFF'} ${line.text}'
      '${ok ? '' : '  (heard: $heard)'}',
    );
    if (!ok) suspects.add('$path  expected "${line.text}", heard "$heard"');
  }
  stdout.writeln('\n${suspects.length} of ${script.length} to listen to:');
  suspects.forEach(stdout.writeln);
}

/// Speaks [text], untrimmed.
Future<PcmAudio> _speak(
  String voiceId,
  String model,
  String text, {
  int seed = 1,
}) async {
  final pcm = await _api.post(
    '/v1/text-to-speech/$voiceId',
    {
      'text': text,
      'model_id': model,
      // Same seed and settings for every line keeps the takes alike.
      'seed': seed,
      'voice_settings': {'stability': 0.5, 'similarity_boost': 0.8},
    },
    query: {'output_format': 'pcm_$_sampleRate'},
  );
  return PcmAudio(
    pcm.buffer.asInt16List(pcm.offsetInBytes, pcm.lengthInBytes ~/ 2),
    _sampleRate,
  );
}

/// Trims and levels a take. AI audio has no hiss, so a low threshold keeps
/// soft word endings that the default (tuned for old recordings) would cut,
/// and there's no noise floor to measure: in a take with little silence the
/// quietest fifth is speech, and trimming above it cut soft endings such as
/// the "জে" of "বেজে".
PcmAudio _clean(PcmAudio take) => take
    .trimSilence(
      threshold: 0.02,
      noiseFactor: 0,
      padding: const Duration(milliseconds: 60),
    )
    .normalized();

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

  /// Bangla speech-to-text with Scribe.
  Future<String> transcribe(Uint8List wav) async {
    const boundary = 'bangla-voice-clock-boundary';
    final body = BytesBuilder()
      ..add(utf8.encode(_field(boundary, 'model_id', 'scribe_v1')))
      ..add(utf8.encode(_field(boundary, 'language_code', 'ben')))
      ..add(
        utf8.encode(
          '--$boundary\r\n'
          'Content-Disposition: form-data; name="file"; filename="clip.wav"\r\n'
          'Content-Type: audio/wav\r\n\r\n',
        ),
      )
      ..add(wav)
      ..add(utf8.encode('\r\n--$boundary--\r\n'));
    final data = await _send(
      Uri.https('api.elevenlabs.io', '/v1/speech-to-text'),
      body.toBytes(),
      ContentType('multipart', 'form-data', parameters: {'boundary': boundary}),
    );
    return (jsonDecode(utf8.decode(data)) as Map<String, dynamic>)['text']
        as String;
  }

  static String _field(String boundary, String name, String value) =>
      '--$boundary\r\n'
      'Content-Disposition: form-data; name="$name"\r\n\r\n'
      '$value\r\n';

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
    return _send(uri, utf8.encode(jsonEncode(body)), ContentType.json);
  }

  Future<Uint8List> _send(
    Uri uri,
    List<int> body,
    ContentType contentType,
  ) async {
    final request = await _client.postUrl(uri);
    request.headers
      ..set('xi-api-key', _key)
      ..contentType = contentType;
    request.add(body);
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
