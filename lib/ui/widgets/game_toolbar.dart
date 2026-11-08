import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/game_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../core/strings.dart';

/// Undo / Restart / Hint / Add tube and the move counter
/// (PLAN.md §12.2).
class GameToolbar extends StatelessWidget {
  const GameToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();
    final strings = stringsFor(context.watch<SettingsController>().locale);
    final hinting = game.hintLoading;

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
            label: Text(strings.undo),
          ),
          TextButton.icon(
            onPressed: game.isStarted ? game.restart : null,
            icon: const Icon(Icons.restart_alt),
            label: Text(strings.restart),
          ),
          TextButton.icon(
            onPressed:
                game.isStarted &&
                    !game.busy &&
                    !hinting &&
                    game.status == GameStatus.playing
                ? () => _showHint(context, strings)
                : null,
            icon: hinting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.lightbulb_outline),
            label: Text(strings.hint),
          ),
          TextButton.icon(
            onPressed: game.canAddExtraTube ? game.addExtraTube : null,
            icon: const Icon(Icons.add),
            label: Text(strings.addTube),
          ),
          Text(
            strings.moves(game.moves),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  Future<void> _showHint(BuildContext context, AppStrings strings) async {
    final game = context.read<GameController>();
    final messenger = ScaffoldMessenger.of(context);
    final found = await game.requestHint();
    if (!context.mounted) return;

    final hint = game.hint;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            found && hint != null
                ? strings.hintMove(hint.from + 1, hint.to + 1)
                : strings.hintUnavailable,
          ),
          duration: const Duration(seconds: 2),
        ),
      );
  }
}
