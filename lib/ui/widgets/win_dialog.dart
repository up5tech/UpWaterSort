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
    required this.canContinue,
  });

  final int levelNumber;
  final int moves;
  final int par;
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
            Text(strings.winStats(moves, par)),
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
