import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/game_controller.dart';
import '../widgets/game_toolbar.dart';
import '../widgets/tubes_board.dart';
import '../widgets/win_dialog.dart';

/// The playable screen: tube board + toolbar. Phase 2 commits every move
/// instantly; pouring animation arrives in Phase 4.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  static const String routeName = '/game';

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  GameController? _game;
  bool _winDialogOpen = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final game = context.read<GameController>();
    if (!identical(game, _game)) {
      _game?.removeListener(_handleGameChanged);
      _game = game..addListener(_handleGameChanged);
    }
  }

  @override
  void dispose() {
    _game?.removeListener(_handleGameChanged);
    super.dispose();
  }

  void _handleGameChanged() {
    final game = _game;
    if (game == null) return;
    if (game.status == GameStatus.playing) {
      _winDialogOpen = false;
      return;
    }
    if (game.status != GameStatus.won || _winDialogOpen) return;

    _winDialogOpen = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_openWinDialog(game));
    });
  }

  Future<void> _openWinDialog(GameController game) async {
    final level = game.level;
    if (level == null) {
      _winDialogOpen = false;
      return;
    }

    final action = await showDialog<WinDialogAction>(
      context: context,
      barrierDismissible: false,
      builder: (_) => WinDialog(
        levelNumber: level.id,
        moves: game.moves,
        par: level.par,
        canContinue: game.hasNextLevel,
      ),
    );
    if (!mounted) return;

    if (action == WinDialogAction.replay) {
      game.restart();
    } else if (action == WinDialogAction.nextLevel) {
      game.nextLevel();
    } else if (action == WinDialogAction.menu) {
      Navigator.of(context).pop();
    } else {
      _winDialogOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();
    final level = game.level;

    return Scaffold(
      appBar: AppBar(
        title: Text(level == null ? 'UpWaterSort' : 'Level ${level.id}'),
      ),
      body: SafeArea(
        child: game.isStarted
            ? Column(
                children: [
                  const Expanded(child: TubesBoard()),
                  if (game.status == GameStatus.stuck) const _StuckBanner(),
                  const GameToolbar(),
                ],
              )
            : const Center(child: Text('No levels available.')),
      ),
    );
  }
}

class _StuckBanner extends StatelessWidget {
  const _StuckBanner();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        'No moves left. Undo or restart.',
        style: Theme.of(context).textTheme.bodyMedium,
        textAlign: TextAlign.center,
      ),
    );
  }
}
