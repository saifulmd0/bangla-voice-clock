import 'bangla_phrase_builder.dart';
import 'bangla_words.dart';
import 'speech_token.dart';

/// One line for a voice to record: the clip it becomes and what to say.
class ScriptLine {
  const ScriptLine(this.key, this.text);

  /// The clip key, which may name a phrase; see [ClipKeys.phrase].
  final String key;

  /// What the speaker says. Lines that end an announcement end with "।",
  /// so they're read with a falling, finished tone.
  final String text;

  @override
  String toString() => '$key: $text';
}

/// Everything a Bangla voice pack records, in recording order.
///
/// The single words let the pack say anything. The phrases (with [phrases])
/// make the common announcements sound natural:
///
/// * every quarter-hour announcement, whole ("এখন সময় সকাল সোয়া দশটা।");
/// * for exact times, the opening for each hour ("এখন সময় সকাল দশটা বেজে")
///   (also without বেজে: "এখন সময় সকাল দশটা", spoken to lead on) and the
///   ending for each minute ("সাত মিনিট।"), so any minute is two natural
///   takes joined, instead of six words.
List<ScriptLine> banglaVoiceScript({bool phrases = true}) {
  final builder = BanglaPhraseBuilder();
  final noBeje = BanglaPhraseBuilder(sayBeje: false);
  ScriptLine line(List<SpeechToken> tokens, {bool ends = false}) => ScriptLine(
    ClipKeys.phrase(tokens.map((t) => t.key)),
    ends ? '${tokens.text}।' : tokens.text,
  );

  return [
    const ScriptLine(ClipKeys.starter, starterWord),
    for (final zone in DayZone.values)
      ScriptLine(ClipKeys.zone(zone), zone.word),
    for (var h = 1; h <= 12; h++) ScriptLine(ClipKeys.hour(h), hourWords[h]),
    const ScriptLine(ClipKeys.sowa, sowaWord),
    const ScriptLine(ClipKeys.sare, sareWord),
    const ScriptLine(ClipKeys.poune, pouneWord),
    const ScriptLine(ClipKeys.der, derWord),
    const ScriptLine(ClipKeys.arai, araiWord),
    const ScriptLine(ClipKeys.beje, bejeWord),
    const ScriptLine(ClipKeys.minute, minuteWord),
    for (var n = 1; n <= 59; n++)
      ScriptLine(ClipKeys.number(n), numberWords[n]),
    if (phrases) ...[
      for (var h = 0; h < 24; h++)
        for (final m in const [0, 15, 30, 45])
          line(builder.build(h, m), ends: true),
      for (var h = 0; h < 24; h++)
        line(_exact(builder, h, 1).sublist(0, _exactOpeningLength)),
      for (var h = 0; h < 24; h++)
        line(_exact(noBeje, h, 1).sublist(0, _exactOpeningLength)),
      for (var m = 1; m <= 59; m++)
        line(_exact(builder, 0, m).sublist(_exactOpeningLength), ends: true),
    ],
  ];
}

List<SpeechToken> _exact(BanglaPhraseBuilder builder, int hour, int minute) =>
    builder.build(hour, minute, style: AnnouncementStyle.exact);

/// এখন সময় + zone + hour + বেজে (or its silent stand-in).
const _exactOpeningLength = 4;
