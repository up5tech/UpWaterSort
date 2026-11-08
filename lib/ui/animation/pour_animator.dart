import 'dart:async';
import 'dart:math' show max;

import 'package:flutter/material.dart';

import '../../domain/models/move.dart';

/// Board-local positions of the tubes, written by `TubesBoard` on every layout
/// and read by [PourAnimator] when a pour starts.
class BoardGeometry {
  final Map<int, Rect> rects = <int, Rect>{};
}

/// Runs the pour timeline of PLAN.md §14.2: travel, tilt, pour, return.
///
/// The controller stays on the pre-move board until the animation finishes
/// (the game state is committed by `GameController` after this future
/// resolves). Its per-frame values drive the fake liquid levels and the
/// flying tube drawn by `TubesBoard`.
class PourAnimator extends ChangeNotifier {
  PourAnimator({required TickerProvider vsync, required this.geometry})
    : _controller = AnimationController(
        vsync: vsync,
        duration: const Duration(milliseconds: 900),
      ) {
    _controller.addListener(_handleTick);
  }

  static const Duration duration = Duration(milliseconds: 900);

  final BoardGeometry geometry;
  final AnimationController _controller;

  Move? _move;
  Tubes? _before;
  Completer<void>? _completer;
  bool _disposed = false;

  Move? get move => _move;

  Tubes? get before => _before;

  bool get isAnimating => _move != null;

  double get _t => _controller.value;

  /// 0 → 1 while the source tube travels above the target.
  double get travelT =>
      const Interval(0, 0.28, curve: Curves.easeInOut).transform(_t);

  /// 0 → 1 while the tube tilts.
  double get tiltT =>
      const Interval(0.28, 0.5, curve: Curves.easeInOut).transform(_t);

  /// 0 → 1 while liquid is poured; linear so the levels move evenly.
  double get pourT => const Interval(0.5, 0.8).transform(_t);

  /// 0 → 1 while the tube tilts back and returns to its slot.
  double get returnT =>
      const Interval(0.8, 1, curve: Curves.easeInOut).transform(_t);

  double get pourFraction => pourT;

  Rect get fromRect => _rect(_move?.from);

  Rect get toRect => _rect(_move?.to);

  Rect _rect(int? index) {
    if (index == null) return Rect.zero;
    return geometry.rects[index] ?? Rect.zero;
  }

  /// The source tube's position while it pours: next to the target, at the
  /// same height, on the side it came from.
  Rect _pourRect(Rect start, Rect target) {
    final fromLeft = target.center.dx >= start.center.dx;
    final left = fromLeft
        ? target.left - start.width * 0.85
        : target.right - start.width * 0.15;
    return Rect.fromLTWH(left, target.top, start.width, start.height);
  }

  Rect get flyingRect {
    final move = _move;
    if (move == null) return Rect.zero;
    final start = geometry.rects[move.from];
    final target = geometry.rects[move.to];
    if (start == null || target == null) return Rect.zero;

    final end = _pourRect(start, target);
    if (returnT > 0) {
      return Rect.lerp(end, start, returnT)!;
    }
    return Rect.lerp(start, end, travelT)!;
  }

  /// Tilt in radians; it leans towards the target and straightens on return.
  double get tiltAngle {
    final move = _move;
    if (move == null) return 0;
    final start = geometry.rects[move.from];
    final target = geometry.rects[move.to];
    if (start == null || target == null) return 0;

    final sign = target.center.dx >= start.center.dx ? 1.0 : -1.0;
    final amount = (tiltT - returnT).clamp(0.0, 1.0);
    return sign * 1.1 * amount;
  }

  Offset get streamStart => flyingRect.topCenter;

  Offset get streamEnd => toRect.topCenter;

  /// Stream opacity: fades in at the start of the pour, out at the end.
  double get streamOpacity {
    final t = pourT;
    if (t <= 0 || t >= 1) return 0;
    return max(0, (t * 8).clamp(0.0, 1.0) * ((1 - t) * 8).clamp(0.0, 1.0));
  }

  int? get pourColor {
    final move = _move;
    final before = _before;
    if (move == null || before == null) return null;
    final source = before[move.from];
    return source.isEmpty ? null : source.last;
  }

  /// Remaining levels in the flying source tube, already reduced by the part
  /// that has left it.
  List<int> get flyingLayers {
    final move = _move;
    final before = _before;
    if (move == null || before == null) return const <int>[];

    final removed = move.count * pourFraction;
    final keep = before[move.from].length - removed.floor();
    return before[move.from].sublist(0, keep < 0 ? 0 : keep);
  }

  /// Fraction of the flying tube's last layer that is still there.
  double get flyingTopFraction {
    final move = _move;
    if (move == null) return 0;
    final removed = move.count * pourFraction;
    final fraction = removed - removed.floor();
    return fraction == 0 ? 1 : 1 - fraction;
  }

  /// Plays one pour. Resolves once the flying tube is back in its slot (or the
  /// animation is cut short by [finishNow] / dispose).
  Future<void> play(Move move, Tubes before) async {
    if (_move != null) return;

    _move = move;
    _before = before;
    final completer = _completer = Completer<void>();
    notifyListeners();

    unawaited(
      _controller.forward(from: 0).whenComplete(() {
        if (!completer.isCompleted) completer.complete();
      }),
    );
    await completer.future;

    _move = null;
    _before = null;
    if (!_disposed) notifyListeners();
  }

  /// Jumps to the end of the animation (app backgrounded, or the screen is
  /// leaving). The game commits the move immediately afterwards.
  void finishNow() {
    if (_move == null) return;
    _controller.stop();
    final completer = _completer;
    if (completer != null && !completer.isCompleted) completer.complete();
  }

  void _handleTick() => notifyListeners();

  @override
  void dispose() {
    _disposed = true;
    _controller.removeListener(_handleTick);
    _controller.dispose();
    final completer = _completer;
    if (completer != null && !completer.isCompleted) completer.complete();
    super.dispose();
  }
}
