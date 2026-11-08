import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:up_water_sort/data/storage_service.dart';
import 'package:up_water_sort/domain/models/move.dart';
import 'package:up_water_sort/domain/models/save_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('round-trips progress, settings and the in-progress game', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.create();

    final data = SaveData(unlockedLevel: 4);
    data.stars[1] = 3;
    data.stars[2] = 2;
    data.settings.sound = false;
    data.inProgress = InProgress(
      levelId: 4,
      tubes: [
        [0, 1],
        <int>[],
      ],
      history: [const Move(0, 1, 2)],
    );
    await storage.save(data);

    final loaded = (await StorageService.create()).load();
    expect(loaded.unlockedLevel, 4);
    expect(loaded.stars, {1: 3, 2: 2});
    expect(loaded.settings.sound, isFalse);
    expect(loaded.inProgress!.levelId, 4);
    expect(loaded.inProgress!.tubes, [
      [0, 1],
      <int>[],
    ]);
    expect(loaded.inProgress!.history.single.count, 2);
  });

  test('uses a fresh save when nothing is stored', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.create();

    final data = storage.load();
    expect(data.unlockedLevel, 1);
    expect(data.stars, isEmpty);
    expect(data.inProgress, isNull);
  });

  test('falls back to a fresh save on corrupt data', () async {
    SharedPreferences.setMockInitialValues({
      StorageService.saveKey: '{not json',
    });
    final storage = await StorageService.create();

    final data = storage.load();
    expect(data.unlockedLevel, 1);
    expect(data.stars, isEmpty);
  });
}
