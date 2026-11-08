import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:up_water_sort/controllers/game_controller.dart';
import 'package:up_water_sort/domain/models/move.dart';

import 'harness.dart';

void main() {
  test('addExtraTube works once and survives undo and a relaunch', () async {
    final harness = await TestHarness.create();
    addTearDown(harness.dispose);
    final game = harness.game;
    game.startLevel(
      testLevel(
        id: 1,
        tubes: [
          [0, 0, 1, 1],
          [1, 1, 0, 0],
          <int>[],
          <int>[],
        ],
      ),
    );

    expect(game.addExtraTube(), isTrue);
    expect(game.tubes, hasLength(5));
    expect(game.tubes.last, isEmpty);
    expect(game.extraTubeUsed, isTrue);
    expect(game.addExtraTube(), isFalse);
    expect(game.tubes, hasLength(5));

    // The extra tube is not part of the history, so undo keeps it.
    await game.onTubeTap(0);
    await game.onTubeTap(2);
    expect(game.moves, 1);
    await game.undo();
    expect(game.moves, 0);
    expect(game.tubes, hasLength(5));

    final saved = harness.progress.inProgressFor(1)!;
    expect(saved.extraTubeUsed, isTrue);
    expect(saved.tubes, hasLength(5));

    final relaunched = await harness.relaunch();
    addTearDown(relaunched.dispose);
    expect(relaunched.game.startLevelById(1), isTrue);
    expect(relaunched.game.tubes, hasLength(5));
    expect(relaunched.game.extraTubeUsed, isTrue);
  });

  test('hint solves the current board and clears on the next tap', () async {
    final harness = await TestHarness.create();
    addTearDown(harness.dispose);
    final game = GameController(
      levels: harness.levels,
      progress: harness.progress,
      hintSolver: (tubes, capacity) async => const Move(0, 2, 2),
    );
    addTearDown(game.dispose);
    game.startLevel(
      testLevel(
        tubes: [
          [0, 0, 1, 1],
          [1, 1, 0, 0],
          <int>[],
          <int>[],
        ],
      ),
    );

    expect(await game.requestHint(), isTrue);
    expect(game.hint, const Move(0, 2, 2));
    expect(game.hintLoading, isFalse);

    await game.onTubeTap(0);
    expect(game.hint, isNull);
  });

  test('a hint that finds no solution reports failure', () async {
    final harness = await TestHarness.create();
    addTearDown(harness.dispose);
    final game = GameController(
      levels: harness.levels,
      progress: harness.progress,
      hintSolver: (tubes, capacity) async => null,
    );
    addTearDown(game.dispose);
    game.startLevel(
      testLevel(
        tubes: [
          [0, 1],
          [1, 0],
          [],
          [],
        ],
      ),
    );

    expect(await game.requestHint(), isFalse);
    expect(game.hint, isNull);
    expect(game.hintLoading, isFalse);
  });

  test(
    'a stale hint is dropped when the board changes while solving',
    () async {
      final harness = await TestHarness.create();
      addTearDown(harness.dispose);
      final gate = Completer<Move?>();
      final game = GameController(
        levels: harness.levels,
        progress: harness.progress,
        hintSolver: (tubes, capacity) => gate.future,
      );
      addTearDown(game.dispose);
      game.startLevel(
        testLevel(
          tubes: [
            [0, 0, 1, 1],
            [1, 1, 0, 0],
            <int>[],
            <int>[],
          ],
        ),
      );

      final pending = game.requestHint();
      await game.onTubeTap(0);
      gate.complete(const Move(0, 2, 2));

      expect(await pending, isFalse);
      expect(game.hint, isNull);
      expect(game.hintLoading, isFalse);
    },
  );
}
