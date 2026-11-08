import 'package:flutter/material.dart';

/// What the player chose in the win dialog.
enum WinDialogAction { replay, nextLevel, menu }

/// Shown when a level is solved. Stars are added in Phase 3.
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
    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: Text('Level $levelNumber complete!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Moves: $moves   Par: $par'),
            if (!canContinue)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text('You finished all the bundled levels.'),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(WinDialogAction.menu),
            child: const Text('Menu'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(WinDialogAction.replay),
            child: const Text('Replay'),
          ),
          if (canContinue)
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(WinDialogAction.nextLevel),
              child: const Text('Next level'),
            ),
        ],
      ),
    );
  }
}
