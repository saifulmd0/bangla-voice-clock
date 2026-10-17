import 'bangla_phrase_builder.dart';
import 'speech_token.dart';
import 'voice_pack.dart';

/// The words to announce [time] with [pack], in [style] where possible.
///
/// Traditional style only covers quarter hours, so at other minutes (Speak
/// now at 10:07) the exact style is used instead. When the pack can't say
/// [time] either way, it falls back to the quarter hour just passed, in
/// whichever style the pack can say (the classic voice only has
/// "পনেরো মিনিট", "ত্রিশ মিনিট" and "পঁয়তাল্লিশ মিনিট").
List<SpeechToken> announcementFor(
  DateTime time,
  AnnouncementStyle style,
  VoicePack pack, {
  BanglaPhraseBuilder? builder,
}) {
  final b = builder ?? BanglaPhraseBuilder();
  final (h, m) = (time.hour, time.minute);
  final other = style == AnnouncementStyle.traditional
      ? AnnouncementStyle.exact
      : AnnouncementStyle.traditional;
  final candidates = [
    for (final minute in {m, m - m % 15})
      for (final s in [style, other])
        if (BanglaPhraseBuilder.supports(s, minute))
          b.build(h, minute, style: s),
  ];
  return candidates.firstWhere(pack.canSpeak, orElse: () => candidates.last);
}
