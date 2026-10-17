import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../audio/audio_composer.dart';
import '../audio/pcm_audio.dart';
import '../audio/wav.dart';
import 'speech_token.dart';

/// Where a voice pack's files come from: a folder on disk now, Flutter
/// assets for the bundled pack later.
abstract interface class ClipSource {
  Future<Uint8List> read(String path);
}

class DirectoryClipSource implements ClipSource {
  DirectoryClipSource(this.directory);

  final Directory directory;

  @override
  Future<Uint8List> read(String path) =>
      File('${directory.path}/$path').readAsBytes();
}

class MissingClipsException implements Exception {
  MissingClipsException(this.packId, this.keys);

  final String packId;
  final List<String> keys;

  @override
  String toString() =>
      'Voice pack "$packId" has no clip for: ${keys.join(', ')}';
}

/// The contents of a voice pack's `manifest.json`.
class VoicePackManifest {
  const VoicePackManifest({
    required this.id,
    required this.name,
    required this.language,
    required this.clips,
    this.credits = '',
  });

  factory VoicePackManifest.fromJson(Map<String, dynamic> json) {
    final format = json['format'];
    if (format != formatVersion) {
      throw FormatException('Unsupported voice pack format: $format');
    }
    return VoicePackManifest(
      id: json['id'] as String,
      name: json['name'] as String,
      language: json['language'] as String,
      credits: json['credits'] as String? ?? '',
      clips: Map<String, String>.from(json['clips'] as Map),
    );
  }

  static const formatVersion = 1;
  static const fileName = 'manifest.json';

  final String id;
  final String name;

  /// BCP 47 language code, such as `bn`.
  final String language;
  final String credits;

  /// Clip key → path of a WAV file, relative to the pack folder.
  final Map<String, String> clips;

  Map<String, dynamic> toJson() => {
    'format': formatVersion,
    'id': id,
    'name': name,
    'language': language,
    if (credits.isNotEmpty) 'credits': credits,
    'clips': clips,
  };
}

/// A set of recorded clips that speak announcement tokens.
class VoicePack {
  VoicePack(this.manifest, this._source);

  static Future<VoicePack> load(ClipSource source) async {
    final bytes = await source.read(VoicePackManifest.fileName);
    final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    return VoicePack(VoicePackManifest.fromJson(json), source);
  }

  static Future<VoicePack> loadDirectory(String path) =>
      load(DirectoryClipSource(Directory(path)));

  final VoicePackManifest manifest;
  final ClipSource _source;
  final _cache = <String, PcmAudio>{};

  String get id => manifest.id;

  bool has(String key) => manifest.clips.containsKey(key);

  /// The clip keys that will speak [tokens], using each token's fallback
  /// when the pack lacks its own clip.
  ///
  /// Throws [MissingClipsException] when a token can't be spoken at all.
  List<String> clipKeysFor(List<SpeechToken> tokens) {
    final keys = <String>[];
    final missing = <String>[];
    for (final token in tokens) {
      if (has(token.key)) {
        keys.add(token.key);
      } else if (token.fallback.isNotEmpty && token.fallback.every(has)) {
        keys.addAll(token.fallback);
      } else {
        missing.add(token.key);
      }
    }
    if (missing.isNotEmpty) throw MissingClipsException(id, missing);
    return keys;
  }

  bool canSpeak(List<SpeechToken> tokens) {
    try {
      clipKeysFor(tokens);
      return true;
    } on MissingClipsException {
      return false;
    }
  }

  Future<PcmAudio> clip(String key) async {
    final cached = _cache[key];
    if (cached != null) return cached;
    final path = manifest.clips[key];
    if (path == null) throw MissingClipsException(id, [key]);
    return _cache[key] = decodeWav(await _source.read(path));
  }

  /// Renders [tokens] as one continuous piece of audio.
  Future<PcmAudio> render(
    List<SpeechToken> tokens, {
    AudioComposer composer = const AudioComposer(),
  }) async {
    final clips = [for (final key in clipKeysFor(tokens)) await clip(key)];
    return composer.compose(clips);
  }
}
