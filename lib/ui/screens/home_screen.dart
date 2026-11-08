import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/game_controller.dart';
import '../../controllers/progress_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../core/strings.dart';
import 'game_screen.dart';
import 'level_select_screen.dart';
import 'settings_screen.dart';

/// Landing screen: continue the saved game, pick a level, see total stars
/// (PLAN.md §12.2).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressController>();
    final strings = stringsFor(context.watch<SettingsController>().locale);
    final hasLevels = progress.levelIds.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.appName),
        actions: [
          IconButton(
            tooltip: strings.settings,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () =>
                Navigator.of(context).pushNamed(SettingsScreen.routeName),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Colors.amber),
                    const SizedBox(width: 6),
                    Text(
                      strings.stars(progress.totalStars),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: 220,
                  child: FilledButton(
                    onPressed: hasLevels ? () => _continue(context) : null,
                    child: Text(strings.continueGame),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: 220,
                  child: OutlinedButton(
                    onPressed: hasLevels
                        ? () =>
                              Navigator.of(context)
                                  .pushNamed(LevelSelectScreen.routeName)
                        : null,
                    child: Text(strings.selectLevel),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _continue(BuildContext context) {
    final game = context.read<GameController>();
    final progress = context.read<ProgressController>();
    if (game.startLevelById(progress.continueLevelId)) {
      Navigator.of(context).pushNamed(GameScreen.routeName);
    }
  }
}
