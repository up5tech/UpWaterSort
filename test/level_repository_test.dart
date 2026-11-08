import 'package:flutter_test/flutter_test.dart';
import 'package:up_water_sort/data/level_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads the bundled trial levels in order', () async {
    final repository = LevelRepository();
    await repository.load();

    expect(repository.count, 30);
    for (var i = 0; i < repository.levels.length; i++) {
      final level = repository.levels[i];
      expect(level.id, i + 1);
      expect(level.capacity, 4);
      expect(level.par, greaterThan(0));
      expect(level.tubes.length, greaterThan(level.colorCount));
    }
  });

  test('looks levels up by id and exposes the next one', () async {
    final repository = LevelRepository();
    await repository.load();

    expect(repository.byId(1)!.id, 1);
    expect(repository.byId(0), isNull);
    expect(repository.next(1)!.id, 2);
    expect(repository.hasNext(repository.levels.last.id), isFalse);
    expect(repository.next(repository.levels.last.id), isNull);
  });
}
