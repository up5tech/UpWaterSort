import 'dart:math' show min;

import 'models/move.dart';

/// Number of consecutive same-color units at the top of a tube.
int topRun(List<int> tube) {
  if (tube.isEmpty) return 0;
  var n = 1;
  while (n < tube.length && tube[tube.length - 1 - n] == tube.last) {
    n++;
  }
  return n;
}

/// A pour from [from] into [to] is allowed when all four conditions hold.
bool canPour(Tubes t, int from, int to, int capacity) {
  if (from == to) return false;
  final src = t[from];
  final dst = t[to];
  if (src.isEmpty) return false;
  if (dst.length >= capacity) return false;
  if (dst.isNotEmpty && dst.last != src.last) return false;
  return true;
}

/// Units moved by a legal pour: the whole top run, capped by free space.
int pourCount(Tubes t, int from, int to, int capacity) =>
    min(topRun(t[from]), capacity - t[to].length);

/// Returns a NEW state; [t] is never mutated.
Tubes applyMove(Tubes t, Move m) {
  final next = [for (final x in t) List<int>.of(x)];
  final color = next[m.from].last;
  for (var i = 0; i < m.count; i++) {
    next[m.from].removeLast();
    next[m.to].add(color);
  }
  return next;
}

/// Reverts [m] on the state produced by `applyMove`; [t] is never mutated.
Tubes undoMove(Tubes t, Move m) {
  final next = [for (final x in t) List<int>.of(x)];
  final color = next[m.to].last;
  for (var i = 0; i < m.count; i++) {
    next[m.to].removeLast();
    next[m.from].add(color);
  }
  return next;
}

bool isTubeComplete(List<int> tube, int capacity) =>
    tube.length == capacity && tube.every((c) => c == tube.first);

bool isWon(Tubes t, int capacity) =>
    t.every((tube) => tube.isEmpty || isTubeComplete(tube, capacity));

/// All legal moves, with pointless ones filtered out:
///  - a completed source tube (full, single color) is never poured out;
///  - a single-color source into an empty target only relocates the liquid.
List<Move> legalMoves(Tubes t, int capacity) {
  final moves = <Move>[];
  for (var i = 0; i < t.length; i++) {
    final src = t[i];
    if (src.isEmpty) continue;
    if (isTubeComplete(src, capacity)) continue;
    final srcIsUniform = src.every((c) => c == src.first);
    for (var j = 0; j < t.length; j++) {
      if (!canPour(t, i, j, capacity)) continue;
      if (srcIsUniform && t[j].isEmpty) continue;
      moves.add(Move(i, j, pourCount(t, i, j, capacity)));
    }
  }
  return moves;
}

bool hasAnyMove(Tubes t, int capacity) => legalMoves(t, capacity).isNotEmpty;
