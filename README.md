# Bangla Voice Clock

A free talking clock that announces the time in Bangla. macOS first, other platforms later.

Inspired by the original *Bangla Voice Clock* for Windows (1998–2002) by Q A M Khaled Ferdaus,
and by [Schedule Voice Clock](https://github.com/HridoyVaraby/schedule-voice-clock) for Ubuntu.

> **Status:** early development. See [docs/PLAN.md](docs/PLAN.md) for the full plan.

## Download (development builds)

Every push to `main` builds the macOS app on GitHub Actions.

1. Open the [Actions tab](../../actions), pick the latest successful **CI** run.
2. Download **BanglaVoiceClock-macos** from the Artifacts section and unzip it.
3. These builds are not signed yet. The first time, right-click **Bangla Voice Clock** and
   choose **Open**.

The clock lives in the menu bar (there's no Dock icon). Click the time there to hear it now,
mute it, change how often it speaks, or open the settings: voice, traditional (সোয়া/সাড়ে/পৌনে)
or exact-minute wording, volume, chime, quiet hours and launch at login.

## Development

Requires [Flutter](https://flutter.dev) 3.47.

```sh
flutter pub get
flutter test      # runs without Xcode
flutter analyze
```

Building and running the macOS app locally (`flutter run -d macos`) also needs Xcode.
Without Xcode, push to GitHub and let CI build it.

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
