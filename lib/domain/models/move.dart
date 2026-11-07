/// A board state: a list of tubes, each stored bottom -> top.
///
/// The last element of a tube is its top layer. A color is an `int` index into
/// the palette (`0..N-1`).
typedef Tubes = List<List<int>>;

/// One pour from tube [from] into tube [to].
///
/// [count] is the number of units actually poured, computed at the time of the
/// move by `game_rules.pourCount`.
class Move {
  final int from;
  final int to;
  final int count;

  const Move(this.from, this.to, this.count);

  Map<String, dynamic> toJson() => {'f': from, 't': to, 'c': count};

  factory Move.fromJson(Map<String, dynamic> j) =>
      Move(j['f'] as int, j['t'] as int, j['c'] as int);

  @override
  String toString() => 'Move($from→$to x$count)';
}
