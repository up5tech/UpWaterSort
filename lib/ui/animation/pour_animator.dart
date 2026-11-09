import 'dart:async';
import 'dart:math' show cos, max, min, sin;

import 'package:flutter/material.dart';

import '../../core/tube_metrics.dart';
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
  bool _pourAnnounced = false;

  /// Called once per pour when the liquid actually starts leaving the tube, so
  /// the pour sound lines up with the stream instead of the tap.
  VoidCallback? onPourStart;

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

  /// How far the tube is tilted, 0..1 (it straightens again on the way back).
  double get tiltAmount => (tiltT - returnT).clamp(0.0, 1.0);

  /// Lip of the tilted source tube: the lowest point of its mouth, i.e. where
  /// the liquid actually leaves the glass.
  Offset get streamOrigin {
    final rect = flyingRect;
    if (rect == Rect.zero) return Offset.zero;

    // The mouth's leaning corner, rotated around the mouth centre (the pivot
    // the tube tilts on): with the barrel on the opposite side this corner is
    // the lowest point of the opening.
    final corner = Offset(-_lean * rect.width / 2, 0);
    final angle = tiltAngle;
    return rect.topCenter +
        Offset(
          corner.dx * cos(angle) - corner.dy * sin(angle),
          corner.dx * sin(angle) + corner.dy * cos(angle),
        );
  }

  /// Side the barrel leans to while pouring: +1 for the right, -1 for the
  /// left. It always points towards the middle of the board, so a tube pouring
  /// into a column near one edge still lies inside the board instead of running
  /// off the screen.
  double get _lean {
    final move = _move;
    if (move == null) return 1;
    final target = geometry.rects[move.to];
    if (target == null) return 1;

    var minLeft = double.infinity;
    var maxRight = double.negativeInfinity;
    for (final rect in geometry.rects.values) {
      minLeft = min(minLeft, rect.left);
      maxRight = max(maxRight, rect.right);
    }
    final middle = (minLeft + maxRight) / 2;
    return target.center.dx >= middle ? -1 : 1;
  }

  /// How far the tube leans while pouring, in radians.
  static const double _maxTilt = 0.66;

  Rect get fromRect => _rect(_move?.from);

  Rect get toRect => _rect(_move?.to);

  Rect _rect(int? index) {
    if (index == null) return Rect.zero;
    return geometry.rects[index] ?? Rect.zero;
  }

  /// The source tube's position while it pours: its lip ends up right above
  /// the middle of the target's mouth, so the liquid falls straight in.
  ///
  /// The tube tilts around the centre of its mouth, so the mouth is placed by
  /// working backwards from where the lip should be at full tilt.
  Rect _pourRect(Rect start, Rect target) {
    final width = start.width;
    final lean = _lean;

    // Lip just above the target's rim, centred on its opening.
    final lip = Offset(target.center.dx, target.top - target.height * 0.03);
    final mouth = Offset(
      lip.dx + lean * width / 2 * cos(_maxTilt),
      lip.dy - width / 2 * sin(_maxTilt),
    );

    return Rect.fromLTWH(mouth.dx - width / 2, mouth.dy, width, start.height);
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

  /// Tilt in radians; positive leans the barrel to the left, negative to the
  /// right. It straightens again on the way back.
  double get tiltAngle {
    if (_move == null) return 0;
    final amount = (tiltT - returnT).clamp(0.0, 1.0);
    return -_lean * _maxTilt * amount;
  }

  /// Stream opacity: fades in at the start of the pour, out at the end.
  double get streamOpacity {
    final t = pourT;
    if (t <= 0 || t >= 1) return 0;
    return max(0, (t * 8).clamp(0.0, 1.0) * ((1 - t) * 8).clamp(0.0, 1.0));
  }

  /// Liquid surface of the target tube while it fills, in board coordinates.
  /// Falls back to the rim before the pour starts.
  Offset streamImpact(int capacity) {
    final target = toRect;
    if (target == Rect.zero) return Offset.zero;
    final move = _move;
    final before = _before;
    if (move == null || before == null) return target.topCenter;

    final usableTop = tubeUsableTop(target.width, target.height);
    final layerHeight = (target.height - usableTop) / capacity;
    final filled = before[move.to].length + move.count * pourFraction;
    final y = (target.bottom - filled * layerHeight).clamp(
      target.top + usableTop,
      target.bottom - target.width * 0.1,
    );
    // Drop straight down from the lip: the stream should look like it is
    // falling into the mouth, not arcing across it.
    final x = streamOrigin.dx.clamp(
      target.left + target.width * 0.14,
      target.right - target.width * 0.14,
    );
    return Offset(x, y);
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
    _pourAnnounced = false;
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

  void _handleTick() {
    if (!_pourAnnounced && _move != null && _t >= 0.5) {
      _pourAnnounced = true;
      onPourStart?.call();
    }
    notifyListeners();
  }

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
