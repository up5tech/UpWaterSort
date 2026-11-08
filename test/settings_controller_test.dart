import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

void main() {
  test(
    'defaults: sound and vibration on, color-blind and dark off, en',
    () async {
      final harness = await TestHarness.create();
      addTearDown(harness.dispose);
      final settings = harness.settings;

      expect(settings.sound, isTrue);
      expect(settings.vibration, isTrue);
      expect(settings.colorBlind, isFalse);
      expect(settings.darkMode, isFalse);
      expect(settings.locale, 'en');
      expect(harness.audio.enabled, isTrue);
    },
  );

  test(
    'every option is persisted in save_v1 and survives a relaunch',
    () async {
      final harness = await TestHarness.create();
      addTearDown(harness.dispose);
      final settings = harness.settings;

      await settings.setSound(false);
      await settings.setVibration(false);
      await settings.setColorBlind(true);
      await settings.setDarkMode(true);
      await settings.setLocale('vi');

      expect(harness.audio.enabled, isFalse);
      expect(harness.progress.data.settings.locale, 'vi');

      final relaunched = await harness.relaunch();
      addTearDown(relaunched.dispose);

      expect(relaunched.settings.sound, isFalse);
      expect(relaunched.settings.vibration, isFalse);
      expect(relaunched.settings.colorBlind, isTrue);
      expect(relaunched.settings.darkMode, isTrue);
      expect(relaunched.settings.locale, 'vi');
      // A fresh AudioService follows the saved Sound option.
      expect(relaunched.audio.enabled, isFalse);
    },
  );

  test('an unknown locale falls back to en', () async {
    final harness = await TestHarness.create();
    addTearDown(harness.dispose);

    await harness.settings.setLocale('fr');

    expect(harness.settings.locale, 'en');
  });

  test('reset clears stars, unlocks and settings', () async {
    final harness = await TestHarness.create();
    addTearDown(harness.dispose);

    await harness.progress.completeLevel(harness.levels.byId(1)!, 2);
    await harness.settings.setDarkMode(true);
    await harness.settings.setSound(false);
    expect(harness.progress.totalStars, greaterThan(0));

    await harness.settings.resetAll();

    expect(harness.progress.unlockedLevel, 1);
    expect(harness.progress.totalStars, 0);
    expect(harness.progress.data.inProgress, isNull);
    expect(harness.settings.darkMode, isFalse);
    expect(harness.settings.sound, isTrue);
    expect(harness.audio.enabled, isTrue);
    // The stored save is a fresh default too.
    expect(harness.storage.load().unlockedLevel, 1);
    expect(harness.storage.load().settings.darkMode, isFalse);
  });
}
