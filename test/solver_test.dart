import 'package:flutter_test/flutter_test.dart';
import 'package:up_water_sort/domain/game_rules.dart';
import 'package:up_water_sort/domain/models/move.dart';
import 'package:up_water_sort/domain/solver.dart';

void main() {
  group('Solver.key', () {
    test('is insensitive to tube order', () {
      final Tubes a = [
        [0, 1],
        [2],
        <int>[],
      ];
      final Tubes b = [
        <int>[],
        [0, 1],
        [2],
      ];
      expect(Solver.key(a), Solver.key(b));
    });

    test('distinguishes different states', () {
      final Tubes a = [
        [0, 1],
        [2],
      ];
      final Tubes b = [
        [0, 2],
        [1],
      ];
      expect(Solver.key(a), isNot(Solver.key(b)));
    });
  });

  test('an already won board needs no moves', () {
    final Tubes start = [
      [0, 0, 0, 0],
      [1, 1, 1, 1],
      <int>[],
    ];
    expect(isWon(start, 4), isTrue);
    expect(Solver.solve(start, 4), isEmpty);
  });

  test('finds the shortest solution and replaying every move wins', () {
    final Tubes start = [
      [0, 0, 0, 0],
      [1, 1, 1],
      [1],
      <int>[],
    ];
    const capacity = 4;
    final solution = Solver.solve(start, capacity, maxNodes: 10000);
    expect(solution, isNotNull);
    expect(solution!.length, 1);

    var state = start;
    for (final m in solution) {
      expect(
        canPour(state, m.from, m.to, capacity),
        isTrue,
        reason: '$m must be legal on the current state',
      );
      expect(m.count, pourCount(state, m.from, m.to, capacity));
      state = applyMove(state, m);
    }
    expect(isWon(state, capacity), isTrue);
  });

  test('solves the 3-color example from PLAN.md 7.3', () {
    final Tubes start = [
      [0, 1, 2, 0],
      [1, 2, 0, 1],
      [2, 0, 1, 2],
      <int>[],
      <int>[],
    ];
    final solution = Solver.solve(start, 4, maxNodes: 300000);
    expect(solution, isNotNull);

    var state = start;
    for (final m in solution!) {
      state = applyMove(state, m);
    }
    expect(isWon(state, 4), isTrue);
  });

  test('returns null for a stuck (unsolvable) board', () {
    final Tubes start = [
      [0, 1, 0, 1],
      [1, 0, 1, 0],
    ];
    expect(isWon(start, 4), isFalse);
    expect(hasAnyMove(start, 4), isFalse);
    expect(Solver.solve(start, 4, maxNodes: 1000), isNull);
  });

  test('respects the node limit', () {
    final Tubes start = [
      [0, 0, 0, 0],
      [1, 1, 1],
      [1],
      <int>[],
    ];
    expect(Solver.solve(start, 4, maxNodes: 1), isNull);
  });
}
