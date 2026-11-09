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
  bool _winDialogOpen = false;

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
      _winDialogOpen = false;
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
                      if (game.status == GameStatus.stuck)
                        _StuckBanner(text: strings.noMovesLeft),
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

class _StuckBanner extends StatelessWidget {
  const _StuckBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium,
        textAlign: TextAlign.center,
      ),
    );
  }
}
