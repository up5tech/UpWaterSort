import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'controllers/game_controller.dart';
import 'controllers/progress_controller.dart';
import 'controllers/settings_controller.dart';
import 'data/audio_service.dart';
import 'data/level_repository.dart';
import 'data/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final storage = await StorageService.create();
  final levels = LevelRepository();
  await levels.load();

  final audio = AudioService();
  await audio.preload();

  final progress = ProgressController(storage: storage, levels: levels)..load();
  final settings = SettingsController(progress: progress, audio: audio);
  final game = GameController(
    levels: levels,
    progress: progress,
    audio: audio,
    settings: settings,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ProgressController>.value(value: progress),
        ChangeNotifierProvider<SettingsController>.value(value: settings),
        ChangeNotifierProvider<GameController>.value(value: game),
      ],
      child: const UpWaterSortApp(),
    ),
  );
}
