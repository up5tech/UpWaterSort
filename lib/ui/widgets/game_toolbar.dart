import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/game_controller.dart';

/// Undo / Restart plus the move counter. Hint and "Add tube" arrive in Phase 5.
class GameToolbar extends StatelessWidget {
  const GameToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 4,
        children: [
          TextButton.icon(
            onPressed: game.canUndo ? game.undo : null,
            icon: const Icon(Icons.undo),
            label: const Text('Undo'),
          ),
          TextButton.icon(
            onPressed: game.isStarted ? game.restart : null,
            icon: const Icon(Icons.restart_alt),
            label: const Text('Restart'),
          ),
          Text(
            'Moves ${game.moves}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}
