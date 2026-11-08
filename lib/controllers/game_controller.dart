import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/audio_service.dart';
import '../data/level_repository.dart';
import '../domain/game_rules.dart';
import '../domain/models/level_data.dart';
import '../domain/models/move.dart';
import '../domain/models/save_data.dart';
import '../domain/solver.dart';
import 'progress_controller.dart';
import 'settings_controller.dart';

enum GameStatus { playing, won, stuck }

/// Owns the state of the level being played: tubes, selection, history, move
/// count and win/stuck status. Every committed state is persisted as the
/// in-progress game; a win is reported to [ProgressController].
///
/// [audio] and [settings] are optional so pure controller tests can run
/// without platform services. [hintSolver] is injectable so tests do not need
/// to spawn an isolate.
class GameController extends ChangeNotifier {
  GameController({
    required this.levels,
    required this.progress,
    this.audio,
    this.settings,
    this.hintSolver,
  });

  final LevelRepository levels;
  final ProgressController progress;
  final AudioService? audio;
  final SettingsController? settings;

  /// Overrides the isolate solver in tests; production uses [compute].
  final Future<Move?> Function(Tubes tubes, int capacity)? hintSolver;

  LevelData? _level;
  Tubes _tubes = const <List<int>>[];
  int _capacity = 4;
  int? _selected;
  int _moves = 0;
  bool _busy = false;
  bool _extraTubeUsed = false;
  GameStatus _status = GameStatus.playing;
  final List<Move> _history = <Move>[];

  Move? _hint;
  bool _hintLoading = false;

  /// Bumped on every state change so a slow hint cannot apply to a board that
  /// has moved on (PLAN.md §18 item 12).
  int _version = 0;

  bool get isStarted => _level != null;

  LevelData? get level => _level;

  Tubes get tubes => _tubes;

  int get capacity => _capacity;

  int? get selected => _selected;

  int get moves => _moves;

  /// Locks input while a pour animation runs (Phase 4).
  bool get busy => _busy;

  GameStatus get status => _status;

  /// The extra tube can be added once per attempt (PLAN.md §18 item 14).
  bool get extraTubeUsed => _extraTubeUsed;

  /// Suggested move from the last hint, drawn by the board until the next tap.
  Move? get hint => _hint;

  bool get hintLoading => _hintLoading;

  bool get canUndo => _history.isNotEmpty && !_busy;

  bool get canAddExtraTube =>
      isStarted && _status != GameStatus.won && !_extraTubeUsed && !_busy;

  bool get hasNextLevel {
    final current = _level;
    return current != null && levels.hasNext(current.id);
  }

  /// Runs the pouring animation before the move is committed.
  Future<void> Function(Move move, Tubes before)? playPourAnimation;

  /// True when the tube at [index] is full of a single color.
  bool isComplete(int index) => isTubeComplete(_tubes[index], _capacity);

  /// Loads level [id] from the bundle, resuming the saved game for that level
  /// when one exists. Returns false when the level is missing.
  bool startLevelById(int id) {
    final data = levels.byId(id);
    if (data == null) return false;
    startLevel(data, resume: progress.inProgressFor(id));
    return true;
  }

  void startLevel(LevelData data, {InProgress? resume}) {
    _level = data;
    _capacity = data.capacity;

    if (resume != null && resume.levelId == data.id) {
      _tubes = [for (final tube in resume.tubes) List<int>.of(tube)];
      _history
        ..clear()
        ..addAll(resume.history);
      _extraTubeUsed = resume.extraTubeUsed;
    } else {
      _tubes = [for (final tube in data.tubes) List<int>.of(tube)];
      _history.clear();
      _extraTubeUsed = false;
    }

    _moves = _history.length;
    _selected = null;
    _busy = false;
    _status = GameStatus.playing;
    _hint = null;
    _hintLoading = false;
    _version++;
    unawaited(_persistInProgress());
    notifyListeners();
  }

  /// Advances to the next bundled level. Returns false if there is none.
  bool nextLevel() {
    final current = _level;
    if (current == null) return false;
    final following = levels.next(current.id);
    if (following == null) return false;
    startLevel(following);
    return true;
  }

  Future<void> onTubeTap(int index) async {
    if (_busy || _status != GameStatus.playing || _level == null) return;

    if (_hint != null) {
      _hint = null;
      _version++;
    }

    // 1. Nothing selected yet -> select the source tube.
    if (_selected == null) {
      if (_tubes[index].isEmpty) return;
      _selected = index;
      _version++;
      audio?.play(Sfx.select);
      notifyListeners();
      return;
    }

    // 2. Tapping the selected tube again deselects it.
    if (_selected == index) {
      _selected = null;
      _version++;
      notifyListeners();
      return;
    }

    final from = _selected!;

    // 3. Invalid move: switch selection to a non-empty target, otherwise keep
    //    the current selection (PLAN.md §18 items 4 and 5).
    if (!canPour(_tubes, from, index, _capacity)) {
      if (_tubes[index].isNotEmpty) {
        _selected = index;
        audio?.play(Sfx.select);
      } else {
        audio?.play(Sfx.error);
        settings?.haptic(HapticKind.error);
      }
      _version++;
      notifyListeners();
      return;
    }

    // 4. Valid move: lock input, animate, then commit the new state.
    final move = Move(from, index, pourCount(_tubes, from, index, _capacity));
    _busy = true;
    _selected = null;
    _version++;
    audio?.play(Sfx.pour);
    notifyListeners();

    final before = _tubes;
    await playPourAnimation?.call(move, before);

    _tubes = applyMove(_tubes, move);
    _history.add(move);
    _moves = _history.length;
    _busy = false;

    if (isTubeComplete(_tubes[move.to], _capacity)) {
      audio?.play(Sfx.completeTube);
      settings?.haptic(HapticKind.light);
    }

    if (isWon(_tubes, _capacity)) {
      _status = GameStatus.won;
      await progress.completeLevel(_level!, _moves);
      audio?.play(Sfx.win);
    } else {
      if (!hasAnyMove(_tubes, _capacity)) {
        _status = GameStatus.stuck;
      }
      await _persistInProgress();
    }
    notifyListeners();
  }

  Future<void> undo() async {
    if (!canUndo) return;
    final move = _history.removeLast();
    _tubes = undoMove(_tubes, move);
    _moves = _history.length;
    _selected = null;
    _status = GameStatus.playing;
    _hint = null;
    _version++;
    await _persistInProgress();
    notifyListeners();
  }

  void restart() {
    final current = _level;
    if (current == null) return;
    startLevel(current);
  }

  /// Adds one empty tube, once per attempt. The extra tube is appended last
  /// and is not recorded in the history, so Undo stays correct
  /// (PLAN.md §11.2, §18 item 14).
  bool addExtraTube() {
    if (!canAddExtraTube) return false;
    _tubes = [..._tubes, <int>[]];
    _extraTubeUsed = true;
    _selected = null;
    _hint = null;
    _hintLoading = false;
    _status = GameStatus.playing;
    _version++;
    unawaited(_persistInProgress());
    notifyListeners();
    return true;
  }

  /// Solves the *current* board in an isolate and keeps the first move as a
  /// hint. Returns false when no hint is available within the node cap.
  Future<bool> requestHint() async {
    if (_busy || _hintLoading || _status != GameStatus.playing) return false;
    if (_level == null) return false;

    _hintLoading = true;
    _hint = null;
    final version = ++_version;
    notifyListeners();

    Move? move;
    try {
      final solver = hintSolver;
      move = solver != null
          ? await solver(_tubes, _capacity)
          : await compute(_solveHintTask, _HintRequest(_tubes, _capacity));
    } catch (_) {
      move = null;
    }

    if (version != _version) {
      // Board changed while solving: drop the stale hint.
      _hintLoading = false;
      notifyListeners();
      return false;
    }

    _hintLoading = false;
    _hint = move;
    notifyListeners();
    return move != null;
  }

  Future<void> _persistInProgress() async {
    final current = _level;
    if (current == null) return;
    await progress.saveInProgress(
      InProgress(
        levelId: current.id,
        tubes: [for (final tube in _tubes) List<int>.of(tube)],
        history: List<Move>.of(_history),
        extraTubeUsed: _extraTubeUsed,
      ),
    );
  }
}

class _HintRequest {
  const _HintRequest(this.tubes, this.capacity);

  final Tubes tubes;
  final int capacity;
}

/// Top-level entry point for `compute`; must not capture any state.
Move? _solveHintTask(_HintRequest request) =>
    Solver.solve(request.tubes, request.capacity)?.first;
