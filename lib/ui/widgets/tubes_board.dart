import 'dart:math' show max, min;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/game_controller.dart';
import '../../core/palette.dart';
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
      builder: (context, _) => _buildBoard(game),
    );
  }

  Widget _buildBoard(GameController game) {
    final tubeCount = game.tubes.length;
    if (tubeCount == 0) return const SizedBox.shrink();

    final perRow = tubeCount <= 5 ? tubeCount : (tubeCount + 1) ~/ 2;
    final rowCount = (tubeCount + perRow - 1) ~/ perRow;

    return LayoutBuilder(
      builder: (context, constraints) {
        final ratio = game.capacity * 0.9 + 0.6;

        // Reserve headroom for the selected tube and keep the height budget
        // honest so eight tubes still fit on a small phone.
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
        final tubeWidth = min(widthLimit, heightLimit).clamp(24.0, 64.0);
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

        return SizedBox.expand(
          child: Stack(
            children: [
              for (var i = 0; i < tubeCount; i++)
                Positioned.fromRect(
                  rect: rects[i]!,
                  child: _tube(game, i, tubeWidth, tubeHeight, lift),
                ),
              if (animating && pourColor != null)
                _flyingTube(animator!, game.capacity, pourColor),
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
    double lift,
  ) {
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
      hidden: isSource,
      extraLayerColor: extraColor,
      extraLayerFraction: extraFraction,
      onTap: () => game.onTubeTap(index),
    );
  }

  Widget _flyingTube(PourAnimator animation, int capacity, int pourColor) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _StreamPainter(
                  start: animation.streamStart,
                  end: animation.streamEnd,
                  color: kPalette[pourColor],
                  opacity: animation.streamOpacity,
                  width: animation.flyingRect.width * 0.16,
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
                    colorBlind: false,
                    complete: false,
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

class _StreamPainter extends CustomPainter {
  const _StreamPainter({
    required this.start,
    required this.end,
    required this.color,
    required this.opacity,
    required this.width,
  });

  final Offset start;
  final Offset end;
  final Color color;
  final double opacity;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;

    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(start.dx, end.dy, end.dx, end.dy);

    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _StreamPainter oldDelegate) =>
      oldDelegate.start != start ||
      oldDelegate.end != end ||
      oldDelegate.color != color ||
      oldDelegate.opacity != opacity ||
      oldDelegate.width != width;
}
