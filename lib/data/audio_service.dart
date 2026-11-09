import 'dart:math';

import 'package:audioplayers/audioplayers.dart';

/// The five bundled sound effects (PLAN.md §16.1).
enum Sfx { select, pour, completeTube, error, win }

/// Plays the bundled WAV effects through one [AudioPlayer] per sound so two
/// effects never cut each other off. The pour effect is deliberately a little
/// different every time (see [play]). Everything comes from `AssetSource`, so
/// no network access is involved (PLAN.md §4).
class AudioService {
  static const Map<Sfx, String> files = {
    Sfx.select: 'audio/select.wav',
    Sfx.pour: 'audio/pour.wav',
    Sfx.completeTube: 'audio/complete_tube.wav',
    Sfx.error: 'audio/error.wav',
    Sfx.win: 'audio/win.wav',
  };

  /// Per-effect playback volume. The pour plays on every move, so it sits a
  /// little below the UI sounds instead of dominating them.
  static const Map<Sfx, double> volumes = {Sfx.pour: 0.7};

  final Map<Sfx, AudioPlayer> _players = {};
  final Random _random = Random();

  /// Mirrors the Sound setting; [SettingsController] keeps it in sync.
  bool enabled = true;

  bool _disposed = false;

  /// Loads every effect up front. A missing or broken asset is skipped so the
  /// game still starts (the sound simply stays silent).
  Future<void> preload() async {
    for (final entry in files.entries) {
      try {
        final player = AudioPlayer();
        await player.setReleaseMode(ReleaseMode.stop);
        await player.setSource(AssetSource(entry.value));
        try {
          await player.setVolume(volumes[entry.key] ?? 1);
        } catch (_) {
          // No per-effect volume on this platform: play at the default level.
        }
        _players[entry.key] = player;
      } catch (_) {
        // Keep the game usable without audio.
      }
    }
  }

  Future<void> play(Sfx sfx) async {
    if (!enabled || _disposed) return;
    final player = _players[sfx];
    if (player == null) return;
    try {
      await player.stop();
      if (sfx == Sfx.pour) {
        // Slight pitch variation per pour, so a long level does not sound like
        // the same clipped sample repeated.
        try {
          await player.setPlaybackRate(0.92 + _random.nextDouble() * 0.16);
        } catch (_) {
          // Platform without playback-rate support: keep the default rate.
        }
      }
      await player.resume();
    } catch (_) {
      // Never let audio failures interrupt a move.
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    for (final player in _players.values) {
      try {
        await player.dispose();
      } catch (_) {
        // Ignore disposal races on shutdown.
      }
    }
    _players.clear();
  }
}
