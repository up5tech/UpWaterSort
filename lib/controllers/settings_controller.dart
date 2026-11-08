import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../data/audio_service.dart';
import '../domain/models/save_data.dart';
import 'progress_controller.dart';

/// The two haptic strengths used by the game (PLAN.md §16.3).
enum HapticKind { light, error }

/// Owns the player settings (sound, vibration, color-blind mode, dark theme,
/// language). Values live inside the single `save_v1` blob, so the save is
/// still written by [ProgressController].
class SettingsController extends ChangeNotifier {
  SettingsController({required this.progress, required this.audio}) {
    audio.enabled = sound;
  }

  final ProgressController progress;
  final AudioService audio;

  Settings get _settings => progress.data.settings;

  bool get sound => _settings.sound;

  bool get vibration => _settings.vibration;

  bool get colorBlind => _settings.colorBlind;

  bool get darkMode => _settings.darkMode;

  /// `'en'` or `'vi'`.
  String get locale => _settings.locale == 'vi' ? 'vi' : 'en';

  Future<void> setSound(bool value) async {
    if (sound == value) return;
    audio.enabled = value;
    await progress.updateSettings((settings) => settings.sound = value);
    notifyListeners();
  }

  Future<void> setVibration(bool value) async {
    if (vibration == value) return;
    await progress.updateSettings((settings) => settings.vibration = value);
    notifyListeners();
  }

  Future<void> setColorBlind(bool value) async {
    if (colorBlind == value) return;
    await progress.updateSettings((settings) => settings.colorBlind = value);
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    if (darkMode == value) return;
    await progress.updateSettings((settings) => settings.darkMode = value);
    notifyListeners();
  }

  Future<void> setLocale(String value) async {
    final next = value == 'vi' ? 'vi' : 'en';
    if (locale == next) return;
    await progress.updateSettings((settings) => settings.locale = next);
    notifyListeners();
  }

  /// Wipes progress, stars and settings, then re-applies the defaults.
  Future<void> resetAll() async {
    await progress.resetAll();
    audio.enabled = sound;
    notifyListeners();
  }

  /// Fires a short haptic pulse unless the player turned vibration off.
  void haptic(HapticKind kind) {
    if (!vibration) return;
    switch (kind) {
      case HapticKind.light:
        unawaited(HapticFeedback.lightImpact());
      case HapticKind.error:
        unawaited(HapticFeedback.heavyImpact());
    }
  }
}
