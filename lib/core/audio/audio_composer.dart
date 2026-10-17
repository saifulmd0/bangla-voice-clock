import 'dart:typed_data';

import 'pcm_audio.dart';

/// Joins spoken clips into a single buffer that plays as one sound.
///
/// Playing one buffer avoids the stutter of starting a new sound per word,
/// and the same buffer can later be saved as a notification sound on mobile.
class AudioComposer {
  const AudioComposer({
    this.gap = const Duration(milliseconds: 60),
    this.fade = const Duration(milliseconds: 5),
  });

  /// Silence inserted between consecutive clips.
  final Duration gap;

  /// Fade applied to both ends of every clip.
  final Duration fade;

  PcmAudio compose(List<PcmAudio> clips) {
    if (clips.isEmpty) throw ArgumentError.value(clips, 'clips', 'is empty');
    final rate = clips.first.sampleRate;
    for (final clip in clips) {
      if (clip.sampleRate != rate) {
        throw ArgumentError(
          'All clips must share one sample rate '
          '(found ${clip.sampleRate} Hz and $rate Hz)',
        );
      }
    }

    final silence = PcmAudio.silence(gap, rate);
    final parts = <PcmAudio>[
      for (var i = 0; i < clips.length; i++) ...[
        if (i > 0) silence,
        clips[i].withFades(fade),
      ],
    ];
    final out = Int16List(parts.fold(0, (n, p) => n + p.length));
    var at = 0;
    for (final part in parts) {
      out.setAll(at, part.samples);
      at += part.length;
    }
    return PcmAudio(out, rate);
  }
}
