import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:up_water_sort/controllers/game_controller.dart';
import 'package:up_water_sort/controllers/progress_controller.dart';
import 'package:up_water_sort/controllers/settings_controller.dart';
import 'package:up_water_sort/data/audio_service.dart';
import 'package:up_water_sort/data/level_repository.dart';
import 'package:up_water_sort/data/storage_service.dart';
import 'package:up_water_sort/domain/models/level_data.dart';

LevelData testLevel({
  int id = 1,
  required List<List<int>> tubes,
  int par = 5,
  int colorCount = 2,
}) => LevelData(
  id: id,
  capacity: 4,
  colorCount: colorCount,
  tubes: tubes,
  par: par,
);

/// Test-only wiring of the app's data and controllers.
class TestHarness {
  TestHarness._(
    this.storage,
    this.levels,
    this.progress,
    this.settings,
    this.audio,
    this.game,
  );

  final StorageService storage;
  final LevelRepository levels;
  final ProgressController progress;
  final SettingsController settings;
  final AudioService audio;
  final GameController game;

  static Future<TestHarness> create() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.create();
    final levels = await _sharedLevels();
    final progress = ProgressController(storage: storage, levels: levels)
      ..load();
    final audio = AudioService();
    final settings = SettingsController(progress: progress, audio: audio);
    return TestHarness._(
      storage,
      levels,
      progress,
      settings,
      audio,
      GameController(
        levels: levels,
        progress: progress,
        audio: audio,
        settings: settings,
      ),
    );
  }

  /// Bundled levels are immutable once loaded, so share one repository: a
  /// second `rootBundle` read inside a widget test's fake-async zone hangs.
  static Future<LevelRepository> _sharedLevels() async {
    final cached = _levels;
    if (cached != null) return cached;
    final repository = LevelRepository();
    await repository.load();
    return _levels = repository;
  }

  static LevelRepository? _levels;

  /// Fresh controllers reading the same stored save, i.e. an app relaunch.
  Future<TestHarness> relaunch() async {
    final storage = await StorageService.create();
    final progress = ProgressController(storage: storage, levels: levels)
      ..load();
    final audio = AudioService();
    final settings = SettingsController(progress: progress, audio: audio);
    return TestHarness._(
      storage,
      levels,
      progress,
      settings,
      audio,
      GameController(
        levels: levels,
        progress: progress,
        audio: audio,
        settings: settings,
      ),
    );
  }

  void dispose() {
    game.dispose();
    settings.dispose();
    progress.dispose();
  }
}
