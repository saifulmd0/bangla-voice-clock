import 'dart:math' as math;
import 'dart:typed_data';

import 'pcm_audio.dart';

/// A soft two-note bell ("ding-dong") played before an announcement.
///
/// Synthesised rather than recorded, so it matches any voice pack's sample
/// rate and needs no sound file.
PcmAudio chime(int sampleRate) {
  const noteSeconds = 0.9;
  const overlapSeconds = 0.35;
  // E5 then C5, each with a quieter octave overtone for a bell-like tone.
  const notes = [659.25, 523.25];
  final noteFrames = (noteSeconds * sampleRate).round();
  final step = ((noteSeconds - overlapSeconds) * sampleRate).round();
  final out = Float64List(step * (notes.length - 1) + noteFrames);
  for (final (n, freq) in notes.indexed) {
    for (var i = 0; i < noteFrames; i++) {
      final t = i / sampleRate;
      final attack = math.min(1.0, t / 0.005);
      final decay = math.exp(-t * 4.5);
      final tone =
          math.sin(2 * math.pi * freq * t) +
          0.3 * math.sin(2 * math.pi * 2 * freq * t) * math.exp(-t * 3);
      out[n * step + i] += tone * attack * decay;
    }
  }
  const level = 0.25 * 32767 / 1.3;
  return PcmAudio(
    Int16List.fromList([for (final s in out) (s * level).round()]),
    sampleRate,
  );
}
