import 'package:flutter/material.dart';

import 'tube_painter.dart';

/// Presentation-only tube: draws [layers] and lifts when [selected]. Taps are
/// dispatched by the board.
///
/// The tube fills its body with the screen background (so it occludes the tubes
/// behind it) and casts a soft shadow to separate it from the board.
class TubeWidget extends StatelessWidget {
  const TubeWidget({
    super.key,
    required this.index,
    required this.width,
    required this.height,
    required this.layers,
    required this.capacity,
    required this.selected,
    required this.complete,
    required this.lift,
    this.hinted = false,
    this.semanticsLabel,
    this.colorBlind = false,
    this.topLayerFraction = 1,
    this.extraLayerColor,
    this.extraLayerFraction = 0,
    this.hidden = false,
    this.onTap,
  });

  final int index;
  final double width;
  final double height;
  final List<int> layers;
  final int capacity;
  final bool selected;
  final bool complete;

  /// How far the tube rises when selected.
  final double lift;

  /// Part of the current solver hint.
  final bool hinted;

  /// Localized accessibility label, e.g. "Tube 3".
  final String? semanticsLabel;
  final bool colorBlind;
  final double topLayerFraction;
  final int? extraLayerColor;
  final double extraLayerFraction;

  /// The real tube is hidden while its flying copy is animating.
  final bool hidden;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (hidden) {
      return SizedBox(width: width, height: height);
    }

    final theme = Theme.of(context);
    final outline = tubeOutlineColor(theme.brightness, theme.colorScheme);
    final selectedOutline = tubeSelectedOutlineColor(
      theme.brightness,
      theme.colorScheme,
    );
    final glow = tubeGlowColor(theme.brightness, theme.colorScheme);
    final shadow = TubeShadow.forBrightness(theme.brightness);

    return RepaintBoundary(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, selected ? -lift : 0, 0),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Semantics(
            button: true,
            selected: selected,
            label: semanticsLabel ?? 'Tube ${index + 1}',
            child: SizedBox(
              width: width,
              height: height,
              child: CustomPaint(
                painter: TubePainter(
                  layers: layers,
                  capacity: capacity,
                  selected: selected,
                  colorBlind: colorBlind,
                  complete: complete,
                  outlineColor: outline,
                  selectedOutlineColor: selectedOutline,
                  glowColor: glow,
                  shadow: shadow,
                  hinted: hinted,
                  topLayerFraction: topLayerFraction,
                  extraLayerColor: extraLayerColor,
                  extraLayerFraction: extraLayerFraction,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
