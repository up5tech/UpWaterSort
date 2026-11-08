import 'package:flutter/material.dart';

import '../../core/palette.dart';

/// Draws one tube: glass background, liquid layers (bottom -> top), optional
/// color-blind symbols and an outline that reflects selection/completion.
///
/// [topLayerFraction] and [extraLayer*] let the pour animation show liquid
/// levels that are mid-way between two whole units.
class TubePainter extends CustomPainter {
  const TubePainter({
    required this.layers,
    required this.capacity,
    required this.selected,
    required this.colorBlind,
    required this.complete,
    this.topLayerFraction = 1,
    this.extraLayerColor,
    this.extraLayerFraction = 0,
  });

  final List<int> layers;
  final int capacity;
  final bool selected;
  final bool colorBlind;
  final bool complete;

  /// Visible part of the top layer, 0..1 (1 = whole layer).
  final double topLayerFraction;

  /// A partially poured layer above [layers], drawn with this palette color.
  final int? extraLayerColor;

  /// Height of [extraLayerColor] as a fraction of one layer, 0..1.
  final double extraLayerFraction;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final r = w / 2;

    // Tube outline: open at the top, rounded bottom.
    final tubePath = Path()
      ..moveTo(0, 0)
      ..lineTo(0, h - r)
      ..arcToPoint(
        Offset(w, h - r),
        radius: Radius.circular(r),
        clockwise: false,
      )
      ..lineTo(w, 0);

    // Frosted glass background.
    final glass = Path.from(tubePath)..close();
    canvas.drawPath(
      glass,
      Paint()..color = Colors.white.withValues(alpha: 0.12),
    );

    // Liquid layers, clipped to the tube shape.
    canvas.save();
    canvas.clipPath(glass);

    final usableTop = h * 0.08;
    final layerHeight = (h - usableTop) / capacity;

    for (var i = 0; i < layers.length; i++) {
      final isTop = i == layers.length - 1;
      final fraction = isTop ? topLayerFraction.clamp(0.0, 1.0) : 1.0;
      if (fraction <= 0) continue;

      final bottom = h - i * layerHeight;
      final top = bottom - layerHeight * fraction;
      final rect = Rect.fromLTWH(0, top, w, layerHeight * fraction + 0.5);
      canvas.drawRect(rect, Paint()..color = kPalette[layers[i]]);

      if (colorBlind && fraction > 0.35) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: kSymbols[layers[i]],
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: layerHeight * fraction * 0.55,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        textPainter.paint(
          canvas,
          Offset(
            (w - textPainter.width) / 2,
            top + (layerHeight * fraction - textPainter.height) / 2,
          ),
        );
        textPainter.dispose();
      }
    }

    final extraColor = extraLayerColor;
    final extraFraction = extraLayerFraction.clamp(0.0, 1.0);
    if (extraColor != null && extraFraction > 0) {
      final baseTop = h - layers.length * layerHeight;
      final rect = Rect.fromLTWH(
        0,
        baseTop - layerHeight * extraFraction,
        w,
        layerHeight * extraFraction + 0.5,
      );
      canvas.drawRect(rect, Paint()..color = kPalette[extraColor]);
    }

    // Highlight streak on the left for a glassy look.
    canvas.drawRect(
      Rect.fromLTWH(w * 0.12, 0, w * 0.1, h),
      Paint()..color = Colors.white.withValues(alpha: 0.18),
    );
    canvas.restore();

    canvas.drawPath(
      tubePath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = selected ? 3.5 : 2.5
        ..color = complete
            ? Colors.amber
            : (selected ? Colors.white : Colors.white70),
    );
  }

  @override
  bool shouldRepaint(covariant TubePainter oldDelegate) =>
      oldDelegate.selected != selected ||
      oldDelegate.capacity != capacity ||
      oldDelegate.colorBlind != colorBlind ||
      oldDelegate.complete != complete ||
      oldDelegate.topLayerFraction != topLayerFraction ||
      oldDelegate.extraLayerColor != extraLayerColor ||
      oldDelegate.extraLayerFraction != extraLayerFraction ||
      !_sameLayers(oldDelegate.layers, layers);

  static bool _sameLayers(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
