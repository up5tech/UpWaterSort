import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/settings_controller.dart';
import '../../core/strings.dart';

/// What the player chose in the win dialog.
enum WinDialogAction { replay, nextLevel, menu }

/// Shown when a level is solved.
class WinDialog extends StatelessWidget {
  const WinDialog({
    super.key,
    required this.levelNumber,
    required this.moves,
    required this.par,
    required this.stars,
    required this.canContinue,
  });

  final int levelNumber;
  final int moves;
  final int par;
  final int stars;
  final bool canContinue;

  @override
  Widget build(BuildContext context) {
    final strings = stringsFor(context.watch<SettingsController>().locale);

    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: Text(strings.winTitle(levelNumber)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: _StarRow(stars: stars)),
            const SizedBox(height: 12),
            Text(strings.winStats(moves, par)),
            const SizedBox(height: 4),
            Text(
              strings.stars(stars),
              style: Theme.of(context).textTheme.labelLarge,
            ),
            if (!canContinue)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(strings.allLevelsDone),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(WinDialogAction.menu),
            child: Text(strings.menu),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(WinDialogAction.replay),
            child: Text(strings.replay),
          ),
          if (canContinue)
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(WinDialogAction.nextLevel),
              child: Text(strings.nextLevel),
            ),
        ],
      ),
    );
  }
}

/// Renders three star icons, the first [stars] of them filled in.
class _StarRow extends StatelessWidget {
  const _StarRow({required this.stars});

  final int stars;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < 3; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 40,
              color: i < stars
                  ? Colors.amberAccent
                  : scheme.onSurface.withValues(alpha: 0.3),
            ),
          ),
      ],
    );
  }
}
