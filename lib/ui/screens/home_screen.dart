import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/game_controller.dart';
import '../../controllers/progress_controller.dart';
import 'game_screen.dart';
import 'level_select_screen.dart';

/// Landing screen: continue the saved game, pick a level, see total stars
/// (PLAN.md §12.2). Settings arrives in Phase 5.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressController>();
    final hasLevels = progress.levelIds.isNotEmpty;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'UpWaterSort',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Colors.amber),
                    const SizedBox(width: 6),
                    Text(
                      '${progress.totalStars} stars',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: 220,
                  child: FilledButton(
                    onPressed: hasLevels ? () => _continue(context) : null,
                    child: const Text('Continue'),
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
                    child: const Text('Select level'),
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
