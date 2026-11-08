import 'package:flutter_test/flutter_test.dart';
import 'package:up_water_sort/controllers/progress_controller.dart';
import 'package:up_water_sort/domain/models/move.dart';
import 'package:up_water_sort/domain/models/save_data.dart';

import 'harness.dart';

void main() {
  group('starsFor', () {
    test('follows the par-based thresholds of PLAN.md §17.1', () {
      expect(starsFor(10, 10), 3);
      expect(starsFor(13, 10), 3);
      expect(starsFor(14, 10), 2);
      expect(starsFor(18, 10), 2);
      expect(starsFor(19, 10), 1);
      expect(starsFor(5, 4), 3);
      expect(starsFor(6, 4), 2);
      expect(starsFor(7, 4), 2);
      expect(starsFor(8, 4), 1);
    });
  });

  test('completing a level records stars and unlocks the next one', () async {
    final harness = await TestHarness.create();
    addTearDown(harness.dispose);
    final progress = harness.progress;
    final level = harness.levels.byId(1)!;

    await progress.completeLevel(level, level.par);

    expect(progress.starsForLevel(1), 3);
    expect(progress.unlockedLevel, 2);
    expect(progress.isUnlocked(2), isTrue);
    expect(progress.isUnlocked(3), isFalse);
    expect(progress.data.inProgress, isNull);
  });

  test('a worse replay never lowers the recorded stars', () async {
    final harness = await TestHarness.create();
    addTearDown(harness.dispose);
    final progress = harness.progress;
    final level = harness.levels.byId(1)!;

    await progress.completeLevel(level, level.par);
    await progress.completeLevel(level, level.par * 5);

    expect(progress.starsForLevel(1), 3);
    expect(progress.totalStars, 3);
  });

  test('completing the last level does not unlock a missing one', () async {
    final harness = await TestHarness.create();
    addTearDown(harness.dispose);
    final progress = harness.progress;
    final last = harness.levels.levels.last;

    await progress.completeLevel(last, last.par);

    expect(progress.unlockedLevel, 1);
    expect(progress.starsForLevel(last.id), 3);
  });

  test('continue opens the saved game, otherwise the latest unlock', () async {
    final harness = await TestHarness.create();
    addTearDown(harness.dispose);
    final progress = harness.progress;

    expect(progress.continueLevelId, 1);

    await progress.saveInProgress(
      InProgress(
        levelId: 3,
        tubes: [
          [0],
          <int>[],
        ],
        history: [const Move(0, 1, 1)],
      ),
    );

    expect(progress.continueLevelId, 3);
    expect(progress.inProgressFor(3)!.history, hasLength(1));
    expect(progress.inProgressFor(1), isNull);
  });

  test('exposes the bundled level ids in order', () async {
    final harness = await TestHarness.create();
    addTearDown(harness.dispose);

    expect(harness.progress.levelIds, hasLength(120));
    expect(harness.progress.levelIds.first, 1);
    expect(harness.progress.levelIds.last, 120);
  });
}
