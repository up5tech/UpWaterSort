import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'ui/screens/game_screen.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/level_select_screen.dart';

/// Root widget: Home is the entry point, Game and LevelSelect are pushed as
/// named routes (PLAN.md §12.1).
class UpWaterSortApp extends StatelessWidget {
  const UpWaterSortApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UpWaterSort',
      theme: kAppTheme,
      home: const HomeScreen(),
      routes: {
        GameScreen.routeName: (_) => const GameScreen(),
        LevelSelectScreen.routeName: (_) => const LevelSelectScreen(),
      },
    );
  }
}
