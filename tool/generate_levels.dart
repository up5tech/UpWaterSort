import 'dart:convert';
import 'dart:io';
import 'dart:math' show Random, min;

import 'package:up_water_sort/domain/level_generator.dart';
import 'package:up_water_sort/domain/models/level_data.dart';
import 'package:up_water_sort/domain/models/move.dart';

/// Offline level generator (PLAN.md 9.4).
///
/// Usage: `dart run tool/generate_levels.dart [levelCount]`
/// The seed is fixed at 2024 so the output is reproducible; never hand-edit
/// `assets/levels/levels.json` or its `par` values.
///
/// Levels are produced in blocks that share one difficulty configuration
/// (same colour count and capacity). Within a block every puzzle costs the
/// same to play, so the block is sorted by `par` before ids are assigned:
/// that keeps `par` non-decreasing across the whole set without having to
/// reject almost every candidate near the top of a block. Each block is also
/// generated with `minPar` set to the previous block's highest `par`, so the
/// curve never dips at a tier boundary either.
void main(List<String> args) {
  // Full release set (decided 2026-11-08, AGENTS.md 10 item 4): 210 levels.
  // 1–120 ramp 3 → 12 colours at capacity 4; 121–150 keep 12 colours and move
  // to capacity 5; 151–180 ramp the four extra palette colours (13 → 16);
  // 181–210 keep the palette and move to capacity 6 (PLAN.md 9.1 `181+` tier),
  // starting at 14 colours.
  final totalLevels = args.isEmpty ? 210 : int.tryParse(args.first);
  if (totalLevels == null || totalLevels < 1) {
    stderr.writeln('Usage: dart run tool/generate_levels.dart [levelCount]');
    exit(64);
  }

  final rng = Random(2024);
  final levels = <Map<String, dynamic>>[];
  // Lowest `par` the next block may use; keeps the curve non-decreasing.
  var floor = 0;
  var id = 1;

  while (id <= totalLevels) {
    final colors = _colorsFor(id);
    final capacity = _capacityFor(id);
    var lastId = id;
    while (lastId < totalLevels &&
        _colorsFor(lastId + 1) == colors &&
        _capacityFor(lastId + 1) == capacity) {
      lastId++;
    }
    final blockSize = lastId - id + 1;

    final block = <({Tubes tubes, int par})>[];
    while (block.length < blockSize) {
      final result = LevelGenerator.generate(
        colors: colors,
        capacity: capacity,
        emptyTubes: _emptyTubes,
        rng: rng,
        minPar: floor,
      );
      if (result == null) {
        stderr.writeln(
          'Could not generate a level for id $id with par >= $floor '
          '(colors=$colors, capacity=$capacity); lower the floor or raise '
          'maxAttempts.',
        );
        exit(1);
      }
      block.add(result);
    }

    block.sort((a, b) {
      final byPar = a.par.compareTo(b.par);
      return byPar != 0 ? byPar : _compareTubes(a.tubes, b.tubes);
    });

    for (final result in block) {
      if (result.par < floor) {
        stderr.writeln('Level $id would dip below the par floor $floor.');
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
      stdout.writeln(
        'Level $id OK (colors=$colors, capacity=$capacity, par=${result.par})',
      );
      floor = result.par;
      id++;
    }
  }

  final file = File('assets/levels/levels.json');
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(
    const JsonEncoder.withIndent('  ')
        .convert({'version': 1, 'levels': levels}),
  );
  stdout.writeln('Wrote ${levels.length} levels to ${file.path}');
}

const _emptyTubes = 2;

int _colorsFor(int id) => id <= 120
    ? min(3 + (id - 1) ~/ 6, 12)
    : id <= 150
    ? 12
    : id <= 180
    ? min(13 + ((id - 151) * 4) ~/ 30, 16)
    : min(14 + ((id - 181) * 3) ~/ 30, 16);

int _capacityFor(int id) => id <= 120
    ? 4
    : id <= 180
    ? 5
    : 6;

/// Deterministic tie-break so equal-`par` puzzles always land in the same
/// order, keeping the generated JSON reproducible.
int _compareTubes(Tubes a, Tubes b) {
  final shared = a.length < b.length ? a.length : b.length;
  for (var i = 0; i < shared; i++) {
    final left = a[i];
    final right = b[i];
    final lengthDiff = left.length.compareTo(right.length);
    if (lengthDiff != 0) return lengthDiff;
    for (var j = 0; j < left.length; j++) {
      final unitDiff = left[j].compareTo(right[j]);
      if (unitDiff != 0) return unitDiff;
    }
  }
  return a.length.compareTo(b.length);
}
