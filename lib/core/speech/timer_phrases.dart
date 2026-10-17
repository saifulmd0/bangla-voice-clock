import 'bangla_words.dart';
import 'speech_token.dart';

/// The longest timer the voice packs can count down, in minutes.
const maxTimerMinutes = 180;

/// What a countdown says each minute: "আর দশ মিনিট বাকি", or with hours
/// "আর এক ঘণ্টা দশ মিনিট বাকি".
List<SpeechToken> timeLeftTokens(int minutes) {
  RangeError.checkValueInInterval(minutes, 1, maxTimerMinutes, 'minutes');
  final (h, m) = (minutes ~/ 60, minutes % 60);
  return [
    const SpeechToken(ClipKeys.timerAr, timerArWord),
    if (h > 0) SpeechToken(ClipKeys.timerHours(h), '${numberWords[h]} ঘণ্টা'),
    if (m > 0) ...[
      SpeechToken(ClipKeys.number(m), numberWords[m]),
      const SpeechToken(ClipKeys.minute, minuteWord),
    ],
    const SpeechToken(ClipKeys.timerLeft, timerLeftWord),
  ];
}

/// What a countdown says when it ends: "সময় শেষ".
const timerDoneTokens = [SpeechToken(ClipKeys.timerDone, timerDoneWords)];
