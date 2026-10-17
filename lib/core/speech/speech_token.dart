/// One spoken unit of an announcement, such as "সকাল" or "দশটা".
///
/// [key] names the voice-pack clip that speaks it. When a pack lacks that
/// clip, [fallback] lists other clips that say the same thing in more words
/// (for example "সাড়ে একটা" instead of "দেড়টা"). An [optional] token is
/// left unspoken by a pack without it (the classic voice has no "বেজে").
class SpeechToken {
  const SpeechToken(
    this.key,
    this.text, {
    this.fallback = const [],
    this.optional = false,
  });

  final String key;
  final String text;
  final List<String> fallback;
  final bool optional;

  @override
  bool operator ==(Object other) =>
      other is SpeechToken && other.key == key && other.text == text;

  @override
  int get hashCode => Object.hash(key, text);

  @override
  String toString() => 'SpeechToken($key, $text)';
}

extension SpeechTokenText on List<SpeechToken> {
  /// The announcement as Bangla text, for display and tests.
  String get text => map((t) => t.text).join(' ');
}
