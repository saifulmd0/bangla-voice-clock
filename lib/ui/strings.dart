import '../app/host_os.dart';
import '../core/clock/bangla_clock.dart';
import '../core/settings/app_settings.dart';
import '../core/speech/bangla_phrase_builder.dart';
import '../core/speech/bangla_words.dart';

/// Every piece of interface text, in [language].
class Strings {
  const Strings(this.language);

  final AppLanguage language;

  bool get _bn => language == AppLanguage.bn;
  String _t(String bn, String en) => _bn ? bn : en;

  String get appName => _t('বাংলা ভয়েস ক্লক', 'Bangla Voice Clock');

  // Clock.
  String clock(DateTime time) =>
      _bn ? banglaClockWithZone(time) : _englishClock(time);
  String clockFace(DateTime time) =>
      _bn ? banglaClockFace(time) : _englishClock(time, withPeriod: false);
  String nextAnnouncement(DateTime? next) => next == null
      ? _t('ঘোষণা বন্ধ আছে', 'Announcements are off')
      : _t(
          'পরের ঘোষণা ${_together(clock(next))}',
          'Next announcement at ${_together(clock(next))}',
        );

  /// Keeps "সকাল ১০:৩০" on one line when the text wraps.
  static String _together(String text) => text.replaceAll(' ', '\u00A0');
  String get speakNow => _t('এখনই সময় শুনুন', 'Speak the time now');

  /// The part of the day, as the dial labels it.
  String zone(DayZone zone) => _bn
      ? zone.word
      : switch (zone) {
          DayZone.bhor => 'Dawn',
          DayZone.sokal => 'Morning',
          DayZone.dupur => 'Noon',
          DayZone.bikal => 'Afternoon',
          DayZone.sondha => 'Evening',
          DayZone.raat => 'Night',
        };

  /// What the dial shows, for VoiceOver.
  String dialSummary(AppSettings s) {
    final quiet = s.quietHoursEnabled
        ? _t(
            ', ${timeOfDay(s.quietStart)} থেকে ${timeOfDay(s.quietEnd)} নীরব',
            ', silent ${timeOfDay(s.quietStart)} to ${timeOfDay(s.quietEnd)}',
          )
        : '';
    return s.muted
        ? _t('আজকের ঘোষণা: বন্ধ', "Today's announcements: muted")
        : _t(
            'আজকের ঘোষণা: প্রতি ${interval(s.intervalMinutes)}$quiet',
            "Today's announcements: every ${interval(s.intervalMinutes)}$quiet",
          );
  }

  // Announcements.
  String get announcements => _t('ঘোষণা', 'Announcements');
  String get announceOn => _t('সময় ঘোষণা চালু', 'Announce the time');
  String get muteMenu => _t('ঘোষণা বন্ধ', 'Mute announcements');
  String get every => _t('কতক্ষণ পরপর', 'Every');
  String interval(int minutes) => minutes % 60 == 0
      ? _t('${banglaDigits(minutes ~/ 60)} ঘণ্টা', '${minutes ~/ 60} hour')
      : _t('${banglaDigits(minutes)} মিনিট', '$minutes minutes');
  String get traditional => _t('প্রচলিত', 'Traditional');
  String get exact => _t('মিনিট ধরে', 'By the minute');
  String get sayBeje => _t('"বেজে" বলুন', 'Say "বেজে"');
  String get sayBejeHint =>
      _t('যেমন: দশটা বেজে সাত মিনিট', 'As in: দশটা বেজে সাত মিনিট');
  String quarterOnlyVoice(String voice) => _t(
    '$voice শুধু ১৫ মিনিট পরপর সময় বলতে পারে, তাই "মিনিট ধরে" এই কণ্ঠে নেই।',
    '$voice can only say the quarter hours, so "By the minute" is not '
        'available with this voice.',
  );

  // Voice.
  String get voice => _t('কণ্ঠ', 'Voice');
  String voiceLabel(String name, String author) =>
      author.isEmpty ? name : '$name - by $author';
  String get volume => _t('শব্দের মাত্রা', 'Volume');
  String get chime => _t('ঘোষণার আগে ঘণ্টাধ্বনি', 'Chime before announcing');
  String get output => _t('কোথায় বাজবে', 'Play through');
  String get systemOutput => _t('সিস্টেমের ডিফল্ট', 'System default');
  String notConnected(String device) =>
      _t('$device (সংযুক্ত নেই)', '$device (not connected)');
  String get outputHint => _t(
    'বেছে নেওয়া ডিভাইস সংযুক্ত না থাকলে সিস্টেমের ডিফল্টে বাজবে।',
    'If the chosen device is not connected, the system default plays instead.',
  );

  // Quiet hours.
  String get quietHours => _t('নীরব সময়', 'Quiet hours');
  String get quietHoursOn =>
      _t('এই সময়ে ঘোষণা হবে না', 'Stay silent during these hours');

  /// The words around the two time pickers: "[from] … [to] … [until]".
  String get quietFrom => _t('', 'From');
  String get quietTo => _t('থেকে', 'to');
  String get quietUntil => _t('পর্যন্ত', '');
  String get hourHeading => _t('ঘণ্টা', 'Hour');
  String get minuteHeading => _t('মিনিট', 'Minute');

  /// A time of day given in minutes from midnight: "রাত ১১:৩০".
  String timeOfDay(int minutes) =>
      clock(DateTime(2000, 1, 1, minutes ~/ 60, minutes % 60));

  /// An hour in the time picker: "রাত ১১টা", "11 PM".
  String hourOfDay(int h) {
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return _bn
        ? '${DayZones.standard.forHour(h).word} ${banglaDigits(h12)}টা'
        : '$h12 ${h < 12 ? 'AM' : 'PM'}';
  }

  /// A minute in the time picker: ":০৫".
  String minuteOfHour(int m) => _t(
    ':${banglaDigits(m.toString().padLeft(2, '0'))}',
    ':${m.toString().padLeft(2, '0')}',
  );

  // Other settings.
  String get other => _t('অন্যান্য', 'General');
  String get languageLabel => _t('ভাষা', 'Language');
  String get menuBar => _t('মেনু বার', 'Menu bar');
  String get look => _t('চেহারা', 'Look');
  String get appearance => _t('রং', 'Appearance');
  String get appearanceSystem => switch (hostOs) {
    HostOs.windows => _t('উইন্ডোজের মতো', 'Match Windows'),
    HostOs.macos => _t('ম্যাকের মতো', 'Match Mac'),
    HostOs.linux => _t('সিস্টেমের মতো', 'Match system'),
  };
  String get appearanceLight => _t('হালকা', 'Light');
  String get appearanceDark => _t('গাঢ়', 'Dark');
  String get menuBarShows => _t('মেনু বারে দেখান', 'Menu bar shows');
  String get menuBarTime => _t('সময়', 'Time');
  String get menuBarLogo => _t('আইকন', 'Icon');
  String get menuBarBoth => _t('আইকন + সময়', 'Icon + Time');
  String get notify => _t('ঘোষণার সাথে নোটিফিকেশন', 'Show a notification');
  String get launchAtLogin =>
      _t('কম্পিউটার চালু হলে নিজে থেকে চালু হবে', 'Open at login');

  // Updates.
  String get checkUpdates =>
      _t('নতুন সংস্করণ এলে জানান', 'Tell me about new versions');
  String version(String v) => _t('সংস্করণ ${banglaDigits(v)}', 'Version $v');
  String get checkNow => _t('এখনই আপডেট খুঁজুন', 'Check for update now');
  String get upToDate =>
      _t('এটিই সর্বশেষ সংস্করণ।', "You're on the latest version.");
  String get checkFailed => _t(
    'নতুন সংস্করণ খোঁজা গেল না। ইন্টারনেট সংযোগ দেখে আবার চেষ্টা করুন।',
    "Couldn't check for a new version. Check the internet connection and "
        'try again.',
  );
  String get updateTitle => _t('নতুন সংস্করণ এসেছে', 'A new version is out');
  String updateBody(String next, String current) => _t(
    'সংস্করণ ${banglaDigits(next)} এসেছে, আপনার আছে ${banglaDigits(current)}।',
    'Version $next is out; you have $current.',
  );
  String get updateNow => _t('এখনই আপডেট করুন', 'Update now');
  String get openDownload => _t('ডাউনলোড পেজ খুলুন', 'Open download page');
  String get later => _t('পরে', 'Later');
  String get skipVersion => _t('এটি বাদ দিন', 'Skip this version');
  String get downloading => _t('ডাউনলোড হচ্ছে…', 'Downloading…');
  String get updateFailed => _t(
    'আপডেট করা গেল না। ডাউনলোড পেজ থেকে নতুন সংস্করণ নামিয়ে নিন।',
    "The update didn't work. Get the new version from the download page "
        'instead.',
  );
  String get brewHint => _t(
    'Homebrew দিয়ে ইনস্টল করে থাকলে টার্মিনালে লিখুন:',
    'Installed with Homebrew? Run this in Terminal:',
  );

  // Tabs and timer.
  String get clockTab => _t('ঘড়ি', 'Clock');
  String get timerTab => _t('টাইমার', 'Timer');
  String minutes(int n) => _t('${banglaDigits(n)} মিনিট', '$n min');
  String get startTimer => _t('শুরু করুন', 'Start');
  String get stopTimer => _t('টাইমার বন্ধ করুন', 'Stop timer');
  String get timerHint => _t(
    'চলার সময় প্রতি মিনিটে বাকি সময় বলে দেবে, শেষে বলবে "সময় শেষ"।',
    'While it runs, it says the time left every minute, then "সময় শেষ" '
        '(time is up) at the end.',
  );
  String timerClassic(String voice) => _t(
    '$voice বাকি সময় বলতে পারে না, তাই প্রতি মিনিটে এখনকার সময় বলবে।',
    "$voice can't say the time left, so it says the current time every "
        'minute instead.',
  );
  String timerLeftMenu(int minutes) => _t(
    'টাইমার: আর ${banglaDigits(minutes)} মিনিট বাকি',
    'Timer: $minutes min left',
  );
  String get timerReady => _t('কত মিনিটের টাইমার?', 'How many minutes?');
  String countdownFace(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final sec = d.inSeconds % 60;
    String two(int v) => v.toString().padLeft(2, '0');
    final face = h > 0 ? '$h:${two(m)}:${two(sec)}' : '${two(m)}:${two(sec)}';
    return _bn ? banglaDigits(face) : face;
  }

  // Menu.
  String get settings => _t('সেটিংস…', 'Settings…');
  String get quit => _t('বন্ধ করুন', 'Quit');

  // About.
  String get developedBy =>
      _t('ডেভেলপ করেছেন সাইফুল ইসলাম', 'Developed by Saiful Islam');
  String get credits => _t('কৃতজ্ঞতা', 'Credits');
  String get creditsMenu => _t('কৃতজ্ঞতা…', 'Credits…');
  String get back => _t('ফিরে যান', 'Back');
  String get close => _t('বন্ধ', 'Close');

  static String _englishClock(DateTime t, {bool withPeriod = true}) {
    final h12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final face = '$h12:${t.minute.toString().padLeft(2, '0')}';
    return withPeriod ? '$face ${t.hour < 12 ? 'AM' : 'PM'}' : face;
  }
}

/// One entry in the credits window.
class Credit {
  const Credit(this.title, this.detail, {this.url});

  final String title;
  final String detail;
  final String? url;
}

/// Everyone the app owes, in [Strings.language].
List<Credit> creditsFor(Strings s) {
  final bn = s.language == AppLanguage.bn;
  return [
    Credit(
      bn
          ? 'মূল বাংলা ভয়েস ক্লক (১৯৯৮–২০০২)'
          : 'The original Bangla Voice Clock (1998–2002)',
      bn
          ? 'উইন্ডোজের জন্য তৈরি করেছিলেন কিউ এ এম খালেদ ফেরদৌস। এই অ্যাপ তারই উত্তরসূরি।'
          : 'Made for Windows by Q A M Khaled Ferdaus. This app is its successor.',
    ),
    Credit(
      'Classic (1998) - by Moshfekah Ferdaus Mahita',
      bn
          ? 'মূল অ্যাপের কণ্ঠ, অনুমতি নিয়ে ব্যবহৃত।'
          : 'The voice of the original app, used with permission.',
    ),
    Credit(
      'Areeba AI (ElevenLabs) - by Saiful Islam',
      bn ? 'বাংলাদেশি উচ্চারণের কণ্ঠ, ElevenLabs দিয়ে ডিজাইন ও তৈরি।' : 'A voice with a Bangladeshi accent, designed and generated with ElevenLabs.',
      url: 'https://elevenlabs.io',
    ),
    Credit(
      'Schedule Voice Clock',
      bn
          ? 'হৃদয় ভারাবির উবুন্টু অ্যাপ (MIT), যা থেকে পুরো বাক্য রেকর্ড করার ধারণা এসেছে।'
          : 'Ubuntu app by Hridoy Varaby (MIT), which inspired recording whole phrases.',
      url: 'https://github.com/HridoyVaraby/schedule-voice-clock',
    ),
    Credit(
      'Flutter',
      bn
          ? 'যে ফ্রেমওয়ার্কে অ্যাপটি তৈরি।'
          : 'The framework the app is built with.',
      url: 'https://flutter.dev',
    ),
    Credit(
      bn ? 'ডেভেলপার: সাইফুল ইসলাম' : 'Developed by Saiful Islam',
      bn
          ? 'বিনামূল্যের ওপেন সোর্স অ্যাপ, GPL-3.0 লাইসেন্সে।'
          : 'Free and open source, under the GPL-3.0.',
      url: developerUrl,
    ),
  ];
}

const developerUrl = 'https://github.com/saifulmd0';
const sourceUrl = 'https://github.com/saifulmd0/bangla-voice-clock';
