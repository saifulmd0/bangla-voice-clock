# Voices

How each bundled voice pack was made, so it can be extended or remade the same way.

## `bn_ai`: Areeba AI (ElevenLabs), by Saiful Islam

A soft, cute young woman's voice with a Bangladeshi accent, designed and generated with
ElevenLabs on 2026-10-17.

| | |
|---|---|
| Voice design model | `eleven_ttv_v3` |
| Voice | "Bangla Voice Clock soft 3", voice id `XlH1ww91ELlLw7wRYFeW` (in the project's ElevenLabs library) |
| Speech model | **`eleven_v4`** |
| Voice settings | stability 0.5, similarity boost 0.8, seed 1 |
| Output | PCM 24 kHz, trimmed and level-normalised by `tool/elevenlabs.dart` |
| Wording | thirty is "তিরিশ", not "ত্রিশ", which the voice says clipped and short |

Voice description used for the design:

> A soft, cute and gentle young Bangladeshi woman in her early twenties, with a sweet, light,
> high and airy voice, speaking clear standard Bangla with a Bangladeshi (Dhaka) accent, not a
> Kolkata accent. Tender, warm and calm, with a slow, steady pace. Clean studio recording with
> no background noise.

Preview line:

> এখন সময় সকাল সোয়া দশটা। এখন সময় দুপুর সাড়ে বারোটা। এখন সময় সন্ধ্যা পৌনে সাতটা। এখন সময়
> রাত নয়টা বেজে সাতাশ মিনিট।

To regenerate or add lines:

```sh
dart run tool/elevenlabs.dart generate --voice XlH1ww91ELlLw7wRYFeW --model eleven_v4 \
    --out assets/voices/bn_ai
```

Existing clips are skipped; delete a clip file (or pass `--force`) to redo it.

### What we learned about the accent

- **The speech model decides the accent, not the voice design.** The same designed voice said
  সোয়া and সাড়ে with a Kolkata accent on `eleven_v3` and with a Bangladeshi accent on
  `eleven_v4`. Use `eleven_v4` for Bangla.
- Writing the words as they sound in Bangladesh (শোয়া, শারে) didn't help on `eleven_v4`; normal
  spelling sounded best.
- ElevenLabs refuses to design children's voices, so "young woman in her early twenties" with
  "soft, cute, light, high" is as young as a designed voice can be.
- Only `eleven_v3` and `eleven_v4` support Bangla. Voice design and library voices need a paid
  plan (pay-as-you-go is enough). The whole pack is about 4,100 characters.
- Library voices tagged Bengali all have Kolkata or Indian accents (checked 2026-10-17).
- Trim AI takes on level alone (`noiseFactor: 0`). A take has almost no silence, so measuring a
  noise floor from its quietest fifth measures speech, and trimming above it cut soft endings,
  such as the "জে" of "দুপুর বারোটা বেজে".

## `bn_classic`: Classic (1998), by Moshfekah Ferdaus Mahita

The voice of Moshfekah Ferdaus Mahita from the original Bangla Voice Clock for Windows
(1998–2002) by Q A M Khaled Ferdaus, used with permission. Imported from the original
`VClock.def` + `vclock.wav` with `tool/import_legacy_voice.dart`.

It speaks the original's way, quarter hours only: "এখন সময় রাত একটা পনেরো মিনিট". Its three
minute clips are "পনেরো মিনিট", "ত্রিশ মিনিট" and "পঁয়তাল্লিশ মিনিট" (the `.def` file marks
them `# 15 min` and so on), spoken after the hour, so the importer stores them as exact-style
minute endings. It has no "বেজে", which is optional, and no সোয়া/সাড়ে/পৌনে, so the traditional
style setting doesn't apply to it. At other minutes it says the quarter hour just passed.

The original recording is 8-bit, 11 kHz and quiet at the ends of words, so the importer trims
gently (noise factor 1.6, 60 ms padding): the soft "-নিট" of মিনিট sits only about twice above the
hiss. The original's "পঁয়তাল্লিশ মিনিট" is the weakest clip; its ending is faint in the 1998
recording itself, and splicing in the "মিনিট" from "পনেরো মিনিট" sounded worse, so it is kept as
recorded.
