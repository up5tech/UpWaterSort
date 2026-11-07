import 'move.dart';

/// The whole player save, stored under the single key `save_v1`.
///
/// [version] exists for future migrations; never rename the JSON keys below
/// without adding one.
class SaveData {
  int version;
  int unlockedLevel;
  Map<int, int> stars;
  Settings settings;
  InProgress? inProgress;

  SaveData({
    this.version = 1,
    this.unlockedLevel = 1,
    Map<int, int>? stars,
    Settings? settings,
    this.inProgress,
  }) : stars = stars ?? {},
       settings = settings ?? Settings();

  Map<String, dynamic> toJson() => {
    'version': version,
    'unlocked': unlockedLevel,
    'stars': stars.map((k, v) => MapEntry('$k', v)),
    'settings': settings.toJson(),
    'inProgress': inProgress?.toJson(),
  };

  factory SaveData.fromJson(Map<String, dynamic> j) => SaveData(
    version: (j['version'] as int?) ?? 1,
    unlockedLevel: (j['unlocked'] as int?) ?? 1,
    stars: (j['stars'] as Map? ?? {}).map(
      (k, v) => MapEntry(int.parse('$k'), v as int),
    ),
    settings: Settings.fromJson(
      Map<String, dynamic>.from(j['settings'] as Map? ?? {}),
    ),
    inProgress: j['inProgress'] == null
        ? null
        : InProgress.fromJson(
            Map<String, dynamic>.from(j['inProgress'] as Map),
          ),
  );
}

class Settings {
  bool sound;
  bool vibration;
  bool colorBlind;
  bool darkMode;
  String locale;

  Settings({
    this.sound = true,
    this.vibration = true,
    this.colorBlind = false,
    this.darkMode = false,
    this.locale = 'en',
  });

  Map<String, dynamic> toJson() => {
    'sound': sound,
    'vibration': vibration,
    'colorBlind': colorBlind,
    'darkMode': darkMode,
    'locale': locale,
  };

  factory Settings.fromJson(Map<String, dynamic> j) => Settings(
    sound: (j['sound'] as bool?) ?? true,
    vibration: (j['vibration'] as bool?) ?? true,
    colorBlind: (j['colorBlind'] as bool?) ?? false,
    darkMode: (j['darkMode'] as bool?) ?? false,
    locale: (j['locale'] as String?) ?? 'en',
  );
}

/// Snapshot of an unfinished game, used to resume after relaunch.
class InProgress {
  final int levelId;
  final Tubes tubes;
  final List<Move> history;
  final bool extraTubeUsed;

  InProgress({
    required this.levelId,
    required this.tubes,
    required this.history,
    this.extraTubeUsed = false,
  });

  Map<String, dynamic> toJson() => {
    'levelId': levelId,
    'tubes': tubes,
    'history': history.map((m) => m.toJson()).toList(),
    'extra': extraTubeUsed,
  };

  factory InProgress.fromJson(Map<String, dynamic> j) => InProgress(
    levelId: j['levelId'] as int,
    tubes: (j['tubes'] as List)
        .map((t) => (t as List).cast<int>().toList())
        .toList(),
    history: (j['history'] as List)
        .map((e) => Move.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    extraTubeUsed: (j['extra'] as bool?) ?? false,
  );
}
