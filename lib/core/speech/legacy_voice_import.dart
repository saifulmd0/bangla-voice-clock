import 'dart:convert';
import 'dart:io';

import '../audio/pcm_audio.dart';
import '../audio/wav.dart';
import 'bangla_words.dart';
import 'voice_pack.dart';

/// A clip location in the original app's single WAV file.
class LegacyClipRange {
  const LegacyClipRange(this.start, this.end);

  final Duration start;
  final Duration end;
}

/// One language block of a `VClock.def` file, e.g. `Bangla { ... }`.
class LegacyVoiceBlock {
  const LegacyVoiceBlock(this.name, this.entries);

  final String name;

  /// Entry name as written in the file (`starter`, `hour[3]`, `zone[0]` …)
  /// → its range. Entries the file disables with `0 0` are left out.
  final Map<String, LegacyClipRange> entries;
}

/// Parses the `VClock.def` format of the original Windows Bangla Voice Clock
/// (v3.2b and later), which lets users supply their own recorded voice.
///
/// Each block looks like:
///
/// ```text
/// Bangla {
///   language = Bangla;
///   starter 34000 35278;     # milliseconds into VClock.wav
///   hour[0] 422 1622;        # 12 o'clock
///   ...
/// }
/// ```
List<LegacyVoiceBlock> parseLegacyVoiceDef(String text) {
  final blocks = <LegacyVoiceBlock>[];
  final entry = RegExp(r'^(\w+(?:\[\d+\])?)\s+(\d+)\s+(\d+)\s*;?$');
  String? name;
  var entries = <String, LegacyClipRange>{};

  final lines = const LineSplitter().convert(text);
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i].split('#').first.trim();
    if (line.isEmpty) continue;

    if (name == null) {
      final header = RegExp(r'^(\w+)\s*\{$').firstMatch(line);
      if (header == null) {
        throw FormatException('Expected "Name {" on line ${i + 1}', line);
      }
      name = header.group(1);
      entries = {};
    } else if (line == '}') {
      blocks.add(LegacyVoiceBlock(name, entries));
      name = null;
    } else if (line.startsWith('language')) {
      continue;
    } else {
      final match = entry.firstMatch(line);
      if (match == null) {
        throw FormatException('Unreadable entry on line ${i + 1}', line);
      }
      final start = int.parse(match.group(2)!);
      final end = int.parse(match.group(3)!);
      if (start == 0 && end == 0) continue; // disabled in the def file
      if (end <= start) {
        throw FormatException('Clip ends before it starts on line ${i + 1}');
      }
      entries[match.group(1)!] = LegacyClipRange(
        Duration(milliseconds: start),
        Duration(milliseconds: end),
      );
    }
  }
  if (name != null) throw FormatException('Block "$name" is never closed');
  return blocks;
}

/// How the original's Bangla entries map onto this app's clip keys.
///
/// The original's three quarter-hour clips are the prefix words
/// সোয়া / সাড়ে / পৌনে. It had no দেড়টা or আড়াইটা, so those fall back to
/// "সাড়ে একটা" and "সাড়ে দুইটা".
final banglaLegacyKeyMap = <String, String>{
  'starter': ClipKeys.starter,
  'hour[0]': ClipKeys.hour(12),
  for (var h = 1; h <= 11; h++) 'hour[$h]': ClipKeys.hour(h),
  'min[1]': ClipKeys.sowa,
  'min[2]': ClipKeys.sare,
  'min[3]': ClipKeys.poune,
  for (final zone in DayZone.values) 'zone[${zone.index}]': ClipKeys.zone(zone),
};

/// Cuts a legacy `VClock.wav` into a voice pack folder.
///
/// Each clip is trimmed of surrounding silence, because the original's
/// ranges include generous padding. Returns the written manifest.
Future<VoicePackManifest> importLegacyVoice({
  required LegacyVoiceBlock block,
  required PcmAudio recording,
  required Map<String, String> keyMap,
  required Directory outDir,
  required String id,
  required String name,
  required String language,
  String credits = '',
}) async {
  final clipsDir = Directory('${outDir.path}/clips');
  await clipsDir.create(recursive: true);

  final clips = <String, String>{};
  for (final MapEntry(key: entryName, value: range) in block.entries.entries) {
    final key = keyMap[entryName];
    if (key == null) continue;
    final clip = recording.slice(range.start, range.end).trimSilence();
    final path = 'clips/${key.replaceAll('.', '_')}.wav';
    await File('${outDir.path}/$path').writeAsBytes(encodeWav(clip));
    clips[key] = path;
  }

  final manifest = VoicePackManifest(
    id: id,
    name: name,
    language: language,
    credits: credits,
    clips: clips,
  );
  await File('${outDir.path}/${VoicePackManifest.fileName}').writeAsString(
    const JsonEncoder.withIndent('  ').convert(manifest.toJson()),
  );
  return manifest;
}
