import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/game_controller.dart';
import '../../controllers/progress_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../core/strings.dart';
import '../animation/pour_animator.dart';
import '../animation/win_confetti.dart';
import '../widgets/game_toolbar.dart';
import '../widgets/stuck_dialog.dart';
import '../widgets/tubes_board.dart';
import '../widgets/win_dialog.dart';

/// The playable screen: tube board + toolbar. Moves are committed by
/// `GameController` only after the pour animation ends (PLAN.md §14).
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  static const String routeName = '/game';

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final BoardGeometry _geometry = BoardGeometry();
  late final PourAnimator _animator = PourAnimator(
    vsync: this,
    geometry: _geometry,
  );

  GameController? _game;
  bool _dialogOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final game = context.read<GameController>();
    if (!identical(game, _game)) {
      _game?.removeListener(_handleGameChanged);
      _game = game..addListener(_handleGameChanged);
    }
    game.playPourAnimation = _animator.play;
    _animator.onPourStart = game.playPourSound;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Backgrounded mid-animation: finish it and commit the move immediately
    // (PLAN.md §18 item 13).
    if (state != AppLifecycleState.resumed) {
      _animator.finishNow();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _game
      ?..removeListener(_handleGameChanged)
      ..playPourAnimation = null;
    _animator
      ..onPourStart = null
      ..dispose();
    super.dispose();
  }

  void _handleGameChanged() {
    final game = _game;
    if (game == null) return;
    if (game.status == GameStatus.playing) {
      _dialogOpen = false;
      return;
    }
    if (_dialogOpen) return;

    _dialogOpen = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (game.status == GameStatus.playing) {
        _dialogOpen = false;
        return;
      }
      unawaited(
        game.status == GameStatus.won
            ? _openWinDialog(game)
            : _openStuckDialog(game),
      );
    });
  }

  Future<void> _openStuckDialog(GameController game) async {
    final action = await showDialog<StuckDialogAction>(
      context: context,
      barrierDismissible: false,
      builder: (_) => StuckDialog(
        canUndo: game.canUndo,
        canAddExtraTube: game.canAddExtraTube,
      ),
    );
    if (!mounted) return;

    if (action == StuckDialogAction.undo) {
      await game.undo();
    } else if (action == StuckDialogAction.addTube) {
      game.addExtraTube();
    } else if (action == StuckDialogAction.restart) {
      game.restart();
    } else {
      _dialogOpen = false;
    }
  }

  Future<void> _openWinDialog(GameController game) async {
    final level = game.level;
    if (level == null) {
      _dialogOpen = false;
      return;
    }

    final action = await showDialog<WinDialogAction>(
      context: context,
      barrierDismissible: false,
      builder: (_) => WinDialog(
        levelNumber: level.id,
        moves: game.moves,
        par: level.par,
        stars: starsFor(game.moves, level.par),
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
      _dialogOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();
    final strings = stringsFor(context.watch<SettingsController>().locale);
    final level = game.level;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          level == null ? strings.appName : strings.levelTitle(level.id),
        ),
      ),
      body: SafeArea(
        child: game.isStarted
            ? Stack(
                children: [
                  Column(
                    children: [
                      Expanded(
                        child: TubesBoard(
                          animator: _animator,
                          geometry: _geometry,
                        ),
                      ),
                      const GameToolbar(),
                    ],
                  ),
                  if (game.status == GameStatus.won)
                    const Positioned.fill(child: WinConfetti()),
                ],
              )
            : Center(child: Text(strings.noLevels)),
      ),
    );
  }
}
