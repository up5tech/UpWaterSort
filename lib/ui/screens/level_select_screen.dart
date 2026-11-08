import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/game_controller.dart';
import '../../controllers/progress_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../core/strings.dart';
import 'game_screen.dart';

/// Level picker: one cell per bundled level with its stars, locked until the
/// previous levels are finished (PLAN.md §12.2).
class LevelSelectScreen extends StatelessWidget {
  const LevelSelectScreen({super.key});

  static const String routeName = '/levels';

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressController>();
    final strings = stringsFor(context.watch<SettingsController>().locale);
    final levelIds = progress.levelIds;

    return Scaffold(
      appBar: AppBar(title: Text(strings.selectLevel)),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 500 ? 5 : 4;
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemCount: levelIds.length,
            itemBuilder: (context, index) {
              final levelId = levelIds[index];
              final unlocked = progress.isUnlocked(levelId);
              return _LevelCell(
                levelId: levelId,
                unlocked: unlocked,
                stars: progress.starsForLevel(levelId),
                onTap: unlocked ? () => _play(context, levelId) : null,
              );
            },
          );
        },
      ),
    );
  }

  void _play(BuildContext context, int levelId) {
    final game = context.read<GameController>();
    if (game.startLevelById(levelId)) {
      Navigator.of(context).pushNamed(GameScreen.routeName);
    }
  }
}

class _LevelCell extends StatelessWidget {
  const _LevelCell({
    required this.levelId,
    required this.unlocked,
    required this.stars,
    this.onTap,
  });

  final int levelId;
  final bool unlocked;
  final int stars;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$levelId', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            if (unlocked)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < 3; i++)
                    Icon(
                      i < stars ? Icons.star : Icons.star_border,
                      size: 16,
                      color: i < stars ? Colors.amber : null,
                    ),
                ],
              )
            else
              const Icon(Icons.lock, size: 18),
          ],
        ),
      ),
    );
  }
}
