import 'move.dart';

/// One bundled level, serialized to/from `assets/levels/levels.json`.
///
/// The JSON key for [colorCount] is `colors` (kept for save-format stability).
class LevelData {
  final int id;
  final int capacity;
  final int colorCount;
  final Tubes tubes;
  final int par;

  const LevelData({
    required this.id,
    required this.capacity,
    required this.colorCount,
    required this.tubes,
    required this.par,
  });

  factory LevelData.fromJson(Map<String, dynamic> j) => LevelData(
    id: j['id'] as int,
    capacity: j['capacity'] as int,
    colorCount: j['colors'] as int,
    tubes: (j['tubes'] as List)
        .map((t) => (t as List).cast<int>().toList())
        .toList(),
    par: j['par'] as int,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'capacity': capacity,
    'colors': colorCount,
    'tubes': tubes,
    'par': par,
  };
}
