import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controllers/settings_controller.dart';
import 'core/theme.dart';
import 'ui/screens/game_screen.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/level_select_screen.dart';
import 'ui/screens/settings_screen.dart';

/// Root widget: Home is the entry point, the other screens are pushed as
/// named routes (PLAN.md §12.1). The theme follows the persisted setting.
class UpWaterSortApp extends StatelessWidget {
  const UpWaterSortApp({super.key});

  @override
  Widget build(BuildContext context) {
    final darkMode = context.watch<SettingsController>().darkMode;

    return MaterialApp(
      title: 'UpWaterSort',
      theme: kLightTheme,
      darkTheme: kDarkTheme,
      themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
      home: const HomeScreen(),
      routes: {
        GameScreen.routeName: (_) => const GameScreen(),
        LevelSelectScreen.routeName: (_) => const LevelSelectScreen(),
        SettingsScreen.routeName: (_) => const SettingsScreen(),
      },
    );
  }
}
