# Voices

How each bundled voice pack was made, so it can be extended or remade the same way.

## `bn_ai`: মিষ্টি কণ্ঠ (AI)

A soft, cute young woman's voice with a Bangladeshi accent, designed and generated with
ElevenLabs on 2026-10-17.

| | |
|---|---|
| Voice design model | `eleven_ttv_v3` |
| Voice | "Bangla Voice Clock soft 3", voice id `XlH1ww91ELlLw7wRYFeW` (in the project's ElevenLabs library) |
| Speech model | **`eleven_v4`** |
| Voice settings | stability 0.5, similarity boost 0.8, seed 1 |
| Output | PCM 24 kHz, trimmed and level-normalised by `tool/elevenlabs.dart` |

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

## `bn_classic`: ক্লাসিক (১৯৯৮)

The voice of Moshfekah Ferdaus Mahita from the original Bangla Voice Clock for Windows
(1998–2002) by Q A M Khaled Ferdaus, used with permission. Imported from the original
`VClock.def` + `vclock.wav` with `tool/import_legacy_voice.dart`. It has the quarter-hour words
only, so it can't speak exact minutes, and it says সাড়ে একটা / সাড়ে দুইটা for দেড়টা / আড়াইটা.
