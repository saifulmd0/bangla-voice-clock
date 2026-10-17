import 'dart:typed_data';

import 'package:bangla_voice_clock/core/audio/audio_composer.dart';
import 'package:bangla_voice_clock/core/audio/pcm_audio.dart';
import 'package:bangla_voice_clock/core/audio/wav.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds a WAV file by hand, so decoding is checked against a known layout
/// rather than against our own encoder.
Uint8List rawWav({
  required int bits,
  required int channels,
  required int sampleRate,
  required List<int> frames,
  bool extraChunk = false,
}) {
  final bytesPerSample = bits ~/ 8;
  final data = BytesBuilder();
  for (final v in frames) {
    final b = ByteData(bytesPerSample);
    bits == 8 ? b.setUint8(0, v) : b.setInt16(0, v, Endian.little);
    data.add(b.buffer.asUint8List());
  }
  final pcm = data.toBytes();

  ByteData u32(int v) => ByteData(4)..setUint32(0, v, Endian.little);
  ByteData u16(int v) => ByteData(2)..setUint16(0, v, Endian.little);
  final fmt = BytesBuilder()
    ..add(u16(1).buffer.asUint8List())
    ..add(u16(channels).buffer.asUint8List())
    ..add(u32(sampleRate).buffer.asUint8List())
    ..add(u32(sampleRate * channels * bytesPerSample).buffer.asUint8List())
    ..add(u16(channels * bytesPerSample).buffer.asUint8List())
    ..add(u16(bits).buffer.asUint8List());

  final body = BytesBuilder()
    ..add('WAVE'.codeUnits)
    ..add('fmt '.codeUnits)
    ..add(u32(16).buffer.asUint8List())
    ..add(fmt.toBytes());
  if (extraChunk) {
    // An odd-sized chunk, which must be skipped along with its pad byte.
    body
      ..add('LIST'.codeUnits)
      ..add(u32(3).buffer.asUint8List())
      ..add([1, 2, 3, 0]);
  }
  body
    ..add('data'.codeUnits)
    ..add(u32(pcm.length).buffer.asUint8List())
    ..add(pcm);

  final content = body.toBytes();
  return (BytesBuilder()
        ..add('RIFF'.codeUnits)
        ..add(u32(content.length).buffer.asUint8List())
        ..add(content))
      .toBytes();
}

void main() {
  group('decodeWav', () {
    test('reads 16-bit mono', () {
      final audio = decodeWav(
        rawWav(
          bits: 16,
          channels: 1,
          sampleRate: 24000,
          frames: [0, 1000, -1000, 32767],
        ),
      );
      expect(audio.sampleRate, 24000);
      expect(audio.samples, [0, 1000, -1000, 32767]);
    });

    test('reads unsigned 8-bit as signed 16-bit', () {
      final audio = decodeWav(
        rawWav(bits: 8, channels: 1, sampleRate: 11025, frames: [128, 255, 0]),
      );
      expect(audio.sampleRate, 11025);
      expect(audio.samples, [0, 127 << 8, -128 << 8]);
    });

    test('mixes stereo down to mono', () {
      final audio = decodeWav(
        rawWav(
          bits: 16,
          channels: 2,
          sampleRate: 8000,
          frames: [100, 300, -200, 200],
        ),
      );
      expect(audio.samples, [200, 0]);
    });

    test('skips unknown chunks, including odd-sized ones', () {
      final audio = decodeWav(
        rawWav(
          bits: 16,
          channels: 1,
          sampleRate: 8000,
          frames: [7, 8],
          extraChunk: true,
        ),
      );
      expect(audio.samples, [7, 8]);
    });

    test('rejects non-WAV bytes', () {
      expect(
        () => decodeWav(Uint8List.fromList('not a wav file'.codeUnits)),
        throwsA(isA<WavFormatException>()),
      );
    });
  });

  test('encodeWav output decodes back to the same audio', () {
    final original = PcmAudio(
      Int16List.fromList([0, -5, 12000, -32768, 32767]),
      22050,
    );
    final bytes = encodeWav(original);
    expect(bytes.length, 44 + original.length * 2);
    final decoded = decodeWav(bytes);
    expect(decoded.sampleRate, 22050);
    expect(decoded.samples, original.samples);
  });

  group('PcmAudio', () {
    PcmAudio tone(int frames, int rate) =>
        PcmAudio(Int16List.fromList(List.filled(frames, 10000)), rate);

    test('trimSilence keeps the sound plus padding', () {
      const rate = 1000; // 10 frames per 10 ms window
      final samples = Int16List(1000)..fillRange(400, 500, 8000);
      final trimmed = PcmAudio(
        samples,
        rate,
      ).trimSilence(padding: const Duration(milliseconds: 20));
      expect(trimmed.length, 100 + 2 * 20);
      expect(trimmed.samples.first, 0);
      expect(trimmed.samples[20], 8000);
    });

    test('trimSilence ignores hiss and isolated clicks', () {
      const rate = 1000;
      // Hiss everywhere at ~10% of the speech level, plus a click at 100 ms.
      final samples = Int16List.fromList([
        for (var i = 0; i < 1000; i++) i.isEven ? 600 : -600,
      ]);
      samples.fillRange(100, 105, 9000);
      for (var i = 400; i < 500; i++) {
        samples[i] = i.isEven ? 6000 : -6000;
      }
      final trimmed = PcmAudio(
        samples,
        rate,
      ).trimSilence(padding: const Duration(milliseconds: 20));
      expect(trimmed.length, 100 + 2 * 20);
    });

    test('a low noise factor keeps a soft word ending', () {
      const rate = 1000;
      // Hiss at 300, a loud word, then a soft ending at about twice the hiss
      // (like the "-নিট" of মিনিট in the 1998 recording).
      final samples = Int16List.fromList([
        for (var i = 0; i < 1000; i++) i.isEven ? 300 : -300,
      ]);
      for (var i = 300; i < 500; i++) {
        samples[i] = i.isEven ? 6000 : -6000;
      }
      for (var i = 500; i < 700; i++) {
        samples[i] = i.isEven ? 650 : -650;
      }
      final audio = PcmAudio(samples, rate);
      const padding = Duration.zero;
      expect(audio.trimSilence(padding: padding).length, 200);
      expect(audio.trimSilence(noiseFactor: 1.6, padding: padding).length, 400);
    });

    test('trimSilence leaves pure silence untouched', () {
      final silent = PcmAudio(Int16List(500), 1000);
      expect(silent.trimSilence().length, 500);
    });

    test('normalized brings quiet and loud clips to the same level', () {
      PcmAudio square(int level) => PcmAudio(
        Int16List.fromList([
          for (var i = 0; i < 100; i++) i.isEven ? level : -level,
        ]),
        1000,
      );
      final quiet = square(500).normalized(rms: 0.25);
      final loud = square(20000).normalized(rms: 0.25);
      expect(quiet.samples.first, (0.25 * 32767).round());
      expect(loud.samples.first, quiet.samples.first);
    });

    test('normalized never clips the loudest sample', () {
      final spiky = PcmAudio(Int16List(100)..[50] = 1000, 1000).normalized();
      expect(spiky.samples[50], (0.95 * 32767).round());
    });

    test('withFades starts and ends at zero', () {
      final faded = tone(
        1000,
        1000,
      ).withFades(const Duration(milliseconds: 10));
      expect(faded.samples.first, 0);
      expect(faded.samples.last, 0);
      expect(faded.samples[500], 10000);
    });

    test('slice cuts by time', () {
      final audio = tone(1000, 1000);
      final part = audio.slice(
        const Duration(milliseconds: 100),
        const Duration(milliseconds: 350),
      );
      expect(part.length, 250);
    });
  });

  group('AudioComposer', () {
    test('joins clips with a gap between each', () {
      const composer = AudioComposer(
        gap: Duration(milliseconds: 50),
        fade: Duration.zero,
      );
      final a = PcmAudio(Int16List.fromList(List.filled(100, 1)), 1000);
      final b = PcmAudio(Int16List.fromList(List.filled(200, 2)), 1000);
      final out = composer.compose([a, b, a]);
      expect(out.length, 100 + 50 + 200 + 50 + 100);
      expect(out.samples[0], 1);
      expect(out.samples[120], 0); // in the gap
      expect(out.samples[150], 2);
    });

    test('rejects clips with different sample rates', () {
      final a = PcmAudio(Int16List(10), 11025);
      final b = PcmAudio(Int16List(10), 24000);
      expect(() => const AudioComposer().compose([a, b]), throwsArgumentError);
    });

    test('rejects an empty list', () {
      expect(() => const AudioComposer().compose([]), throwsArgumentError);
    });
  });
}
