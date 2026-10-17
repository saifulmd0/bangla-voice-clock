import 'dart:typed_data';

import 'pcm_audio.dart';

/// Thrown when bytes are not a WAV file this app can read.
class WavFormatException implements Exception {
  WavFormatException(this.message);

  final String message;

  @override
  String toString() => 'WavFormatException: $message';
}

const _formatPcm = 1;
const _formatExtensible = 0xFFFE;

/// Decodes an uncompressed PCM WAV file (8 or 16 bit, any channel count).
///
/// Multi-channel audio is mixed down to mono.
PcmAudio decodeWav(Uint8List bytes) {
  final data = ByteData.sublistView(bytes);
  if (bytes.length < 12 ||
      _fourCc(data, 0) != 'RIFF' ||
      _fourCc(data, 8) != 'WAVE') {
    throw WavFormatException('not a RIFF/WAVE file');
  }

  int? format, channels, sampleRate, bitsPerSample;
  ByteData? pcm;

  var offset = 12;
  while (offset + 8 <= bytes.length) {
    final id = _fourCc(data, offset);
    final size = data.getUint32(offset + 4, Endian.little);
    final body = offset + 8;
    final end = body + size;
    if (end > bytes.length) {
      // Some writers leave a wrong size on the last chunk; read what exists.
      if (id != 'data') throw WavFormatException('truncated "$id" chunk');
    }
    if (id == 'fmt ') {
      format = data.getUint16(body, Endian.little);
      channels = data.getUint16(body + 2, Endian.little);
      sampleRate = data.getUint32(body + 4, Endian.little);
      bitsPerSample = data.getUint16(body + 14, Endian.little);
    } else if (id == 'data') {
      final available = (end > bytes.length ? bytes.length : end) - body;
      pcm = ByteData.sublistView(bytes, body, body + available);
    }
    offset = end + (size.isOdd ? 1 : 0);
  }

  if (format == null || channels == null || sampleRate == null) {
    throw WavFormatException('missing "fmt " chunk');
  }
  if (pcm == null) throw WavFormatException('missing "data" chunk');
  if (format != _formatPcm && format != _formatExtensible) {
    throw WavFormatException('only uncompressed PCM is supported');
  }
  if (bitsPerSample != 8 && bitsPerSample != 16) {
    throw WavFormatException('unsupported bit depth: $bitsPerSample');
  }
  if (channels < 1) throw WavFormatException('no audio channels');

  final bytesPerSample = bitsPerSample! ~/ 8;
  final frames = pcm.lengthInBytes ~/ (bytesPerSample * channels);
  final out = Int16List(frames);
  for (var f = 0; f < frames; f++) {
    var sum = 0;
    for (var c = 0; c < channels; c++) {
      final at = (f * channels + c) * bytesPerSample;
      // 8-bit WAV samples are unsigned, centred on 128.
      sum += bytesPerSample == 1
          ? (pcm.getUint8(at) - 128) << 8
          : pcm.getInt16(at, Endian.little);
    }
    out[f] = sum ~/ channels;
  }
  return PcmAudio(out, sampleRate);
}

/// Encodes [audio] as a mono 16-bit PCM WAV file.
Uint8List encodeWav(PcmAudio audio) {
  final dataSize = audio.length * 2;
  final data = ByteData(44 + dataSize);
  void fourCc(int at, String s) {
    for (var i = 0; i < 4; i++) {
      data.setUint8(at + i, s.codeUnitAt(i));
    }
  }

  fourCc(0, 'RIFF');
  data.setUint32(4, 36 + dataSize, Endian.little);
  fourCc(8, 'WAVE');
  fourCc(12, 'fmt ');
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, _formatPcm, Endian.little);
  data.setUint16(22, 1, Endian.little); // mono
  data.setUint32(24, audio.sampleRate, Endian.little);
  data.setUint32(28, audio.sampleRate * 2, Endian.little); // byte rate
  data.setUint16(32, 2, Endian.little); // block align
  data.setUint16(34, 16, Endian.little); // bits per sample
  fourCc(36, 'data');
  data.setUint32(40, dataSize, Endian.little);
  for (var i = 0; i < audio.length; i++) {
    data.setInt16(44 + i * 2, audio.samples[i], Endian.little);
  }
  return data.buffer.asUint8List();
}

String _fourCc(ByteData data, int offset) => String.fromCharCodes([
  for (var i = 0; i < 4; i++) data.getUint8(offset + i),
]);
