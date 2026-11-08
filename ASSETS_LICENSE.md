# Asset licences

UpWaterSort ships only bundled, royalty-free assets (PLAN.md §4, AGENTS.md §2.10).

## Audio — `assets/audio/*.wav`

The five sound effects are **synthesised from scratch by this repository** with
`dart run tool/generate_sfx.dart` (sine waves and filtered white noise, fixed
seed 2024). They contain no third-party recordings or samples and are released
as **CC0 / public domain** together with the source script.

| File | Event | Length |
|---|---|---|
| `select.wav` | tube selected | ~0.13 s |
| `pour.wav` | pouring liquid | ~0.75 s |
| `complete_tube.wav` | tube completed | ~0.45 s |
| `error.wav` | invalid move | ~0.26 s |
| `win.wav` | level won | ~1.7 s |

Format: 16-bit PCM mono WAV, 44.1 kHz (playback via `audioplayers` `AssetSource`;
no network access).

## Fonts — `assets/fonts/`

Currently empty: the app uses the platform system font. A CC0 display font
(`Baloo2`) is planned for the release polish phase; its source and licence will
be recorded here before it is added.

## Images — `assets/images/`

Currently empty. Future icons/illustrations must be CC0 or royalty-free and
listed in this file before being committed.
