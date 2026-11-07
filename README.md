# UpWaterSort

A 100% offline Flutter/Dart water-sort puzzle game for Android and iOS. Single player, 1–3 minutes per level, 100–200 pre-generated bundled levels. No backend, no network, no internet permission.

## Requirements

- Flutter 3.47.8 / Dart 3.13.7 (see `AGENTS.md` §10 item 2)
- Android + iOS toolchains (`flutter doctor`)

## Getting started

```bash
flutter pub get
flutter run
```

## Commands

```bash
dart format lib test tool       # formatting
flutter analyze                 # must be clean
flutter test                   # must be green (see note below)
dart run tool/generate_levels.dart  # regenerate assets/levels/levels.json (fixed seed 2024)
flutter build apk --release     # or: flutter build appbundle --release / flutter build ios --release
```

> On this machine `HTTP_PROXY` is set without `NO_PROXY`, so run tests with:
> `NO_PROXY=localhost,127.0.0.1,::1 no_proxy=localhost,127.0.0.1,::1 flutter test`

## Project layout

```
lib/
  core/        # constants, palette, theme
  domain/      # pure Dart: models, game_rules, solver, level_generator
  data/        # repositories / services (storage, audio, levels)
  controllers/ # provider + ChangeNotifier (Game/Progress/Settings)
  ui/          # widgets, painters, screens
  main.dart
test/          # mirrors lib/
tool/          # offline scripts (generate_levels.dart)
assets/        # levels/, audio/, images/, fonts/
```

## Offline guarantees

- No network packages as direct dependencies (approved transitive exception: `audioplayers` → `http`, used only via `AssetSource`).
- No `INTERNET` permission in release builds; fonts/audio/levels bundled under `assets/`.
- Player data stored only via `shared_preferences` (`save_v1` key).
- Verify with a playthrough in airplane mode.

## Status

Phases 0 and 1 complete (scaffold + pure-Dart domain, solver, generator, 30 trial levels). Next: Phase 2 (basic playable UI). See `PLAN.md` §21 roadmap.

## License

See `ASSETS_LICENSE.md` for asset sources (Phase 5/6).
```
filePath">
/Users/up5techjacky/Documents/projects/UpWaterSort/README.md