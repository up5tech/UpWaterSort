import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/game_controller.dart';
import 'tube_painter.dart';

/// One tappable tube. Reads its own slice of [GameController] state so that a
/// tap only repaints the affected tubes (the parent is wrapped in a
/// `RepaintBoundary`).
class TubeWidget extends StatelessWidget {
  const TubeWidget({
    super.key,
    required this.index,
    required this.width,
    required this.height,
  });

  final int index;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();
    final selected = game.selected == index;

    return RepaintBoundary(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => game.onTubeTap(index),
        child: Semantics(
          button: true,
          selected: selected,
          label: 'Tube ${index + 1}',
          child: SizedBox(
            width: width,
            height: height,
            child: CustomPaint(
              painter: TubePainter(
                layers: game.tubes[index],
                capacity: game.capacity,
                selected: selected,
                colorBlind: false,
                complete: game.isComplete(index),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
