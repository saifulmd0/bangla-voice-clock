import '../core/clock/bangla_clock.dart';
import '../core/settings/app_settings.dart';
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
            ', ${hour(s.quietStartHour)} থেকে ${hour(s.quietEndHour)} নীরব',
            ', silent ${hour(s.quietStartHour)} to ${hour(s.quietEndHour)}',
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

  // Voice.
  String get voice => _t('কণ্ঠ', 'Voice');
  String voiceLabel(String name, String author) =>
      author.isEmpty ? name : '$name - by $author';
  String get volume => _t('শব্দের মাত্রা', 'Volume');
  String get chime => _t('ঘোষণার আগে ঘণ্টাধ্বনি', 'Chime before announcing');

  // Quiet hours.
  String get quietHours => _t('নীরব সময়', 'Quiet hours');
  String get quietHoursOn =>
      _t('এই সময়ে ঘোষণা হবে না', 'Stay silent during these hours');

  /// The words around the two hour pickers: "[from] … [to] … [until]".
  String get quietFrom => _t('', 'From');
  String get quietTo => _t('থেকে', 'to');
  String get quietUntil => _t('পর্যন্ত', '');
  String hour(int h) => _bn
      ? banglaClockWithZone(DateTime(2000, 1, 1, h))
      : _englishClock(DateTime(2000, 1, 1, h));

  // Other settings.
  String get other => _t('অন্যান্য', 'General');
  String get languageLabel => _t('ভাষা', 'Language');
  String get menuBar => _t('মেনু বার', 'Menu bar');
  String get menuBarShows => _t('মেনু বারে দেখান', 'Menu bar shows');
  String get menuBarTime => _t('সময়', 'Time');
  String get menuBarLogo => _t('লোগো', 'Logo');
  String get notify => _t('ঘোষণার সাথে নোটিফিকেশন', 'Show a notification');
  String get launchAtLogin =>
      _t('ম্যাক চালু হলে নিজে থেকে চালু হবে', 'Open at login');

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
      'Areeba AI (ElevenLabs) - by Saiful',
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
      bn ? 'বিনামূল্যের ওপেন সোর্স অ্যাপ।' : 'Free and open source.',
      url: developerUrl,
    ),
  ];
}

const developerUrl = 'https://github.com/saifulmd0';
const sourceUrl = 'https://github.com/saifulmd0/bangla-voice-clock';
