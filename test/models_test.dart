import 'package:flutter_test/flutter_test.dart';
import 'package:up_water_sort/domain/models/level_data.dart';
import 'package:up_water_sort/domain/models/move.dart';
import 'package:up_water_sort/domain/models/save_data.dart';

void main() {
  group('Move JSON', () {
    test('round-trip keeps the short keys', () {
      const m = Move(2, 3, 2);
      expect(m.toJson(), {'f': 2, 't': 3, 'c': 2});
      expect(Move.fromJson(m.toJson()).toJson(), m.toJson());
    });
  });

  group('LevelData JSON', () {
    test('round-trip maps colors to colorCount', () {
      final level = LevelData(
        id: 1,
        capacity: 4,
        colorCount: 3,
        tubes: [
          [0, 1, 2, 0],
          [1, 2, 0, 1],
          [2, 0, 1, 2],
          <int>[],
          <int>[],
        ],
        par: 9,
      );
      final json = level.toJson();
      expect(json['colors'], 3);
      expect(json['par'], 9);
      expect(json['tubes'], level.tubes);

      final restored = LevelData.fromJson(json);
      expect(restored.id, 1);
      expect(restored.capacity, 4);
      expect(restored.colorCount, 3);
      expect(restored.tubes, level.tubes);
      expect(restored.par, 9);
    });
  });

  group('SaveData JSON', () {
    test('empty json falls back to defaults', () {
      final save = SaveData.fromJson({});
      expect(save.version, 1);
      expect(save.unlockedLevel, 1);
      expect(save.stars, isEmpty);
      expect(save.settings.sound, isTrue);
      expect(save.settings.vibration, isTrue);
      expect(save.settings.colorBlind, isFalse);
      expect(save.settings.darkMode, isFalse);
      expect(save.settings.locale, 'en');
      expect(save.inProgress, isNull);
    });

    test('round-trip preserves stars, settings and inProgress', () {
      final save = SaveData(
        unlockedLevel: 7,
        stars: {1: 3, 4: 2},
        settings: Settings(
          sound: false,
          vibration: false,
          colorBlind: true,
          darkMode: true,
        ),
        inProgress: InProgress(
          levelId: 7,
          tubes: [
            [0, 1],
            [1],
            <int>[],
          ],
          history: [const Move(0, 1, 1)],
          extraTubeUsed: true,
        ),
      );
      final restored = SaveData.fromJson(save.toJson());
      expect(restored.version, 1);
      expect(restored.unlockedLevel, 7);
      expect(restored.stars, {1: 3, 4: 2});
      expect(restored.settings.sound, isFalse);
      expect(restored.settings.vibration, isFalse);
      expect(restored.settings.colorBlind, isTrue);
      expect(restored.settings.darkMode, isTrue);
      expect(restored.inProgress!.levelId, 7);
      expect(restored.inProgress!.extraTubeUsed, isTrue);
      expect(restored.inProgress!.tubes, save.inProgress!.tubes);
      expect(restored.inProgress!.history.single.toJson(), {
        'f': 0,
        't': 1,
        'c': 1,
      });
    });
  });
}
