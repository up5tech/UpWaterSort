import 'game_rules.dart';
import 'models/move.dart';

class _Node {
  final Tubes state;
  final int parent;
  final Move? move;

  _Node(this.state, this.parent, this.move);
}

/// Breadth-first search over board states. Returns the shortest solution
/// (a list of moves referencing the original tube indices), or `null` when no
/// solution is found within [maxNodes].
class Solver {
  /// Canonical key: tubes are interchangeable, so sort before joining.
  /// Used only for duplicate detection, never to produce moves.
  static String key(Tubes t) {
    final parts = t.map((tube) => tube.join(',')).toList()..sort();
    return parts.join('|');
  }

  static List<Move>? solve(Tubes start, int capacity, {int maxNodes = 300000}) {
    final nodes = <_Node>[_Node(start, -1, null)];
    final seen = <String>{key(start)};
    var head = 0;

    while (head < nodes.length && nodes.length < maxNodes) {
      final node = nodes[head];
      if (isWon(node.state, capacity)) return _trace(nodes, head);

      for (final m in legalMoves(node.state, capacity)) {
        final next = applyMove(node.state, m);
        if (seen.add(key(next))) {
          nodes.add(_Node(next, head, m));
        }
      }
      head++;
    }
    return null;
  }

  static List<Move> _trace(List<_Node> nodes, int index) {
    final path = <Move>[];
    var i = index;
    while (nodes[i].parent != -1) {
      path.add(nodes[i].move!);
      i = nodes[i].parent;
    }
    return path.reversed.toList();
  }
}
