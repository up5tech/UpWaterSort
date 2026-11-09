import 'dart:math' show cos, max, min, pi, sin;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/game_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../core/palette.dart';
import '../../core/strings.dart';
import '../animation/pour_animator.dart';
import 'tube_painter.dart';
import 'tube_widget.dart';

/// Lays the tubes out in one row (n <= 5) or two rows (n > 5), sizes them from
/// the available space (PLAN.md §12.3) and draws the pour animation on top.
class TubesBoard extends StatelessWidget {
  const TubesBoard({super.key, this.animator, this.geometry});

  static const double _gap = 12;
  static const double _rowGap = 24;

  final PourAnimator? animator;
  final BoardGeometry? geometry;

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();
    final listenable = animator ?? const AlwaysStoppedAnimation<double>(0);

    return ListenableBuilder(
      listenable: listenable,
      builder: (context, _) => _buildBoard(context, game),
    );
  }

  Widget _buildBoard(BuildContext context, GameController game) {
    final settings = context.watch<SettingsController>();
    final strings = stringsFor(settings.locale);
    final hint = game.hint;
    final tubeCount = game.tubes.length;
    if (tubeCount == 0) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final ratio = game.capacity * 0.9 + 0.6;

        ({int perRow, int rowCount, double tubeWidth}) layout(int rowCount) {
          final perRow = (tubeCount + rowCount - 1) ~/ rowCount;
          // Reserve headroom for the selected tube and keep the height budget
          // honest so the widest supported board still fits a small phone.
          final widthLimit =
              ((constraints.maxWidth - _gap * (perRow - 1)) / perRow).clamp(
                36.0,
                64.0,
              );
          final liftRoom = widthLimit * 0.5;
          final heightLimit = constraints.maxHeight.isFinite
              ? (constraints.maxHeight - liftRoom - _rowGap * (rowCount - 1)) /
                    rowCount /
                    ratio
              : widthLimit;
          return (
            perRow: perRow,
            rowCount: rowCount,
            tubeWidth: min(widthLimit, heightLimit).clamp(24.0, 64.0),
          );
        }

        // Two rows for most boards; the 17–18 tube boards are wider than two
        // phone rows can hold, so use three rows when that keeps tubes bigger.
        final baseRows = tubeCount <= 5 ? 1 : 2;
        var chosen = layout(baseRows);
        if (baseRows == 2) {
          final threeRows = layout(3);
          if (threeRows.tubeWidth > chosen.tubeWidth) chosen = threeRows;
        }

        final perRow = chosen.perRow;
        final rowCount = chosen.rowCount;
        final tubeWidth = chosen.tubeWidth;
        final tubeHeight = tubeWidth * ratio;
        final lift = tubeWidth * 0.5;

        final blockWidth = perRow * tubeWidth + _gap * (perRow - 1);
        final blockHeight = rowCount * tubeHeight + _rowGap * (rowCount - 1);
        final left = (constraints.maxWidth - blockWidth) / 2;
        final top = constraints.maxHeight.isFinite
            ? lift + max(0.0, (constraints.maxHeight - lift - blockHeight) / 2)
            : lift;

        final rects = <int, Rect>{};
        for (var i = 0; i < tubeCount; i++) {
          rects[i] = Rect.fromLTWH(
            left + (i % perRow) * (tubeWidth + _gap),
            top + (i ~/ perRow) * (tubeHeight + _rowGap),
            tubeWidth,
            tubeHeight,
          );
        }
        final target = geometry;
        if (target != null) {
          target.rects
            ..clear()
            ..addAll(rects);
        }

        final move = animator?.move;
        final before = animator?.before;
        final animating = move != null && before != null;
        final pourColor = animator?.pourColor;

        // The selected tube rises by `lift` and can overlap the row above or
        // below, so paint it last: it must never be cut off by a neighbour.
        final selected = game.selected;
        final order = <int>[
          for (var i = 0; i < tubeCount; i++)
            if (i != selected) i,
          if (selected != null && selected >= 0 && selected < tubeCount)
            selected,
        ];

        return SizedBox.expand(
          child: Stack(
            children: [
              for (final i in order)
                Positioned.fromRect(
                  key: ValueKey<int>(i),
                  rect: rects[i]!,
                  child: _tube(
                    game,
                    i,
                    tubeWidth,
                    tubeHeight,
                    lift,
                    colorBlind: settings.colorBlind,
                    tubeLabel: strings.tubeLabel(i + 1),
                    hinted: hint != null && (hint.from == i || hint.to == i),
                  ),
                ),
              if (animating && pourColor != null)
                _flyingTube(
                  context,
                  animator!,
                  game.capacity,
                  pourColor,
                  settings.colorBlind,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _tube(
    GameController game,
    int index,
    double tubeWidth,
    double tubeHeight,
    double lift, {
    required bool colorBlind,
    required String tubeLabel,
    required bool hinted,
  }) {
    final animation = animator;
    final move = animation?.move;
    final before = animation?.before;
    final isSource = move != null && before != null && move.from == index;

    var layers = game.tubes[index];
    int? extraColor;
    var extraFraction = 0.0;

    if (move != null && before != null && move.to == index) {
      final color = before[move.from].last;
      final added = move.count * animation!.pourFraction;
      final whole = added.floor();
      layers = [...before[move.to], for (var i = 0; i < whole; i++) color];
      extraColor = color;
      extraFraction = added - whole;
    }

    return TubeWidget(
      index: index,
      width: tubeWidth,
      height: tubeHeight,
      layers: layers,
      capacity: game.capacity,
      selected: game.selected == index,
      complete: game.isComplete(index),
      lift: lift,
      colorBlind: colorBlind,
      hinted: hinted,
      semanticsLabel: tubeLabel,
      hidden: isSource,
      extraLayerColor: extraColor,
      extraLayerFraction: extraFraction,
      onTap: () => game.onTubeTap(index),
    );
  }

  Widget _flyingTube(
    BuildContext context,
    PourAnimator animation,
    int capacity,
    int pourColor,
    bool colorBlind,
  ) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _StreamPainter(
                  origin: animation.streamOrigin,
                  impact: animation.streamImpact(capacity),
                  color: kPalette[pourColor],
                  opacity: animation.streamOpacity,
                  width: animation.flyingRect.width * 0.2,
                  progress: animation.pourFraction,
                ),
              ),
            ),
            Positioned.fromRect(
              rect: animation.flyingRect,
              child: Transform.rotate(
                angle: animation.tiltAngle,
                alignment: Alignment.topCenter,
                child: CustomPaint(
                  painter: TubePainter(
                    layers: animation.flyingLayers,
                    capacity: capacity,
                    selected: false,
                    colorBlind: colorBlind,
                    complete: false,
                    outlineColor: tubeOutlineColor(
                      Theme.of(context).brightness,
                      Theme.of(context).colorScheme,
                    ),
                    glowColor: tubeGlowColor(
                      Theme.of(context).brightness,
                      Theme.of(context).colorScheme,
                    ),
                    topLayerFraction: animation.flyingTopFraction,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Draws the falling stream plus what it does when it hits the surface: an
/// expanding ripple on the liquid and a few droplets thrown up around it.
class _StreamPainter extends CustomPainter {
  const _StreamPainter({
    required this.origin,
    required this.impact,
    required this.color,
    required this.opacity,
    required this.width,
    required this.progress,
  });

  /// Mouth of the tilted source tube.
  final Offset origin;

  /// Point where the stream lands, i.e. the target's current liquid surface.
  final Offset impact;
  final Color color;
  final double opacity;

  /// Width of the stream at its widest, just below the lip.
  final double width;

  /// 0 → 1 across the pour phase; drives the wobble and the splash animation.
  final double progress;

  static const int _steps = 40;

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0 || origin == Offset.zero || impact == Offset.zero) return;

    final dx = impact.dx - origin.dx;
    final dy = impact.dy - origin.dy;
    // Water leaves the mouth at an angle and lands almost vertically, so the
    // curve is slow at first and steep at the end.
    final c1 = Offset(origin.dx + dx * 0.25, origin.dy + dy * 0.45);
    final c2 = Offset(impact.dx, impact.dy - dy * 0.5);

    final centers = <Offset>[];
    final halves = <double>[];
    for (var i = 0; i <= _steps; i++) {
      final u = i / _steps;
      final point = _cubic(origin, c1, c2, impact, u);
      // A thin, winding ribbon: a higher-frequency sine travelling down the
      // stream makes several gentle bends ("uốn lượn") instead of a stiff
      // stripe. The larger amplitude (relative to the now-thinner width) keeps
      // the meander clearly visible.
      final wobble = sin(u * 7.0 - progress * 6.5) * width * 0.6 * u;
      centers.add(Offset(point.dx + wobble, point.dy));
      // Narrow at the lip, full just below it, then necking in as it falls —
      // a constant-width bar reads as a painted stripe rather than water.
      // Kept slimmer overall so the stream stays a thin thread of water.
      final profile = 0.55 + 0.28 * sin(u * pi * 0.85);
      halves.add(width * profile / 2);
    }

    final path = Path()
      ..moveTo(centers.first.dx - halves.first, centers.first.dy);
    for (var i = 1; i <= _steps; i++) {
      path.lineTo(centers[i].dx - halves[i], centers[i].dy);
    }
    for (var i = _steps; i >= 0; i--) {
      path.lineTo(centers[i].dx + halves[i], centers[i].dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color.withValues(alpha: opacity));

    // Bright core so the stream reads as moving water rather than a stripe.
    final core = Path()..moveTo(centers.first.dx, centers.first.dy);
    for (var i = 1; i <= _steps; i++) {
      core.lineTo(centers[i].dx, centers[i].dy);
    }
    canvas.drawPath(
      core,
      Paint()
        ..color = Colors.white.withValues(alpha: opacity * 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = width * 0.26
        ..strokeCap = StrokeCap.round,
    );

    _paintSplash(canvas);
  }

  /// Ripples and droplets around [impact].
  void _paintSplash(Canvas canvas) {
    // Pale, flattened splash where the stream meets the surface.
    canvas.drawOval(
      Rect.fromCenter(
        center: impact,
        width: width * 1.15,
        height: width * 0.36,
      ),
      Paint()..color = Colors.white.withValues(alpha: opacity * 0.26),
    );

    for (var ring = 0; ring < 2; ring++) {
      final s = (progress * 2.4 + ring * 0.5) % 1.0;
      // Kept inside the target's walls: a ripple wider than the tube would
      // spill over its outline.
      final radiusX = width * (0.5 + 1.15 * s);
      final radiusY = radiusX * 0.32;
      canvas.drawOval(
        Rect.fromCenter(
          center: impact,
          width: radiusX * 2,
          height: radiusY * 2,
        ),
        Paint()
          ..color = color.withValues(alpha: opacity * (1 - s) * 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = width * 0.16 * (1 - s * 0.6),
      );
    }

    // Droplets thrown up and out, each on its own little ballistic arc: they
    // rise, slow down and fall back into the surface by the end of their life.
    const dropletCount = 8;
    final dropletColor = Color.lerp(color, Colors.white, 0.22)!;
    for (var k = 0; k < dropletCount; k++) {
      final t = (progress * 3.1 + k * 0.37) % 1.0;
      final alpha = opacity * (1 - t) * 0.95;
      if (alpha <= 0.02) continue;

      final angle = -1.35 + k * (2.7 / (dropletCount - 1));
      final lift = width * (1.5 + (k % 3) * 0.35);
      final center = Offset(
        impact.dx + sin(angle) * lift * 1.15 * t,
        impact.dy - cos(angle) * lift * t + lift * t * t,
      );
      final r = width * 0.14 * (1 - 0.4 * t);
      canvas.drawOval(
        Rect.fromCenter(center: center, width: r * 1.5, height: r * 2.2),
        Paint()..color = dropletColor.withValues(alpha: alpha),
      );
    }
  }

  static Offset _cubic(Offset a, Offset b, Offset c, Offset d, double u) {
    final v = 1 - u;
    return Offset(
      v * v * v * a.dx +
          3 * v * v * u * b.dx +
          3 * v * u * u * c.dx +
          u * u * u * d.dx,
      v * v * v * a.dy +
          3 * v * v * u * b.dy +
          3 * v * u * u * c.dy +
          u * u * u * d.dy,
    );
  }

  @override
  bool shouldRepaint(covariant _StreamPainter oldDelegate) =>
      oldDelegate.origin != origin ||
      oldDelegate.impact != impact ||
      oldDelegate.color != color ||
      oldDelegate.opacity != opacity ||
      oldDelegate.width != width ||
      oldDelegate.progress != progress;
}
