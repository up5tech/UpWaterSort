import 'dart:convert';
import 'dart:io';
import 'dart:math' show Random, min;

import 'package:up_water_sort/domain/level_generator.dart';
import 'package:up_water_sort/domain/models/level_data.dart';

/// Offline level generator (PLAN.md 9.4).
///
/// Usage: `dart run tool/generate_levels.dart [levelCount]`
/// The seed is fixed at 2024 so the output is reproducible; never hand-edit
/// `assets/levels/levels.json` or its `par` values.
void main(List<String> args) {
  // Full release set (decided 2026-11-08, AGENTS.md 10 item 4): 210 levels.
  // 1–120 ramp 3 → 12 colours at capacity 4; 121–150 keep 12 colours and move
  // to capacity 5; 151–180 ramp the four extra palette colours (13 → 16);
  // 181–210 keep the palette and move to capacity 6 (PLAN.md 9.1 `181+` tier).
  final totalLevels = args.isEmpty ? 210 : int.tryParse(args.first);
  if (totalLevels == null || totalLevels < 1) {
    stderr.writeln('Usage: dart run tool/generate_levels.dart [levelCount]');
    exit(64);
  }

  final rng = Random(2024);
  final levels = <Map<String, dynamic>>[];

  for (var id = 1; id <= totalLevels; id++) {
    final colors = id <= 120
        ? min(3 + (id - 1) ~/ 6, 12)
        : id <= 150
        ? 12
        : id <= 180
        ? min(13 + ((id - 151) * 4) ~/ 30, 16)
        : min(13 + ((id - 181) * 4) ~/ 30, 16);
    final capacity = id <= 120
        ? 4
        : id <= 180
        ? 5
        : 6;
    const empty = 2;

    final result = LevelGenerator.generate(
      colors: colors,
      capacity: capacity,
      emptyTubes: empty,
      rng: rng,
    );
    if (result == null) {
      stderr.writeln('Could not generate level $id, try raising maxAttempts.');
      exit(1);
    }

    levels.add(
      LevelData(
        id: id,
        capacity: capacity,
        colorCount: colors,
        tubes: result.tubes,
        par: result.par,
      ).toJson(),
    );
    stdout.writeln('Level $id OK (colors=$colors, par=${result.par})');
  }

  final file = File('assets/levels/levels.json');
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(
    const JsonEncoder.withIndent('  ')
        .convert({'version': 1, 'levels': levels}),
  );
  stdout.writeln('Wrote ${levels.length} levels to ${file.path}');
}
