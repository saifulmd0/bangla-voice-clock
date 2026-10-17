import 'package:flutter/services.dart';

import '../core/speech/voice_pack.dart';

/// Reads a voice pack bundled with the app under [base].
class AssetClipSource implements ClipSource {
  AssetClipSource(this.base, [AssetBundle? bundle])
    : _bundle = bundle ?? rootBundle;

  final String base;
  final AssetBundle _bundle;

  @override
  Future<Uint8List> read(String path) async {
    final data = await _bundle.load('$base/$path');
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }
}
