import 'package:flutter/material.dart';

import '../../core/palette.dart';
import '../../core/tube_metrics.dart';

/// Edge of an idle bottle: a pale luminous glass rim (not a dark cartoon
/// outline), so the vessel reads as glossy. The light theme uses a deeper teal
/// so it still separates from a pale board.
Color tubeOutlineColor(Brightness brightness, ColorScheme scheme) =>
    brightness == Brightness.dark
    ? const Color(0xFFCFFBFF)
    : const Color(0xFF2C7A86);

/// Edge of the selected bottle.
Color tubeSelectedOutlineColor(Brightness brightness, ColorScheme scheme) =>
    brightness == Brightness.dark ? Colors.white : scheme.primary;

/// Cyan/violet glow that rims the glass so the vessel reads as glossy. The hue
/// flips with the board brightness: a bright cyan on the near-black dark theme,
/// a calmer teal on the pale light theme.
Color tubeGlowColor(Brightness brightness, ColorScheme scheme) =>
    brightness == Brightness.dark
    ? const Color(0xFF7FE9FF)
    : const Color(0xFF39B6D6);

/// Soft drop shadow under a bottle, so the vessel reads as a solid object
/// standing on the board instead of a shape painted onto it.
///
/// Every length is a fraction of the bottle width, so the shadow scales with
/// the board. The two presets differ because the cue that separates a bottle
/// from the board flips with the board's brightness: on a pale board a faint
/// black halo reads as depth, while on the dark theme's almost-black board
/// black on black is invisible, so the bottle is separated by a soft halo of
/// light instead.
class TubeShadow {
  const TubeShadow({
    required this.color,
    required this.dx,
    required this.dy,
    required this.blur,
  });

  /// Shadow for the light theme: a very faint contact halo that falls down and
  /// slightly right, as if the light came from the top left. Kept well under
  /// 15% opacity so it never reads as a heavy dark outline around the bottle.
  static const TubeShadow light = TubeShadow(
    color: Color(0x1C000000),
    dx: 0.03,
    dy: 0.07,
    blur: 0.065,
  );

  /// Shadow for the dark theme: black would vanish into the near-black board,
  /// so this preset is a wide, low-alpha white halo. It reads as ambient light
  /// around the vessel, which lifts it off the board the same way a shadow
  /// does on the light theme.
  static const TubeShadow dark = TubeShadow(
    color: Color(0x14FFFFFF),
    dx: 0.02,
    dy: 0.045,
    blur: 0.09,
  );

  final Color color;

  /// Horizontal throw, as a fraction of the bottle width.
  final double dx;

  /// How far the shadow is pushed down, as a fraction of the bottle width.
  final double dy;

  /// Blur sigma, as a fraction of the bottle width.
  final double blur;

  static TubeShadow forBrightness(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;
}

/// Draws one bottle: a capped, narrow-necked glass vessel whose body holds the
/// liquid layers (bottom -> top). The glass is translucent and tinted, so the
/// bottle reads as a glossy vessel on any board colour, and a bottle in front
/// still mostly hides the one behind it.
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
    this.outlineColor = const Color(0xFFCFFBFF),
    this.selectedOutlineColor = Colors.white,
    this.glowColor = const Color(0xFF7FE9FF),
    this.shadow,
    this.hinted = false,
    this.topLayerFraction = 1,
    this.extraLayerColor,
    this.extraLayerFraction = 0,
  });

  final List<int> layers;
  final int capacity;
  final bool selected;
  final bool colorBlind;
  final bool complete;

  /// Crisp edge of an idle bottle; a pale luminous rim.
  final Color outlineColor;

  /// Edge of the bottle the player selected.
  final Color selectedOutlineColor;

  /// Cyan/violet glow that rims the glass.
  final Color glowColor;

  /// Soft drop shadow cast behind the bottle. `null` means no shadow, which is
  /// what the flying copy during a pour uses so it never smears the board.
  final TubeShadow? shadow;

  /// Highlighted by the current hint (source or destination).
  final bool hinted;

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
    final cx = w / 2;

    final capH = tubeCapHeight(h);
    final neckTopY = capH; // glass begins just under the cap
    final neckBottomY = bottleNeckBottom(h);
    final shoulderY = bottleShoulderBottom(h);
    final neckHalf = bottleNeckHalfWidth(w);
    final capHalf = neckHalf * 1.20; // cap overhangs the neck as a wider rim
    final rCorner = w * 0.16; // rounded lower corners
    final inset = w * 0.028; // body sits just inside the widget edge
    final shoulderH = shoulderY - neckBottomY;
    // Control-point offset of the shoulder curve. Putting both controls on the
    // same vertical line as their end points gives the curve a vertical tangent
    // at BOTH ends, so it joins the straight neck and the straight body without
    // a kink (a quadratic shoulder ends horizontally and made a sharp elbow).
    final shoulderK = shoulderH * 0.55;

    // Glass silhouette (open across the neck): cap rim -> neck -> ogee
    // shoulder -> straight body -> rounded bottom -> shoulder -> neck -> close.
    // Every join is tangent-continuous: neck (vertical) -> shoulder (vertical
    // in, vertical out) -> body (vertical) -> base corner (vertical in).
    final glass = Path()
      ..moveTo(cx - neckHalf, neckTopY)
      ..lineTo(cx - neckHalf, neckBottomY)
      ..cubicTo(
        cx - neckHalf,
        neckBottomY + shoulderK,
        inset,
        shoulderY - shoulderK,
        inset,
        shoulderY,
      )
      ..lineTo(inset, h - rCorner)
      // Convex rounded corners: a quadratic through the sharp corner point
      // gives a clean, symmetric base without relying on arcToPoint's centre
      // selection, which can otherwise flip into a concave notch.
      ..quadraticBezierTo(inset, h, inset + rCorner, h)
      ..lineTo(w - inset - rCorner, h)
      ..quadraticBezierTo(w - inset, h, w - inset, h - rCorner)
      ..lineTo(w - inset, shoulderY)
      ..cubicTo(
        w - inset,
        shoulderY - shoulderK,
        cx + neckHalf,
        neckBottomY + shoulderK,
        cx + neckHalf,
        neckBottomY,
      )
      ..lineTo(cx + neckHalf, neckTopY)
      ..close();

    // Soft halo around the vessel: a blurred STROKE of the silhouette, not a
    // filled copy. A filled shadow would sit directly under the translucent
    // glass and show through it, turning an empty bottle into a dark solid
    // block. Outlining only the contour keeps the interior clear.
    final shadow = this.shadow;
    if (shadow != null) {
      canvas.drawPath(
        glass.shift(Offset(w * shadow.dx, w * shadow.dy)),
        Paint()
          ..color = shadow.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.075
          ..strokeJoin = StrokeJoin.round
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * shadow.blur),
      );
    }

    // --- Clear glass body. ---
    // Only a whisper of cool tint: an empty bottle must read as see-through
    // glass, not as a filled vessel. The luminous rim, sheen streaks and cap
    // carry the shape, so the interior can stay almost fully transparent.
    canvas.drawPath(
      glass,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0x146FC0CC), const Color(0x1C3A8A98)],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );
    canvas.drawPath(
      glass,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            const Color(0x132C5A68),
            Colors.transparent,
            const Color(0x132C5A68),
          ],
          stops: const [0, 0.5, 1],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // --- Liquid layers, clipped to the bottle shape. ---
    canvas.save();
    canvas.clipPath(glass);

    // Glossy highlight blooming on the upper-left shoulder. Drawn BEFORE the
    // liquid so opaque water covers it: a reflection on the glass must not
    // bleach the colour of a layer that happens to sit near the neck.
    final glossCenter = Offset(w * 0.27, shoulderY + (h - shoulderY) * 0.14);
    final glossRadius = w * 0.46;
    canvas.drawCircle(
      glossCenter,
      glossRadius,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                Colors.white.withValues(alpha: 0.20),
                Colors.white.withValues(alpha: 0.0),
              ],
            ).createShader(
              Rect.fromCircle(center: glossCenter, radius: glossRadius),
            ),
    );

    final usableTop = tubeUsableTop(w, h);
    final layerHeight = (h - usableTop) / capacity;
    var surfaceTop = double.nan;
    final column = Rect.fromLTWH(0, 0, w, h);

    final extraFraction = extraLayerFraction.clamp(0.0, 1.0);
    final topFraction = topLayerFraction.clamp(0.0, 1.0);

    for (var i = 0; i < layers.length; i++) {
      final isTop = i == layers.length - 1;
      final fraction = isTop ? topFraction : 1.0;
      if (fraction <= 0) continue;

      final bottom = h - i * layerHeight;
      final top = bottom - layerHeight * fraction;
      final rect = Rect.fromLTWH(0, top, w, layerHeight * fraction + 0.5);
      canvas.drawRect(rect, _liquidPaint(layers[i], column));
      if (isTop) surfaceTop = top;

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
    if (extraColor != null && extraFraction > 0) {
      final baseTop = h - layers.length * layerHeight;
      final rect = Rect.fromLTWH(
        0,
        baseTop - layerHeight * extraFraction,
        w,
        layerHeight * extraFraction + 0.5,
      );
      canvas.drawRect(rect, _liquidPaint(extraColor, column));
      surfaceTop = rect.top;
    }

    // Vertical reflections on the glass: a broad cyan sheen on the left and a
    // thin violet one on the right, the way light streaks down a bottle.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          w * 0.14,
          shoulderY + h * 0.02,
          w * 0.10,
          h - shoulderY - rCorner - h * 0.04,
        ),
        Radius.circular(w * 0.05),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.22),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          w * 0.80,
          shoulderY + h * 0.03,
          w * 0.055,
          h - shoulderY - rCorner - h * 0.06,
        ),
        Radius.circular(w * 0.03),
      ),
      Paint()..color = const Color(0xFFB38CFF).withValues(alpha: 0.16),
    );

    // Convex liquid surface at the top of the column: a bright lens that fades
    // downward, like a water level seen slightly from above.
    if (!surfaceTop.isNaN && surfaceTop < h) {
      final lensH = (layerHeight * 0.20).clamp(3.0, 10.0);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, surfaceTop + lensH * 0.5),
          width: w * 0.84,
          height: lensH,
        ),
        Paint()
          ..shader =
              LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.42),
                  Colors.white.withValues(alpha: 0.0),
                ],
              ).createShader(
                Rect.fromCenter(
                  center: Offset(cx, surfaceTop + lensH * 0.5),
                  width: w * 0.84,
                  height: lensH,
                ),
              ),
      );
    }

    canvas.restore();

    // --- Glass glow + edge. ---
    final edgeColor = complete
        ? Colors.amber
        : selected
        ? selectedOutlineColor
        : hinted
        ? Colors.lightBlueAccent
        : outlineColor;

    // Luminous outer glow: a blurred stroke that gives the rim its glassy edge.
    canvas.drawPath(
      glass,
      Paint()
        ..color = glowColor.withValues(alpha: selected ? 0.85 : 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = selected ? 5.0 : 3.6
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.055),
    );

    // Crisp glass edge on top of the glow: thin and pale so it reads as glass,
    // not as a drawn outline.
    canvas.drawPath(
      glass,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = selected ? 3.0 : 1.6
        ..color = edgeColor,
    );

    // --- Cap (drawn last, on top of the neck). ---
    _paintCap(canvas, cx, capH, capHalf);
  }

  /// The lid: a light translucent cap with a recessed oval opening at the top,
  /// like the reference bottle you can see into.
  void _paintCap(Canvas canvas, double cx, double capH, double capHalf) {
    final capR = capHalf * 0.45;
    final capPath = Path()
      ..moveTo(cx - capHalf, capH)
      ..lineTo(cx - capHalf, capR)
      ..quadraticBezierTo(cx - capHalf, 0, cx - capHalf + capR, 0)
      ..lineTo(cx + capHalf - capR, 0)
      ..quadraticBezierTo(cx + capHalf, 0, cx + capHalf, capR)
      ..lineTo(cx + capHalf, capH)
      ..close();

    // Light cyan-green cap body.
    canvas.drawPath(
      capPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFFCDEFF3), const Color(0xFF7FC4CF)],
        ).createShader(Rect.fromLTRB(cx - capHalf, 0, cx + capHalf, capH)),
    );

    // Recessed mouth: a darker oval at the top of the cap.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, capH * 0.42),
        width: capHalf * 0.66,
        height: capH * 0.5,
      ),
      Paint()..color = const Color(0x6614242C),
    );

    // Soft rim highlight along the cap's upper edge.
    canvas.drawPath(
      Path()
        ..moveTo(cx - capHalf + capR, capH * 0.16)
        ..quadraticBezierTo(cx, -capH * 0.04, cx + capHalf - capR, capH * 0.16),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = capH * 0.18
        ..strokeCap = StrokeCap.round,
    );
  }

  /// Liquid fill: clear, luminous water with a soft horizontal sheen.
  ///
  /// The gradient MUST be horizontal. A vertical one sampled over the whole
  /// [column] makes one palette colour look lighter near the neck and darker
  /// at the base — the same blue would appear as two different blues. Left →
  /// right shading is constant at every height, so a colour looks identical
  /// wherever it sits, and adjacent layers of the same colour still meet
  /// seamlessly (no per-layer tone step). No black shading and no
  /// translucency, so colours stay clean and saturated.
  static Paint _liquidPaint(int colorIndex, Rect column) {
    final base = kPalette[colorIndex];
    return Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Color.lerp(base, Colors.white, 0.26)!,
          base,
          Color.lerp(base, Colors.white, 0.10)!,
        ],
        stops: const [0, 0.45, 1],
      ).createShader(column);
  }

  @override
  bool shouldRepaint(covariant TubePainter oldDelegate) =>
      oldDelegate.selected != selected ||
      oldDelegate.capacity != capacity ||
      oldDelegate.colorBlind != colorBlind ||
      oldDelegate.complete != complete ||
      oldDelegate.outlineColor != outlineColor ||
      oldDelegate.selectedOutlineColor != selectedOutlineColor ||
      oldDelegate.glowColor != glowColor ||
      oldDelegate.shadow != shadow ||
      oldDelegate.hinted != hinted ||
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
