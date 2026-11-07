import 'package:flutter_test/flutter_test.dart';
import 'package:up_water_sort/domain/game_rules.dart';
import 'package:up_water_sort/domain/models/move.dart';

void main() {
  group('topRun', () {
    test('returns 0 for an empty tube', () {
      expect(topRun(<int>[]), 0);
    });

    test('counts a full tube of one color', () {
      expect(topRun([2, 2, 2, 2]), 4);
    });

    test('counts only the contiguous top block (bottom -> top order)', () {
      expect(topRun([0, 1, 1, 1]), 3);
      expect(topRun([1, 1, 1, 0]), 1);
    });
  });

  group('canPour', () {
    test('allows pouring into an empty tube', () {
      final Tubes t = [
        [1, 2],
        <int>[],
      ];
      expect(canPour(t, 0, 1, 4), isTrue);
    });

    test('allows pouring onto the same top color', () {
      final Tubes t = [
        [0, 2, 2],
        [2, 2],
      ];
      expect(canPour(t, 0, 1, 4), isTrue);
    });

    test('rejects pouring a tube into itself', () {
      expect(
        canPour(
          [
            [1],
          ],
          0,
          0,
          4,
        ),
        isFalse,
      );
    });

    test('rejects an empty source', () {
      final Tubes t = [
        <int>[],
        [1],
      ];
      expect(canPour(t, 0, 1, 4), isFalse);
    });

    test('rejects a full target', () {
      final Tubes t = [
        [1],
        [1, 1, 1, 1],
      ];
      expect(canPour(t, 0, 1, 4), isFalse);
    });

    test('rejects different top colors', () {
      final Tubes t = [
        [1, 2],
        [1, 3],
      ];
      expect(canPour(t, 0, 1, 4), isFalse);
    });
  });

  group('pourCount', () {
    test('pours the whole same-color block when there is room', () {
      final Tubes t = [
        [0, 1, 1, 1],
        <int>[],
      ];
      expect(pourCount(t, 0, 1, 4), 3);
    });

    test('is limited by the free space in the target', () {
      final Tubes t = [
        [1, 1, 1],
        [1, 1, 1],
      ];
      expect(pourCount(t, 0, 1, 4), 1);
    });
  });

  group('applyMove / undoMove', () {
    test('undo restores the exact previous state', () {
      final Tubes t = [
        [0, 1, 1],
        [1],
      ];
      const m = Move(0, 1, 2);
      final after = applyMove(t, m);
      expect(after, [
        [0],
        [1, 1, 1],
      ]);
      expect(undoMove(after, m), t);
    });

    test('never mutates the input state', () {
      final Tubes t = [
        [0, 1, 1],
        [1],
      ];
      final snapshot = [for (final tube in t) List<int>.of(tube)];
      const m = Move(0, 1, 2);
      final after = applyMove(t, m);
      expect(t, snapshot);
      expect(undoMove(after, m), snapshot);
      expect(after, isNot(same(t)));
    });

    test('pours only as many units as the target can hold', () {
      final Tubes t = [
        [1, 1, 1],
        [1, 1, 1],
      ];
      const m = Move(0, 1, 1);
      final after = applyMove(t, m);
      expect(after, [
        [1, 1],
        [1, 1, 1, 1],
      ]);
      expect(undoMove(after, m), t);
    });
  });

  group('isTubeComplete / isWon', () {
    test('a full single-color tube is complete', () {
      expect(isTubeComplete([2, 2, 2, 2], 4), isTrue);
      expect(isTubeComplete([2, 2, 2], 4), isFalse);
      expect(isTubeComplete([2, 2, 2, 1], 4), isFalse);
      expect(isTubeComplete(<int>[], 4), isFalse);
    });

    test('won when every tube is empty or full with one color', () {
      expect(
        isWon([
          [1, 1, 1, 1],
          [2, 2, 2, 2],
          <int>[],
        ], 4),
        isTrue,
      );
    });

    test('not won while a mixed tube remains', () {
      expect(
        isWon([
          [1, 1, 1, 2],
          [2, 2, 2, 1],
        ], 4),
        isFalse,
      );
    });

    test('not won while a partially filled single-color tube remains', () {
      expect(
        isWon([
          [1, 1, 1],
          <int>[],
        ], 4),
        isFalse,
      );
    });
  });

  group('legalMoves / hasAnyMove', () {
    test('keeps legal pours with their computed count', () {
      final Tubes t = [
        [0, 1, 1],
        [1],
        <int>[],
      ];
      final moves = legalMoves(t, 4);
      expect(
        moves.any((m) => m.from == 0 && m.to == 1 && m.count == 2),
        isTrue,
      );
      expect(
        moves.any((m) => m.from == 0 && m.to == 2 && m.count == 2),
        isTrue,
      );
      expect(
        moves.any((m) => m.from == 1 && m.to == 0 && m.count == 1),
        isTrue,
      );
      expect(hasAnyMove(t, 4), isTrue);
    });

    test('skips completed sources and pointless uniform -> empty moves', () {
      final Tubes t = [
        [1, 1, 1, 1],
        [0, 0],
        <int>[],
        <int>[],
      ];
      expect(isWon(t, 4), isFalse);
      expect(legalMoves(t, 4), isEmpty);
      expect(hasAnyMove(t, 4), isFalse);
    });
  });
}
