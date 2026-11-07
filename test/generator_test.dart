import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:up_water_sort/domain/game_rules.dart';
import 'package:up_water_sort/domain/level_generator.dart';
import 'package:up_water_sort/domain/models/level_data.dart';
import 'package:up_water_sort/domain/solver.dart';

void main() {
  test('20 seeds produce valid, solvable levels', () {
    for (var seed = 0; seed < 20; seed++) {
      final result = LevelGenerator.generate(
        colors: 3,
        capacity: 4,
        emptyTubes: 2,
        rng: Random(seed),
        solverNodeLimit: 50000,
      );
      expect(result, isNotNull, reason: 'seed $seed must generate a level');

      final tubes = result!.tubes;
      expect(tubes.length, 5, reason: 'seed $seed');

      final units = <int, int>{};
      for (final tube in tubes) {
        for (final color in tube) {
          units[color] = (units[color] ?? 0) + 1;
        }
      }
      expect(units.length, 3, reason: 'seed $seed');
      for (final entry in units.entries) {
        expect(
          entry.value,
          4,
          reason: 'color ${entry.key} must have exactly 4 units, seed $seed',
        );
      }
      expect(
        tubes.any((t) => isTubeComplete(t, 4)),
        isFalse,
        reason: 'seed $seed must not start with a completed tube',
      );

      final solution = Solver.solve(tubes, 4, maxNodes: 50000);
      expect(solution, isNotNull, reason: 'seed $seed');
      expect(result.par, solution!.length);

      var state = tubes;
      for (final m in solution) {
        state = applyMove(state, m);
      }
      expect(isWon(state, 4), isTrue, reason: 'seed $seed');
    }
  });

  test('is deterministic for the same seed', () {
    final a = LevelGenerator.generate(
      colors: 4,
      capacity: 4,
      emptyTubes: 2,
      rng: Random(7),
      solverNodeLimit: 50000,
    );
    final b = LevelGenerator.generate(
      colors: 4,
      capacity: 4,
      emptyTubes: 2,
      rng: Random(7),
      solverNodeLimit: 50000,
    );
    expect(a, isNotNull);
    expect(a!.tubes, b!.tubes);
    expect(a.par, b.par);
  });

  test('returns null when every candidate is already solved', () {
    final result = LevelGenerator.generate(
      colors: 1,
      capacity: 4,
      emptyTubes: 2,
      rng: Random(1),
      maxAttempts: 5,
      solverNodeLimit: 1000,
    );
    expect(result, isNull);
  });

  test('bundled levels.json is valid and every level is solvable', () {
    final file = File('assets/levels/levels.json');
    expect(
      file.existsSync(),
      isTrue,
      reason: 'run dart run tool/generate_levels.dart first',
    );

    final decoded = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    expect(decoded['version'], 1);
    final rawLevels = decoded['levels'] as List;
    expect(rawLevels, isNotEmpty);

    for (var i = 0; i < rawLevels.length; i++) {
      final level = LevelData.fromJson(
        Map<String, dynamic>.from(rawLevels[i] as Map),
      );
      expect(level.id, i + 1, reason: 'level ids must be sequential');
      expect(level.capacity, 4);

      final units = <int, int>{};
      for (final tube in level.tubes) {
        for (final color in tube) {
          units[color] = (units[color] ?? 0) + 1;
        }
      }
      expect(units.length, level.colorCount, reason: 'level ${level.id}');
      for (final entry in units.entries) {
        expect(
          entry.value,
          level.capacity,
          reason: 'level ${level.id}, color ${entry.key}',
        );
      }
      expect(
        level.tubes.any((t) => isTubeComplete(t, level.capacity)),
        isFalse,
        reason: 'level ${level.id} must not start with a completed tube',
      );

      final solution = Solver.solve(
        level.tubes,
        level.capacity,
        maxNodes: 300000,
      );
      expect(solution, isNotNull, reason: 'level ${level.id} must be solvable');
      expect(
        level.par,
        solution!.length,
        reason: 'level ${level.id} par must equal the shortest solution',
      );

      var state = level.tubes;
      for (final m in solution) {
        state = applyMove(state, m);
      }
      expect(
        isWon(state, level.capacity),
        isTrue,
        reason: 'level ${level.id} replay must win',
      );
    }
  });
}
