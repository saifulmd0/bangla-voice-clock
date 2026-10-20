<p align="center"><img src="docs/brand/icon.png" width="128" alt="Bangla Voice Clock icon: a clock face of twelve blue dots with a coral dot at twelve"></p>

# Bangla Voice Clock

**বাংলা ভয়েস ক্লক.** A free talking clock that announces the time in Bangla. macOS first, other platforms later.

Inspired by the original *Bangla Voice Clock* for Windows (1998–2002) by Q A M Khaled Ferdaus,
and by [Schedule Voice Clock](https://github.com/HridoyVaraby/schedule-voice-clock) for Ubuntu.

> **Status:** early development. See [docs/PLAN.md](docs/PLAN.md) for the full plan.

## Download

Get the latest version from [Releases](../../releases). The builds are not signed yet:

- **macOS** (12 or later): open `BanglaVoiceClock-…-macos.dmg` and drag **Bangla Voice Clock**
  onto **Applications**. The first time, if macOS won't open it, go to **System Settings →
  Privacy & Security** and choose **Open Anyway** (on older macOS, right-click the app and
  choose **Open**).
- **Windows** (10 or later, 64-bit): run `BanglaVoiceClock-…-windows-setup.exe`. It installs for
  your account only, with no administrator prompt, adds a Start menu entry, and starts the clock
  when you sign in (untick that if you'd rather not). If SmartScreen warns, choose
  **More info → Run anyway**. Uninstall it from **Settings → Apps**. A portable zip is there too.

The clock lives in the macOS menu bar (time, icon or both) or the Windows system tray, with no
Dock or taskbar window. From its menu you can hear the time now, mute it, change how often it
speaks, or open the window, which has two tabs:

- **ঘড়ি (Clock):** voice, traditional (সোয়া/সাড়ে/পৌনে) or exact-minute wording (বেজে optional),
  volume, chime, quiet hours (to the minute), launch at login, light or dark look, and the interface language
  (বাংলা by default, or English). Today's schedule is drawn as a dial of dots; see
  [DESIGN.md](DESIGN.md) for the brand.
- **টাইমার (Timer):** up to three hours; it says the time left every minute ("আর দশ মিনিট বাকি")
  and "সময় শেষ" at the end.

Every push to `main` also builds both apps on GitHub Actions (the **CI** run's artifacts), and
pushing a `v*` tag publishes a release.

Developed by [Saiful Islam](https://github.com/saifulmd0).

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
