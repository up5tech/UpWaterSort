import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/level_repository.dart';
import '../domain/game_rules.dart';
import '../domain/models/level_data.dart';
import '../domain/models/move.dart';
import '../domain/models/save_data.dart';
import 'progress_controller.dart';

enum GameStatus { playing, won, stuck }

/// Owns the state of the level being played: tubes, selection, history, move
/// count and win/stuck status. Every committed state is persisted as the
/// in-progress game; a win is reported to [ProgressController].
class GameController extends ChangeNotifier {
  GameController({required this.levels, required this.progress});

  final LevelRepository levels;
  final ProgressController progress;

  LevelData? _level;
  Tubes _tubes = const <List<int>>[];
  int _capacity = 4;
  int? _selected;
  int _moves = 0;
  bool _busy = false;
  bool _extraTubeUsed = false;
  GameStatus _status = GameStatus.playing;
  final List<Move> _history = <Move>[];

  bool get isStarted => _level != null;

  LevelData? get level => _level;

  Tubes get tubes => _tubes;

  int get capacity => _capacity;

  int? get selected => _selected;

  int get moves => _moves;

  /// Locks input while a pour animation runs (wired in Phase 4).
  bool get busy => _busy;

  GameStatus get status => _status;

  bool get canUndo => _history.isNotEmpty && !_busy;

  bool get hasNextLevel {
    final current = _level;
    return current != null && levels.hasNext(current.id);
  }

  /// Runs the pouring animation before the move is committed. Phase 2 leaves
  /// this unset, so the board updates instantly; Phase 4 assigns it.
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

    // 1. Nothing selected yet -> select the source tube.
    if (_selected == null) {
      if (_tubes[index].isEmpty) return;
      _selected = index;
      notifyListeners();
      return;
    }

    // 2. Tapping the selected tube again deselects it.
    if (_selected == index) {
      _selected = null;
      notifyListeners();
      return;
    }

    final from = _selected!;

    // 3. Invalid move: switch selection to a non-empty target, otherwise keep
    //    the current selection (PLAN.md §18 items 4 and 5).
    if (!canPour(_tubes, from, index, _capacity)) {
      if (_tubes[index].isNotEmpty) {
        _selected = index;
      }
      notifyListeners();
      return;
    }

    // 4. Valid move: lock input, animate, then commit the new state.
    final move = Move(from, index, pourCount(_tubes, from, index, _capacity));
    _busy = true;
    _selected = null;
    notifyListeners();

    final before = _tubes;
    await playPourAnimation?.call(move, before);

    _tubes = applyMove(_tubes, move);
    _history.add(move);
    _moves = _history.length;
    _busy = false;

    if (isWon(_tubes, _capacity)) {
      _status = GameStatus.won;
      await progress.completeLevel(_level!, _moves);
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
    await _persistInProgress();
    notifyListeners();
  }

  void restart() {
    final current = _level;
    if (current == null) return;
    startLevel(current);
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
