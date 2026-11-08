import 'package:flutter_test/flutter_test.dart';
import 'package:up_water_sort/controllers/game_controller.dart';

import 'harness.dart';

void main() {
  late TestHarness harness;
  late GameController game;

  setUp(() async {
    harness = await TestHarness.create();
    game = harness.game;
  });

  tearDown(() => harness.dispose());

  test('select then pour updates the board and the move count', () async {
    game.startLevel(
      testLevel(
        tubes: [
          [0, 1, 1],
          [1],
          [],
          [],
        ],
      ),
    );

    await game.onTubeTap(0);
    expect(game.selected, 0);

    await game.onTubeTap(1);
    expect(game.selected, isNull);
    expect(game.tubes, [
      [0],
      [1, 1, 1],
      <int>[],
      <int>[],
    ]);
    expect(game.moves, 1);
    expect(game.canUndo, isTrue);
  });

  test('undo restores the exact previous state', () async {
    game.startLevel(
      testLevel(
        tubes: [
          [0, 1, 1],
          [1],
          [],
          [],
        ],
      ),
    );
    final original = [for (final tube in game.tubes) List<int>.of(tube)];

    await game.onTubeTap(0);
    await game.onTubeTap(1);
    await game.undo();

    expect(game.tubes, original);
    expect(game.moves, 0);
    expect(game.canUndo, isFalse);
    expect(game.status, GameStatus.playing);
  });

  test('restart restores the level from scratch', () async {
    game.startLevel(
      testLevel(
        tubes: [
          [0, 1, 1],
          [1],
          [],
          [],
        ],
      ),
    );
    await game.onTubeTap(0);
    await game.onTubeTap(1);

    game.restart();

    expect(game.tubes, [
      [0, 1, 1],
      [1],
      <int>[],
      <int>[],
    ]);
    expect(game.moves, 0);
    expect(game.selected, isNull);
  });

  test('detects a win, records stars and blocks further taps', () async {
    game.startLevel(
      testLevel(
        tubes: [
          [0, 0, 0],
          [0],
          [],
        ],
        par: 1,
      ),
    );

    await game.onTubeTap(1);
    await game.onTubeTap(0);

    expect(game.tubes.first, [0, 0, 0, 0]);
    expect(game.status, GameStatus.won);
    expect(game.moves, 1);
    expect(harness.progress.starsForLevel(1), 3);
    expect(harness.progress.unlockedLevel, 2);
    expect(harness.progress.data.inProgress, isNull);

    await game.onTubeTap(0);
    expect(game.selected, isNull);
  });

  test('reports stuck when no legal move remains', () async {
    game.startLevel(
      testLevel(
        tubes: [
          [0, 1],
          [0, 1],
        ],
      ),
    );

    await game.onTubeTap(0);
    await game.onTubeTap(1);

    expect(game.status, GameStatus.stuck);
    expect(harness.progress.data.inProgress!.tubes, game.tubes);
  });

  group('tap edge cases', () {
    test('ignores an empty tube when nothing is selected', () async {
      game.startLevel(
        testLevel(
          tubes: [
            [0],
            [1],
            [],
            [],
          ],
        ),
      );

      await game.onTubeTap(2);
      expect(game.selected, isNull);
    });

    test('tapping the selected tube deselects it', () async {
      game.startLevel(
        testLevel(
          tubes: [
            [0],
            [1],
            [],
            [],
          ],
        ),
      );

      await game.onTubeTap(0);
      await game.onTubeTap(0);
      expect(game.selected, isNull);
    });

    test('invalid non-empty target moves the selection', () async {
      game.startLevel(
        testLevel(
          tubes: [
            [1],
            [2],
            [],
            [],
          ],
        ),
      );

      await game.onTubeTap(0);
      await game.onTubeTap(1);
      expect(game.selected, 1);
    });

    test('invalid full target moves the selection', () async {
      game.startLevel(
        testLevel(
          tubes: [
            [0],
            [1, 1, 1, 1],
            [],
            [],
          ],
        ),
      );

      await game.onTubeTap(0);
      await game.onTubeTap(1);
      expect(game.selected, 1);
    });
  });

  test('every move is saved as the in-progress game', () async {
    game.startLevel(
      testLevel(
        tubes: [
          [0, 1, 1],
          [1],
          [],
          [],
        ],
      ),
    );

    await game.onTubeTap(0);
    await game.onTubeTap(1);

    final saved = harness.progress.data.inProgress;
    expect(saved, isNotNull);
    expect(saved!.levelId, 1);
    expect(saved.tubes, game.tubes);
    expect(saved.history, hasLength(1));
  });

  test('undo persists the restored history', () async {
    game.startLevel(
      testLevel(
        tubes: [
          [0, 1, 1],
          [1],
          [],
          [],
        ],
      ),
    );
    await game.onTubeTap(0);
    await game.onTubeTap(1);

    await game.undo();

    expect(harness.progress.data.inProgress!.history, isEmpty);
  });

  test('resume restores the saved game after a relaunch', () async {
    game.startLevel(
      testLevel(
        tubes: [
          [0, 1, 1],
          [1],
          [],
          [],
        ],
      ),
    );
    await game.onTubeTap(0);
    await game.onTubeTap(1);
    final afterMove = [for (final tube in game.tubes) List<int>.of(tube)];

    final relaunched = await harness.relaunch();
    addTearDown(relaunched.dispose);

    expect(relaunched.game.startLevelById(1), isTrue);
    expect(relaunched.game.tubes, afterMove);
    expect(relaunched.game.moves, 1);
    expect(relaunched.game.canUndo, isTrue);

    await relaunched.game.undo();
    expect(relaunched.game.tubes, [
      [0, 1, 1],
      [1],
      <int>[],
      <int>[],
    ]);
    expect(relaunched.game.moves, 0);
  });

  test('startLevelById reports a missing level', () async {
    expect(game.startLevelById(999), isFalse);
    expect(game.isStarted, isFalse);
  });

  test('nextLevel follows the bundled level order', () async {
    game.startLevel(harness.levels.first!);
    expect(game.hasNextLevel, isTrue);
    expect(game.nextLevel(), isTrue);
    expect(game.level!.id, 2);

    game.startLevel(harness.levels.levels.last);
    expect(game.hasNextLevel, isFalse);
    expect(game.nextLevel(), isFalse);
  });
}
