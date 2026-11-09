import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/settings_controller.dart';
import '../../core/strings.dart';

/// What the player chose in the stuck dialog (PLAN.md §2.4).
enum StuckDialogAction { undo, addTube, restart }

/// Shown when no legal move remains: the player must undo, add an extra tube
/// or restart. Leaving the level is handled by the AppBar back button once the
/// dialog is resolved.
class StuckDialog extends StatelessWidget {
  const StuckDialog({
    super.key,
    required this.canUndo,
    required this.canAddExtraTube,
  });

  final bool canUndo;
  final bool canAddExtraTube;

  @override
  Widget build(BuildContext context) {
    final strings = stringsFor(context.watch<SettingsController>().locale);

    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: Text(strings.stuckTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Icon(
                Icons.error_outline,
                size: 40,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 12),
            Text(strings.stuckBody),
          ],
        ),
        actions: [
          TextButton(
            onPressed: canUndo
                ? () => Navigator.of(context).pop(StuckDialogAction.undo)
                : null,
            child: Text(strings.undo),
          ),
          TextButton(
            onPressed: canAddExtraTube
                ? () => Navigator.of(context).pop(StuckDialogAction.addTube)
                : null,
            child: Text(strings.addTube),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pop(StuckDialogAction.restart),
            child: Text(strings.restart),
          ),
        ],
      ),
    );
  }
}
