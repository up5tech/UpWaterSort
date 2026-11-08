import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../domain/models/level_data.dart';

/// Reads the pre-generated levels bundled in `assets/levels/levels.json`.
class LevelRepository {
  static const String assetPath = 'assets/levels/levels.json';

  List<LevelData> _levels = const <LevelData>[];

  /// Levels in bundled (difficulty) order. Treat as read-only.
  List<LevelData> get levels => _levels;

  int get count => _levels.length;

  bool get isEmpty => _levels.isEmpty;

  LevelData? get first => _levels.isEmpty ? null : _levels.first;

  Future<void> load() async {
    final raw = await rootBundle.loadString(assetPath);
    _levels = parse(raw);
  }

  /// Decodes the JSON document into levels; exposed for tests and tooling.
  static List<LevelData> parse(String source) {
    final decoded = jsonDecode(source) as Map<String, dynamic>;
    return (decoded['levels'] as List)
        .map(
          (entry) =>
              LevelData.fromJson(Map<String, dynamic>.from(entry as Map)),
        )
        .toList();
  }

  LevelData? byId(int id) {
    for (final level in _levels) {
      if (level.id == id) return level;
    }
    return null;
  }

  LevelData? next(int id) => byId(id + 1);

  bool hasNext(int id) => next(id) != null;
}
