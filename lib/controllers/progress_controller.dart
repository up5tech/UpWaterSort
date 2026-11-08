import 'package:flutter/foundation.dart';

import '../data/level_repository.dart';
import '../data/storage_service.dart';
import '../domain/models/level_data.dart';
import '../domain/models/save_data.dart';

/// Star rating for a finished level (PLAN.md §17.1).
int starsFor(int moves, int par) {
  if (moves <= (par * 1.25).ceil()) return 3;
  if (moves <= (par * 1.75).ceil()) return 2;
  return 1;
}

/// Owns unlocking, stars and the in-progress game, and persists [SaveData]
/// through [StorageService].
class ProgressController extends ChangeNotifier {
  ProgressController({required this.storage, required this.levels});

  final StorageService storage;
  final LevelRepository levels;

  SaveData _data = SaveData();

  SaveData get data => _data;

  void load() {
    _data = storage.load();
    notifyListeners();
  }

  int get totalStars => _data.stars.values.fold(0, (sum, stars) => sum + stars);

  int get unlockedLevel => _data.unlockedLevel;

  bool isUnlocked(int levelId) => levelId <= _data.unlockedLevel;

  int starsForLevel(int levelId) => _data.stars[levelId] ?? 0;

  /// Level the Home "Continue" button opens: the saved game if there is one,
  /// otherwise the latest unlocked level.
  int get continueLevelId => _data.inProgress?.levelId ?? _data.unlockedLevel;

  /// The saved snapshot for [levelId], or null when another level is saved.
  InProgress? inProgressFor(int levelId) {
    final saved = _data.inProgress;
    return saved != null && saved.levelId == levelId ? saved : null;
  }

  /// Ids of the bundled levels, in order, for the level picker.
  List<int> get levelIds => [for (final level in levels.levels) level.id];

  /// Records a win: best stars, unlock the next level, drop the saved game.
  Future<void> completeLevel(LevelData level, int moves) async {
    final stars = starsFor(moves, level.par);
    final previous = _data.stars[level.id] ?? 0;
    if (stars > previous) _data.stars[level.id] = stars;
    if (level.id + 1 > _data.unlockedLevel && levels.hasNext(level.id)) {
      _data.unlockedLevel = level.id + 1;
    }
    _data.inProgress = null;
    await storage.save(_data);
    notifyListeners();
  }

  /// Stores the unfinished game so it can be resumed after a relaunch.
  Future<void> saveInProgress(InProgress snapshot) async {
    _data.inProgress = snapshot;
    await storage.save(_data);
    notifyListeners();
  }
}
