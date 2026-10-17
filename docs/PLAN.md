# Bangla Voice Clock: Rebuild Plan

Status: **Draft for review**, 2026-10-17
Target: v1 = macOS menu-bar app, Bangla voice. Later: Windows, Linux, Android, iOS.

---

## 1. What the reference app does (study of `Reference/`)

The original is **Bangla Voice Clock v3.26** (1998–2002) by Q A M Khaled Ferdaus. It's a C++/MFC
Windows tray app (`VClock.exe`, 380 KB) that stores data in an MS Access/Jet database (`bvcdb.mdb`).
It plays audio with the Windows MCI API.

### 1.1 How the talking clock works

The core idea is simple and good. **One WAV file holds every spoken fragment, plus a definition
file that maps each fragment to a millisecond range.**

- `vclock.wav`: 45.8 s, 8-bit mono, 11 kHz. Holds Bangla and English fragments back to back.
- `VClock.def`: a hand-parsed text format with one block per language (`Bangla { ... }`, `English { ... }`):

| Key | Meaning | Bangla | English |
|---|---|---|---|
| `starter` | "এখন সময় হলো" / "It is now" | ✔ | ✔ |
| `hour[0..11]` | 12, 1, 2 … 11 | ✔ | ✔ |
| `min[1..3]` | :15, :30, :45 | ✔ | ✔ |
| `zone[0..5]` | ভোর 4–6, সকাল 7–11, দুপুর 12–15, বিকাল 16–17, সন্ধ্যা 18–19, রাত 20–3 | ✔ | – (0 0) |
| `ampm[0..1]` | AM / PM | – (0 0) | ✔ |

- At each announcement the EXE runs `play <alias> from <start> to <end> wait` for each fragment
  in turn, for example *starter → zone → hour → min*. A language uses either `zone` or `ampm`.
- Users could swap in **their own voice** by recording a new WAV and editing the timings.
  That's the original "voice pack" concept, and we keep it.
- The voice is a 9-year-old (Moshfekah Ferdaus Mahita). That's charming, but the audio is
  low quality (8-bit, 11 kHz).

> Open question: do the original `min[1..3]` clips say **সোয়া / সাড়ে / পৌনে** or
> **পনেরো / ত্রিশ / পঁয়তাল্লিশ মিনিট**? The answer informs the grammar default in §4.

### 1.2 Feature inventory (from the EXE, manual and screenshots)

| # | Feature | Details found | Rebuild decision |
|---|---|---|---|
| 1 | **Time announcement** | Interval 15 / 30 / 60 min / off | **v1 core** |
| 2 | **Language toggle** | "Announce in English/Bangla" (`IsEnglish` setting) | v1: Bangla. English pack in v1.x |
| 3 | **Tray app** | Lives in the taskbar. Menus: Clock, Tools, Events, Minimize, Exit | **v1**: macOS menu-bar app |
| 4 | **Alarms** | 6 fixed slots, each with a time and a WAV file (`Alarm%d`). Analog clock picker | v1: unlimited alarms, repeat days, snooze |
| 5 | **Event scheduler** | Title, message, date/time, "remind N min before", "remind again every N min", record a voice message in-app. Table `VCLOCK_EVENT` | v1.1 |
| 6 | **Aazan / prayer times** | Times by city lat/long/timezone/DST. Fajr by angle or interval, Asr by shadow ratio (1 or 2), Jumma. Plays `Aazan.wav` (`FAazan.wav` for Fajr). Daily table rows `Days, Fajr, Zohor, Asr, Magreb, Isha` | v1.1 (compute live, no table) |
| 7 | **Sleep timer** | Shutdown / power-off at a set time | Drop or later (sandbox and permission issues) |
| 8 | **Custom voice** | `VClock.def` + `vclock.wav` | v1: voice-pack format + importer for the legacy format |
| 9 | Repair DB, built-in web browser, About | Workarounds for the Jet DB and IE help viewer | Drop (About stays) |

### 1.3 Lessons from the original's changelog
- **DST bug**: the C `localtime` call announced the wrong hour. → Always read time from the OS
  timezone-aware clock and re-sync after timezone or DST changes.
- **Audio device conflict** broke Aazan. → Use one audio service that serialises all playback
  (announcement, alarm, aazan) with a clear priority.
- **Corrupted DB** needed a repair tool. → Use SQLite with transactions plus schema migrations.

---

## 2. Stack choice

### Recommendation: **Flutter (Dart)**

| Criterion | Flutter | Tauri 2 (Rust + web) | Electron | React Native | .NET MAUI |
|---|---|---|---|---|---|
| macOS / Windows / Linux | ✅ / ✅ / ✅ | ✅ / ✅ / ✅ | ✅ / ✅ / ✅ | ⚠️ MS forks / ⚠️ / ❌ | ✅ (Catalyst) / ✅ / ❌ |
| iOS / Android | ✅ mature | ⚠️ young | ❌ | ✅ | ✅ |
| One codebase for UI and logic | ✅ single language | ❌ Rust + JS | ✅ JS | ✅ JS | ✅ C# |
| App size (macOS) | ~25–40 MB | ~5–10 MB | ~150 MB+ | n/a | ~40 MB+ |
| Bangla text rendering | ✅ bundles its own fonts and shaping | ✅ (browser) | ✅ | ✅ | ⚠️ |
| Tray / menu bar, launch at login | ✅ plugins | ✅ built in | ✅ | ❌ | ⚠️ |
| Ease of work | ✅ hot reload, one language | ⚠️ two languages | ✅ | ⚠️ desktop is hard | ⚠️ |

**Why Flutter wins:**
- It's the only option that covers all **six** platforms from one codebase with mature tooling.
- UI, scheduling logic and audio composition are all Dart, which keeps the code simple.
- Bundled fonts (Noto Sans Bengali / Hind Siliguri) render Bangla the same on every platform.
- Hot reload makes UI iteration fast.

**Honest trade-offs:**
- The app is bigger than a Tauri app (~30 MB vs ~8 MB).
- A few macOS behaviours still need small Swift snippets through a platform channel: App Nap
  prevention and wake-from-sleep notifications. That's ~50 lines.
- Mobile background execution is restricted by the OS on any stack (see §5.3).

### 2.1 Packages

| Concern | Package | Notes |
|---|---|---|
| State management | `flutter_riverpod` | Testable, no `BuildContext` dependency |
| Storage | `drift` (SQLite) | Alarms, events, prayer settings. Migrations built in |
| Simple settings | `shared_preferences` | Interval, volume, language |
| Audio playback | `just_audio` (+ `just_audio_media_kit` on Win/Linux) | Plays one composed WAV buffer per announcement |
| Menu bar / tray | `tray_manager` + `window_manager` | macOS menu bar icon, popover-style window |
| Launch at login | `launch_at_startup` | Uses `SMAppService` on macOS 13+ |
| Notifications | `flutter_local_notifications` | Alarms and events (and mobile announcements later) |
| Prayer times | `adhan` (Dart port of adhan-js) | Muslim World League, Karachi, ISNA and other methods. Hanafi/Shafi Asr |
| Hijri / Bangla date | `hijri` + small custom Bangla calendar (বঙ্গাব্দ) | Shown in the UI |
| Localisation | `flutter_localizations` + ARB (`bn`, `en`) | Bangla UI and Bangla digits (০–৯) |
| Testing time | `clock` + `fake_async` | Deterministic scheduler tests |
| Auto-update (direct distribution) | `auto_updater` (Sparkle) | Not needed for the App Store build |

---

## 3. Architecture

```
┌──────────────────────────── UI (Flutter widgets) ────────────────────────────┐
│ Menu-bar popover · Settings · Alarms · Prayer · Events · Voice packs          │
└───────────────▲──────────────────────────────────────────────▲───────────────┘
                │ Riverpod providers                           │
┌───────────────┴───────────────── Core (pure Dart) ───────────┴───────────────┐
│ ClockService      → emits wall-clock ticks; resyncs on wake / TZ / DST change │
│ Scheduler         → next due item: announcement | alarm | aazan | event        │
│ PhraseBuilder     → (time, language, style) → [clip keys]  ← grammar per lang  │
│ VoicePack         → manifest.json + clips/*.wav; legacy .def importer          │
│ AudioComposer     → concatenates PCM clips → one WAV buffer (gapless)          │
│ AudioService      → single playback queue with priorities (aazan > alarm > …) │
│ PrayerService     → adhan calculations for location + method                   │
│ Repositories      → drift (SQLite) + prefs                                     │
└───────────────▲──────────────────────────────────────────────────────────────┘
                │ platform channels / plugins
┌───────────────┴──────────────────────────────────────────────────────────────┐
│ macOS: menu bar, login item, App Nap off, NSWorkspace wake notifications     │
│ (later) Windows tray · Linux AppIndicator · Android AlarmManager · iOS notifs │
└──────────────────────────────────────────────────────────────────────────────┘
```

### Key design decisions

1. **Grammar in code, voice in data.** The `PhraseBuilder` for each language knows the rules,
   for example that Bangla 1:30 is "দেড়টা" and 2:30 is "আড়াইটা". It outputs a list of **clip keys**.
   A voice pack only supplies audio for those keys. New voices need no code. New languages need
   one grammar class plus a voice pack.
2. **Compose once, play once.** Instead of playing fragments in sequence (the original approach,
   which leaves gaps and stutters), `AudioComposer` concatenates the 16-bit PCM clips into **one
   WAV buffer** in pure Dart, with small crossfades. The same buffer is:
   - played directly on desktop
   - written to a file as the **notification sound** on iOS/Android later

   One code path serves every platform.
3. **Sleep-until-next-event scheduler**, not a 1-second polling loop. After every tick, wake from
   sleep, or timezone change, it recomputes "next due" from the real OS local time. This avoids
   the original's DST bug.
   - **Stale-skip rule:** if the Mac wakes 40 min late, skip missed announcements instead of
     reading them all out. Alarms are an exception: a missed alarm fires once on wake, marked as missed.
4. **Quiet hours** (new): no announcements, say, 23:00–06:00. Alarms and aazan still play.
   Chime-only mode (new): an optional short chime before each announcement.

### 3.1 Voice-pack format

```
voices/bn_default/
  manifest.json
  clips/starter.wav  clips/hour_01.wav … clips/zone_sokal.wav  clips/sowa.wav …
```
```json
{
  "id": "bn_default",
  "name": "বাংলা – ডিফল্ট",
  "language": "bn",
  "grammar": "bn_v1",
  "sampleRate": 24000,
  "clips": { "starter": "clips/starter.wav", "hour_10": "clips/hour_10.wav", "...": "..." }
}
```
- Clip format: 16-bit PCM WAV, mono, 24 kHz, loudness-normalised (−16 LUFS), silence trimmed.
- A **legacy importer** reads a `VClock.def` + `vclock.wav` pair and turns it into a voice pack.
  Old custom voices keep working.
- Users can add packs from a folder: "Add voice pack…".

---

## 4. Bangla announcement grammar (needs your/native-speaker sign-off)

Two styles, user-selectable:

**A. Traditional (default)**, which is how people speak:

| Time | Phrase |
|---|---|
| 10:00 | এখন সময় **সকাল দশটা** |
| 10:15 | এখন সময় সকাল **সোয়া** দশটা |
| 10:30 | এখন সময় সকাল **সাড়ে** দশটা |
| 10:45 | এখন সময় সকাল **পৌনে এগারোটা** *(rolls to the next hour)* |
| 1:30 | এখন সময় দুপুর **দেড়টা** *(irregular)* |
| 2:30 | এখন সময় দুপুর **আড়াইটা** *(irregular)* |

**B. Exact** (new: announce any minute, for example "Speak time now" at 10:07):
এখন সময় সকাল দশটা বেজে সাত মিনিট. This needs number words ১–৫৯. Each one is irregular in
Bangla, so each is its own clip.

Time-of-day zones, using the original's ranges as default (editable in Settings):
ভোর 4–6 · সকাল 7–11 · দুপুর 12–15 · বিকাল 16–17 · সন্ধ্যা 18–19 · রাত 20–3.

**Required clip inventory (Bangla):**
- starter ×1
- zones ×6
- hours (একটা…বারোটা) ×12
- সোয়া / সাড়ে / পৌনে / দেড়টা / আড়াইটা ×5
- numbers ১–৫৯ ×59
- বেজে / মিনিট ×2
- chime ×1

That's **~86 clips**, ~4 MB.

---

## 5. Platform plan

### 5.1 macOS (v1)
- **Menu-bar-only app** (`LSUIElement = true`, no Dock icon). Clicking the icon opens a small
  window with the clock, next announcement, quick toggles and "Speak now".
- Optional: show the time in Bangla digits in the menu bar itself (১০:১৫).
- Launch at login via `SMAppService`.
- **App Nap / timer reliability**: call
  `ProcessInfo.beginActivity(.userInitiatedAllowingIdleSystemSleep)` through a small Swift channel,
  and re-sync on `NSWorkspace.didWakeNotification`.
- Minimum macOS: 12 Monterey (Flutter's current floor is around 10.15; 12+ simplifies login items).
- Universal binary (Apple Silicon + Intel).
- **Distribution**: Developer ID-signed and notarized **DMG** with Sparkle auto-update first.
  Mac App Store later (needs App Sandbox, which is compatible with everything in v1).

### 5.2 Windows / Linux (later)
Same code. The tray works through `tray_manager`. Mostly packaging work: MSIX or Inno Setup (a nod
to the original), and AppImage or deb.

### 5.3 Android / iOS (later): the architectural caveat
Mobile OSes do **not** let an app run a timer in the background. The plan:
- **Android**: exact alarms (`SCHEDULE_EXACT_ALARM`) + a notification with the composed WAV,
  or a foreground service while "Talking clock" is on.
- **iOS**: schedule local notifications with the composed WAV as a custom sound. Limits: a sound
  must be ≤ 30 s and at most 64 can be pending, which is about 16 h at 15-min intervals.
  The app refills the queue whenever it opens and via background refresh.

The "compose to one WAV" decision in §3 makes this possible without new audio code.

---

## 6. Voice assets: options

| Option | Quality | Cost / time | Notes |
|---|---|---|---|
| **A. Record a native speaker** (recommended for release) | Best, warm, natural | A few hours of studio or home-mic time | I provide a script of the ~86 lines and a batch tool that trims, normalises and names the clips |
| **B. AI TTS** (ElevenLabs multilingual, Azure `bn-BD-NabanitaNeural` / `PradeepNeural`, Google `bn-IN`) | Good, sometimes odd intonation | Minutes, low cost | Ideal as **placeholder during development**. Generated at build time, so the app stays fully offline |
| **C. Original "Mahita" clips** | Nostalgic but 8-bit / 11 kHz, and only 15/30/45 | Free | **Requires permission from the original author** to redistribute. Could ship as a "Classic 1998" pack if granted |

Plan: start development with **B** (an ElevenLabs connection is available in this environment),
swap in **A** before release, and pursue **C** as an optional extra.

---

## 7. Project structure

```
bangla_voice_clock/
├─ lib/
│  ├─ main.dart
│  ├─ app/                 # app shell, theme, routing, l10n setup
│  ├─ core/
│  │  ├─ time/             # ClockService, scheduler, quiet hours
│  │  ├─ speech/           # PhraseBuilder (bn, en), VoicePack, legacy .def importer
│  │  ├─ audio/            # AudioComposer (WAV concat), AudioService (queue)
│  │  ├─ prayer/           # adhan wrapper, location, methods
│  │  └─ data/             # drift DB, repositories, prefs
│  ├─ features/
│  │  ├─ tray/             # menu bar icon + menu
│  │  ├─ home/             # popover: clock, next announcement, quick toggles
│  │  ├─ settings/
│  │  ├─ alarms/
│  │  ├─ prayer/
│  │  └─ events/
│  ├─ platform/            # method-channel wrappers (App Nap, wake events)
│  └─ l10n/               # app_bn.arb, app_en.arb
├─ assets/
│  ├─ voices/bn_default/   # manifest.json + clips/
│  ├─ sounds/              # chimes, alarm tones, aazan
│  └─ fonts/               # Noto Sans Bengali, Hind Siliguri
├─ tool/
│  ├─ gen_voice.dart       # TTS generation from script (dev placeholder)
│  ├─ process_clips.dart   # trim, normalise, rename recorded clips
│  └─ voice_script_bn.md   # recording script for the voice artist
├─ test/                   # unit + widget + golden tests
├─ macos/  (later: windows/ linux/ android/ ios/)
└─ docs/PLAN.md
```

---

## 8. Milestones

| # | Milestone | Deliverable | Est. |
|---|---|---|---|
| **M0** | Setup | Install Xcode + Flutter. Create project, lints, folder skeleton, GitHub Actions macOS build | 0.5 day |
| **M1** | Core engine | `PhraseBuilder` (bn traditional + exact), voice-pack loader, `AudioComposer`, legacy `.def` importer. **Tests cover all 1,440 minutes of a day** | 2 days |
| **M2** | Placeholder voice | TTS-generated `bn_default` pack (~86 clips) + recording script | 1 day |
| **M3** | macOS MVP | Menu-bar app: live Bangla clock, interval 15/30/60/off, Speak now, volume, quiet hours, chime, launch at login, App Nap and wake handling | 3 days |
| **M4** | Alarms | Unlimited alarms, repeat days, custom sound, snooze, notification | 2 days |
| **M5** | Prayer times | City search / manual lat-long, calculation method, Hanafi/Shafi, aazan playback (separate Fajr aazan), Jumma, per-prayer on/off and offset | 2–3 days |
| **M6** | Events | Event reminders with "remind N min before" and "repeat every N min", optional recorded voice note | 2 days |
| **M7** | Polish and release | Bangla/English UI, app icon, About (crediting the original author), signing, notarization, DMG, Sparkle | 2 days |
| **M8** | Real voice | Swap in the human-recorded pack | depends on recording |
| Later | Platforms | Windows → Android → iOS → Linux | – |

**v1.0 = M0–M5 + M7** (talking clock, alarms, prayer times on macOS). Events can ship in v1.1 if
you want an earlier release.

---

## 9. Testing strategy
- **PhraseBuilder**: table-driven tests. For each of 1,440 minutes × {traditional, exact}, check
  the expected clip keys and expected Bangla text.
  Edge cases: 12:45 → পৌনে একটা, 23:45 → zone, 1:30 / 2:30 irregulars.
- **Scheduler**: `fake_async` + `clock`. Cover:
  - DST jump forward and back
  - timezone change
  - wake after 2 h asleep (stale-skip)
  - quiet hours across midnight
- **AudioComposer**: byte-level tests, checking header correctness, length = sum of clips, and
  sample-rate mismatch rejected.
- **Prayer**: compare against known published timetables (e.g. Dhaka, London) within ±1 min.
- **Manual QA checklist** for macOS: sleep/wake, login item, external audio device switch, Focus mode.

---

## 10. Before starting: what I need from you

1. **Grammar style**: is the Traditional (সোয়া/সাড়ে/পৌনে) default right? Should "exact minute"
   mode be in v1?
2. **Voice**: OK to start with an AI TTS placeholder? Do you have, or want, a human voice artist
   for release?
3. **Original voice**: should we try to contact the original author for permission to include
   the classic voice?
4. **Distribution**: direct DMG download (faster) or Mac App Store from day one?
5. **v1 scope**: confirm v1 = talking clock + alarms + prayer times, with events in v1.1.

### Build setup (decided 2026-10-17)
- Public GitHub repo; the app is released for free.
- **Local:** Flutter only. Engine code and tests (`flutter test`, `flutter analyze`) need no Xcode.
- **GitHub Actions:** builds the macOS app on `macos-latest` (Xcode preinstalled) and uploads it
  as an artifact. Later it will also sign, notarize and publish releases.
- Install Xcode locally only if UI iteration through CI turns out to be too slow.
- Apple Developer account ($99/yr): needed for notarized distribution (M7), not before.
