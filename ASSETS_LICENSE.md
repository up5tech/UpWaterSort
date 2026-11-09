# Asset licences

UpWaterSort ships only bundled, royalty-free assets (PLAN.md §4, AGENTS.md §2.10).

## Audio — `assets/audio/*.wav`

Four of the five effects (`select`, `complete_tube`, `error`, `win`) are
**synthesised from scratch by this repository** with
`dart run tool/generate_sfx.dart` (sine waves and filtered white noise, fixed
seed 2024). They contain no third-party recordings or samples and are released
as **CC0 / public domain** together with the source script.

`pour.wav` is a trimmed excerpt of a **public-domain recording**:

- Source: `Pouring water in mug in sink.ogg`, Wikimedia Commons,
  <https://commons.wikimedia.org/wiki/File:Pouring_water_in_mug_in_sink.ogg>
- Author: earthcalling (pdsounds.org record 73), released into the public domain
  by the author.
- Processing: decoded to 44.1 kHz mono 16-bit, 0.70 s cut from 16.50 s of the
  recording (the steadiest stretch: level variation 0.28, no isolated clinks),
  DC removed, 15 ms fade-in and 250 ms fade-out, RMS-normalised with a soft
  limiter. No other samples were added.

| File | Event | Length |
|---|---|---|
| `select.wav` | tube selected | ~0.13 s |
| `pour.wav` | pouring liquid (real recording) | ~0.70 s |
| `complete_tube.wav` | tube completed | ~0.45 s |
| `error.wav` | invalid move | ~0.26 s |
| `win.wav` | level won | ~1.7 s |

Format: 16-bit PCM mono WAV, 44.1 kHz (playback via `audioplayers` `AssetSource`;
no network access).

## Artwork — `assets/images/icon.png`, `assets/images/icon_mark.png`

Original vector-style artwork drawn from scratch for this project with
ImageMagick (three tubes with layered liquid on a navy gradient). The same mark
is reused for the Android splash (`res/drawable-nodpi/splash_logo.png`),
the iOS launch images and the Adaptive Icon foreground. Released as **CC0**.

Regenerate with `dart run flutter_launcher_icons` after replacing the artwork;
the launch images are exported at 1x/2x/3x from `icon_mark.png`.

## Fonts — `assets/fonts/`

Currently empty: the app uses the platform system font. A CC0 display font
(`Baloo2`) is planned for the release polish phase; its source and licence will
be recorded here before it is added.

## Images — `assets/images/`

Currently empty. Future icons/illustrations must be CC0 or royalty-free and
listed in this file before being committed.
