import 'dart:math' show min;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/game_controller.dart';
import 'tube_widget.dart';

/// Lays the tubes out in one row (n <= 5) or two rows (n > 5) and sizes them
/// from the available space (PLAN.md §12.3).
class TubesBoard extends StatelessWidget {
  const TubesBoard({super.key});

  static const double _gap = 12;
  static const double _rowPadding = 16;

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();
    final tubeCount = game.tubes.length;
    if (tubeCount == 0) return const SizedBox.shrink();

    final perRow = tubeCount <= 5 ? tubeCount : (tubeCount + 1) ~/ 2;

    return LayoutBuilder(
      builder: (context, constraints) {
        final rowCount = (tubeCount + perRow - 1) ~/ perRow;
        final ratio = game.capacity * 0.9 + 0.6;

        final widthLimit =
            ((constraints.maxWidth - _gap * (perRow + 1)) / perRow).clamp(
              36.0,
              64.0,
            );
        final heightLimit = constraints.maxHeight.isFinite
            ? (constraints.maxHeight - 2 * _rowPadding * rowCount) /
                  rowCount /
                  ratio
            : widthLimit;
        final tubeWidth = min(widthLimit, heightLimit).clamp(24.0, 64.0);
        final tubeHeight = tubeWidth * ratio;

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var row = 0; row < rowCount; row++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: _rowPadding),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (
                      var i = row * perRow;
                      i < min((row + 1) * perRow, tubeCount);
                      i++
                    )
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: _gap / 2,
                        ),
                        child: TubeWidget(
                          index: i,
                          width: tubeWidth,
                          height: tubeHeight,
                        ),
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
