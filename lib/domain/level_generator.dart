import 'dart:math';

import 'game_rules.dart';
import 'models/move.dart';
import 'solver.dart';

/// Random shuffle + solver verification (PLAN.md 9.3, approach A).
///
/// Every generated level is guaranteed solvable because the BFS solver has to
/// find a solution before the level is accepted; [par] is that shortest
/// solution's length.
class LevelGenerator {
  /// Returns `(tubes, par)` or `null` if all attempts fail.
  ///
  /// [minPar] rejects puzzles whose shortest solution is shorter than the
  /// given value; the offline tool uses it to keep the bundled `par` curve
  /// non-decreasing. A rejected candidate still costs one attempt.
  static ({Tubes tubes, int par})? generate({
    required int colors,
    required int capacity,
    required int emptyTubes,
    required Random rng,
    int minPar = 0,
    int maxAttempts = 200,
    int solverNodeLimit = 300000,
  }) {
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final units = <int>[
        for (var c = 0; c < colors; c++) ...List.filled(capacity, c),
      ]..shuffle(rng);

      final tubes = <List<int>>[
        for (var i = 0; i < colors; i++)
          units.sublist(i * capacity, (i + 1) * capacity),
        for (var i = 0; i < emptyTubes; i++) <int>[],
      ];

      // Reject levels that already contain a finished tube (too easy).
      if (tubes.any((t) => isTubeComplete(t, capacity))) continue;

      final solution = Solver.solve(tubes, capacity, maxNodes: solverNodeLimit);
      if (solution != null && solution.length >= minPar) {
        return (tubes: tubes, par: solution.length);
      }
    }
    return null;
  }
}
