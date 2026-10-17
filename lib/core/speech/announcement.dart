import 'bangla_phrase_builder.dart';
import 'speech_token.dart';
import 'voice_pack.dart';

/// The words to announce [time] with [pack], in [style] where possible.
///
/// Traditional style only covers quarter hours, so at other minutes (Speak
/// now at 10:07) the exact style is used instead. A pack that can't say
/// exact minutes (the classic voice) gives the quarter hour just passed.
List<SpeechToken> announcementFor(
  DateTime time,
  AnnouncementStyle style,
  VoicePack pack, {
  BanglaPhraseBuilder? builder,
}) {
  final b = builder ?? BanglaPhraseBuilder();
  final (h, m) = (time.hour, time.minute);
  if (style == AnnouncementStyle.traditional && m % 15 == 0) {
    return b.build(h, m);
  }
  final exact = b.build(h, m, style: AnnouncementStyle.exact);
  if (pack.canSpeak(exact)) return exact;
  return b.build(h, m - m % 15);
}
