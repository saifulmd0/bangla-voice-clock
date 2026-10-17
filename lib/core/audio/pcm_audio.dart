import 'dart:math' as math;
import 'dart:typed_data';

/// Mono 16-bit PCM audio held in memory.
///
/// Every clip in the app is converted to this form, whatever its original
/// WAV encoding, so clips can be joined and processed uniformly.
class PcmAudio {
  PcmAudio(this.samples, this.sampleRate) {
    if (sampleRate <= 0) {
      throw ArgumentError.value(sampleRate, 'sampleRate', 'must be positive');
    }
  }

  PcmAudio.silence(Duration duration, this.sampleRate)
    : samples = Int16List(_frames(duration, sampleRate));

  final Int16List samples;
  final int sampleRate;

  int get length => samples.length;

  Duration get duration =>
      Duration(microseconds: samples.length * 1000000 ~/ sampleRate);

  /// Returns a copy of the frames between [start] and [end].
  PcmAudio slice(Duration start, [Duration? end]) {
    final from = _frames(start, sampleRate).clamp(0, length);
    final to = end == null
        ? length
        : _frames(end, sampleRate).clamp(from, length);
    return PcmAudio(Int16List.fromList(samples.sublist(from, to)), sampleRate);
  }

  /// Trims leading and trailing silence, keeping [padding] on each side.
  ///
  /// A 10 ms window counts as sound when its mean amplitude exceeds both
  /// [threshold] times the loudest window and [noiseFactor] times the noise
  /// floor (the quietest fifth of the windows), so hiss in old recordings
  /// isn't mistaken for speech. Sound must last three windows in a row.
  /// Audio with no sound at all is returned unchanged.
  PcmAudio trimSilence({
    double threshold = 0.08,
    double noiseFactor = 3,
    Duration padding = const Duration(milliseconds: 40),
  }) {
    final window = math.max(1, sampleRate ~/ 100);
    final windows = (length / window).ceil();
    if (windows == 0) return this;

    final energy = List<double>.generate(windows, (w) {
      final from = w * window;
      final to = math.min(from + window, length);
      var sum = 0;
      for (var i = from; i < to; i++) {
        sum += samples[i].abs();
      }
      return sum / (to - from);
    });
    final peak = energy.reduce(math.max);
    if (peak == 0) return this;

    final sorted = [...energy]..sort();
    final noiseFloor = sorted[sorted.length ~/ 5];
    var cutoff = math.max(peak * threshold, noiseFloor * noiseFactor);
    if (cutoff >= peak) cutoff = peak * threshold;

    const minRun = 3;
    bool loud(int w) =>
        w + minRun <= windows &&
        energy.sublist(w, w + minRun).every((e) => e > cutoff);
    var first = List.generate(windows, (w) => w).indexWhere(loud);
    var last = List.generate(windows, (w) => w).lastIndexWhere(loud);
    if (first < 0) {
      // Only short bursts; fall back to any single loud window.
      first = energy.indexWhere((e) => e > cutoff);
      last = energy.lastIndexWhere((e) => e > cutoff);
    } else {
      last += minRun - 1;
    }

    final pad = _frames(padding, sampleRate);
    final from = math.max(0, first * window - pad);
    final to = math.min(length, (last + 1) * window + pad);
    return PcmAudio(Int16List.fromList(samples.sublist(from, to)), sampleRate);
  }

  /// Returns a copy scaled to an average (RMS) level of [rms], as a
  /// fraction of full scale, so clips recorded separately play equally loud.
  /// The gain is capped so no sample exceeds [maxPeak].
  PcmAudio normalized({double rms = 0.1, double maxPeak = 0.95}) {
    var sumSquares = 0.0;
    var peak = 0;
    for (final s in samples) {
      sumSquares += s * s;
      peak = math.max(peak, s.abs());
    }
    if (peak == 0) return this;
    final current = math.sqrt(sumSquares / length);
    final gain = math.min(rms * 32767 / current, maxPeak * 32767 / peak);
    return PcmAudio(
      Int16List.fromList([
        for (final s in samples) (s * gain).round().clamp(-32768, 32767),
      ]),
      sampleRate,
    );
  }

  /// Returns a copy with a linear fade applied to both ends, which avoids
  /// audible clicks where clips are joined.
  PcmAudio withFades(Duration fade) {
    final out = Int16List.fromList(samples);
    final n = math.min(_frames(fade, sampleRate), length ~/ 2);
    for (var i = 0; i < n; i++) {
      final gain = i / n;
      out[i] = (out[i] * gain).round();
      out[length - 1 - i] = (out[length - 1 - i] * gain).round();
    }
    return PcmAudio(out, sampleRate);
  }
}

int _frames(Duration duration, int sampleRate) =>
    duration.inMicroseconds * sampleRate ~/ 1000000;
