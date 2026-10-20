<p align="center">
  <img src="docs/brand/icon.png" width="128" alt="Bangla Voice Clock icon: a clock face of twelve blue dots with a coral dot at twelve">
</p>

<h1 align="center">Bangla Voice Clock</h1>

<p align="center">
  <b>বাংলা ভয়েস ক্লক</b><br>
  A free talking clock that tells the time aloud in Bangla, the way it is said in Bangladesh.
</p>

<p align="center">
  <a href="https://github.com/saifulmd0/bangla-voice-clock/releases"><img alt="Latest version" src="https://img.shields.io/github/v/release/saifulmd0/bangla-voice-clock?include_prereleases&label=version&color=2F74D0"></a>
  <a href="https://github.com/saifulmd0/bangla-voice-clock/releases"><img alt="Downloads" src="https://img.shields.io/github/downloads/saifulmd0/bangla-voice-clock/total?color=2F74D0"></a>
  <img alt="macOS 12 or later, Windows 10 or later" src="https://img.shields.io/badge/platforms-macOS%2012%2B%20%7C%20Windows%2010%2B-2F74D0">
  <img alt="Free" src="https://img.shields.io/badge/price-free-FF8A65">
  <a href="https://github.com/saifulmd0/bangla-voice-clock/actions/workflows/ci.yml"><img alt="Build" src="https://github.com/saifulmd0/bangla-voice-clock/actions/workflows/ci.yml/badge.svg"></a>
</p>

<p align="center">
  <a href="https://github.com/saifulmd0/bangla-voice-clock/releases"><img alt="Download for macOS" src="https://img.shields.io/badge/Download-macOS-2F74D0?style=for-the-badge&logo=apple&logoColor=white"></a>
  <a href="https://github.com/saifulmd0/bangla-voice-clock/releases"><img alt="Download for Windows" src="https://img.shields.io/badge/Download-Windows-2F74D0?style=for-the-badge&logo=windows&logoColor=white"></a>
</p>

<p align="center">
  <a href="docs/media/demo.mp4"><img src="docs/media/demo.gif" width="800" alt="Demo: the clock's window with its dial of the day, speaking the time, the two voices, dark mode in English, quiet hours and the timer"></a><br>
  <a href="docs/media/demo.mp4"><b>▶ Watch the demo with sound</b></a> (30 seconds, with the app's real voices)
</p>

> **এখন সময় সকাল দশটা বেজে বিশ মিনিট।**<br>
> Every 15, 30 or 60 minutes, from the menu bar on a Mac or the system tray on Windows.

## Contents

- [Features](#features)
- [Screenshots](#screenshots)
- [Install](#install): [macOS](#macos) · [Windows](#windows) · [Updating](#updating) · [Uninstalling](#uninstalling)
- [Using it](#using-it)
- [FAQ](#faq)
- [Privacy](#privacy)
- [Credits](#credits)
- [Development](#development)

## Features

- **Speaks Bangla the Bangladeshi way.** The part of the day (ভোর, সকাল, দুপুর, বিকাল, সন্ধ্যা,
  রাত), the exact minute ("দশটা বেজে সাত মিনিট", with or without বেজে) or the traditional
  quarters (সোয়া, সাড়ে, পৌনে). Whole recorded phrases, not robotic stitched words.
- **Two voices.** *Areeba AI*, a soft voice with a Bangladeshi accent made with ElevenLabs, and
  *Classic (1998)*, the voice of the original Bangla Voice Clock, used with permission.
- **On your schedule.** Every 15, 30 or 60 minutes, with an optional chime and notification,
  and quiet hours set to the minute.
- **A talking timer.** Up to three hours. It says the time left every minute ("আর দশ মিনিট
  বাকি") and "সময় শেষ" at the end.
- **Plays where you want.** The system default, the built-in speakers, headphones or any other
  output.
- **Stays out of the way.** It lives in the macOS menu bar (time, icon or both) or the Windows
  system tray, opens at login, and has no Dock or taskbar window.
- **Bangla or English window**, in light or dark, with today's schedule drawn as a dial of dots.
- **Free, with no ads and no account.** Announcements work offline. It checks GitHub once a
  day for a new version, and you can turn that off.

## Screenshots

| | |
|---|---|
| ![The clock speaking: the now dot glows on the dial](docs/media/scene-2-speak.png) | ![The two voices as option cards](docs/media/scene-3-voices.png) |
| ![The window in English and dark mode](docs/media/scene-4-dark.png) | ![Choosing a quiet hours time: hours in a list, minutes in a grid](docs/media/scene-5-quiet.png) |
| ![The timer counting down from ten minutes](docs/media/scene-6-timer.png) | ![The clock tab with the dial of the day](docs/media/scene-1-clock.png) |

## Install

Get the latest version from **[Releases](https://github.com/saifulmd0/bangla-voice-clock/releases)**.
Each release has a file for each system:

| File | For |
|---|---|
| `BanglaVoiceClock-…-macos.dmg` | macOS 12 Monterey or later, Apple Silicon and Intel |
| `BanglaVoiceClock-…-windows-setup.exe` | Windows 10 or 11, 64-bit (recommended) |
| `BanglaVoiceClock-…-windows-portable.zip` | Windows, without installing |

The apps are not code-signed yet, so macOS and Windows warn the first time. The steps below get
past that.

### macOS

**With [Homebrew](https://brew.sh)** (the easiest, and it skips the security warning):

```sh
brew install --cask saifulmd0/tap/bangla-voice-clock
```

**Or with the disk image:**

1. Download `BanglaVoiceClock-…-macos.dmg` and open it.
2. Drag **Bangla Voice Clock** onto **Applications**.
3. Open it from Applications. If macOS says it can't check the app, open **System Settings →
   Privacy & Security**, scroll down and choose **Open Anyway**. (On macOS 14 or older,
   right-click the app and choose **Open**.) You only do this once.
4. The time appears in the menu bar, and the settings window opens.

### Windows

1. Download `BanglaVoiceClock-…-windows-setup.exe` and run it.
2. If SmartScreen says "Windows protected your PC", choose **More info → Run anyway**.
3. Choose whether it starts when you sign in and whether to add a desktop shortcut (both are
   ticked), then **Install**. It installs for your account only, with no administrator prompt.
4. The clock icon appears in the system tray (in the **^** overflow at first; drag it onto the
   taskbar to keep it in view). Click it for the menu.

Prefer not to install? Unzip `BanglaVoiceClock-…-windows-portable.zip` anywhere and run
`BanglaVoiceClock.exe`.

### Updating

Once a day the clock looks for a new version and, when there is one, shows what changed.

- **Windows (installed with the setup):** choose **Update now**. It downloads the new version,
  checks it, installs it and reopens the clock, keeping your settings.
- **macOS:** run `brew upgrade --cask bangla-voice-clock`, or choose **Open download page** and
  install the new disk image over the old app.
- **Windows portable:** download the new zip and replace the old folder.

You can also choose **Check for update now** under **General** (অন্যান্য) in the window.

### Uninstalling

- **macOS:** quit it from its menu, then move the app from Applications to the Trash, or run
  `brew uninstall --cask bangla-voice-clock` (add `--zap` to remove its settings too).
- **Windows:** **Settings → Apps → Installed apps → Bangla Voice Clock → Uninstall**. For the
  portable copy, quit it from the tray and delete the folder.

## Using it

Click the time in the menu bar (or the tray icon on Windows) for the menu:

- **এখনই সময় শুনুন** (Speak the time now)
- **ঘোষণা বন্ধ** (Mute), and **কতক্ষণ পরপর** (Every) 15 minutes, 30 minutes or 1 hour
- **সেটিংস…** (Settings…), **কৃতজ্ঞতা…** (Credits…) and **বন্ধ করুন** (Quit)

The window has two tabs:

- **ঘড়ি (Clock):** the dial of the day, then the look (light, dark or matching the system;
  what the menu bar shows), announcements (on or off, how often, by the minute or traditional,
  বেজে), voice, volume, chime, the output device, quiet hours, the language, notifications,
  opening at login and update checks.
- **টাইমার (Timer):** pick the minutes and start; it speaks the time left every minute.

## FAQ

**Does it need the internet?**
No. Announcements and the timer work offline. The only connection is a once-a-day check of this
project's GitHub releases, which you can turn off under General ("নতুন সংস্করণ এলে জানান").

**I hear nothing.**
Choose **এখনই সময় শুনুন** (Speak the time now). If that is silent, check the volume slider and
**কোথায় বাজবে** (Play through) under Voice, and that the system volume is up. If only the
scheduled announcements are missing, check that announcements are on, not muted from the menu,
and not inside your quiet hours.

**Why does macOS or Windows warn about the app?**
The builds are not signed with a paid Apple or Microsoft developer certificate yet. The app is
built from this repository's source by [GitHub Actions](https://github.com/saifulmd0/bangla-voice-clock/actions),
and the release page lists each file's SHA-256.

**Why does the classic voice not say every minute?**
The 1998 recordings only cover the quarter hours, so with that voice the clock speaks the
traditional way. Areeba AI says any minute.

**Where are my settings?**
macOS: `~/Library/Containers/com.projuktiteam.banglaVoiceClock/Data/Library/Application Support/Bangla Voice Clock/settings.json`.
Windows: `%APPDATA%\Bangla Voice Clock\settings.json`. Updates keep them.

**Is there a Linux, Android or iPhone version?**
Not yet. A mobile app for blind and low-literacy users is planned.

**Found a bug or have an idea?**
[Open an issue](https://github.com/saifulmd0/bangla-voice-clock/issues).

## Privacy

The app has no accounts, ads, analytics or tracking. Your settings stay on your computer. The
update check asks GitHub for the list of releases; GitHub sees the app's version and your IP
address, as with any web request, and nothing else is sent.

## Credits

- The original **Bangla Voice Clock** for Windows (1998–2002) by **Q A M Khaled Ferdaus**, of
  which this app is the successor.
- **Classic (1998)** voice by **Moshfekah Ferdaus Mahita**, from the original app, used with
  permission.
- **Areeba AI** voice by Saiful Islam, designed and generated with [ElevenLabs](https://elevenlabs.io).
- [Schedule Voice Clock](https://github.com/HridoyVaraby/schedule-voice-clock) by Hridoy
  Varaby, which inspired recording whole phrases.
- Built with [Flutter](https://flutter.dev); [Hind Siliguri](https://fonts.google.com/specimen/Hind+Siliguri) for the text.

Developed by **[Saiful Islam](https://github.com/saifulmd0)**.

## Development

Requires [Flutter](https://flutter.dev) 3.47.

```sh
flutter pub get
flutter test      # runs without Xcode
flutter analyze
```

Building and running the apps locally needs Xcode (macOS) or Visual Studio (Windows).
Without them, push to GitHub and let CI build both.

### Hearing the announcement engine

The engine runs from the command line, without the app:

```sh
# Speak a time (24-hour) with a voice pack folder; macOS plays it with afplay
dart run tool/speak.dart --pack assets/voices/bn_classic --time 10:15
dart run tool/speak.dart --pack assets/voices/bn_ai --time 21:27 --exact

# Convert a voice made for the original Windows app (VClock.def + vclock.wav)
dart run tool/import_legacy_voice.dart VClock.def vclock.wav <out-dir>
```

### Voices

| Pack | Voice |
|---|---|
| `bn_classic` | Moshfekah Ferdaus Mahita, from the original Bangla Voice Clock (1998). Used with permission. |
| `bn_ai` | A soft, cute young woman with a Bangladeshi accent, an AI voice designed with [ElevenLabs](https://elevenlabs.io). See [docs/VOICES.md](docs/VOICES.md). |

A pack records single words, which can say any time, plus whole phrases, which sound more
natural and are used whenever they match. `lib/core/speech/voice_script.dart` lists every line.

To make an AI pack, put `ELEVENLABS_API_KEY=...` in a `.env` file (git ignores it), then:

```sh
dart run tool/elevenlabs.dart design          # three preview voices to listen to
dart run tool/elevenlabs.dart save --id <generated_voice_id>
dart run tool/elevenlabs.dart generate --voice <voice_id> --out assets/voices/bn_ai
dart run tool/elevenlabs.dart check --pack assets/voices/bn_ai   # speech-to-text check
dart run tool/review_pack.dart --pack assets/voices/bn_ai        # long files to listen through
```

Add `--dry-run` to `generate` to list the lines and character count without calling the API.
Packs built from material we can't redistribute go in `voices_local/`, which git ignores.
