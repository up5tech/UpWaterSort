import 'package:flutter/material.dart';

import '../../core/palette.dart';
import '../../core/tube_metrics.dart';

/// Outline of an idle tube. White only reads on the dark theme, so the light
/// theme uses the Material `outline` token instead.
Color tubeOutlineColor(Brightness brightness, ColorScheme scheme) =>
    brightness == Brightness.dark ? Colors.white70 : scheme.outline;

/// Outline of the selected tube.
Color tubeSelectedOutlineColor(Brightness brightness, ColorScheme scheme) =>
    brightness == Brightness.dark ? Colors.white : scheme.primary;

/// Soft drop shadow under a tube, so the vessel reads as a solid object
/// standing on the board instead of a shape painted onto it.
///
/// Every length is a fraction of the tube width, so the shadow scales with the
/// board. The two presets differ because the cue that separates a tube from the
/// board flips with the board's brightness: on a pale board a faint black halo
/// reads as depth, while on the dark theme's almost-black board black on black
/// is invisible, so the tube is separated by a soft halo of light instead.
class TubeShadow {
  const TubeShadow({
    required this.color,
    required this.dx,
    required this.dy,
    required this.blur,
  });

  /// Shadow for the light theme: a tight, low-contrast contact shadow that
  /// falls down and slightly right, as if the light came from the top left.
  static const TubeShadow light = TubeShadow(
    color: Color(0x52000000),
    dx: 0.03,
    dy: 0.07,
    blur: 0.065,
  );

  /// Shadow for the dark theme: black would vanish into the near-black board,
  /// so this preset is a wide, low-alpha white halo. It reads as ambient light
  /// around the vessel, which lifts it off the board the same way a shadow
  /// does on the light theme.
  static const TubeShadow dark = TubeShadow(
    color: Color(0x24FFFFFF),
    dx: 0.02,
    dy: 0.045,
    blur: 0.09,
  );

  final Color color;

  /// Horizontal throw, as a fraction of the tube width.
  final double dx;

  /// How far the shadow is pushed down, as a fraction of the tube width.
  final double dy;

  /// Blur sigma, as a fraction of the tube width.
  final double blur;

  static TubeShadow forBrightness(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;
}

/// Draws one tube: liquid layers (bottom -> top), optional color-blind symbols
/// and an outline that reflects selection/completion. The tube body is filled
/// with [bodyColor] (the screen background) instead of staying clear, so a tube
/// in front hides the one behind it.
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
    this.outlineColor = Colors.white70,
    this.selectedOutlineColor = Colors.white,
    this.bodyColor = Colors.white,
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

  /// Outline of an idle tube; must contrast with the screen background.
  final Color outlineColor;

  /// Outline of the tube the player selected.
  final Color selectedOutlineColor;

  /// Opaque fill of the tube interior; the screen's background colour, so a
  /// selected tube covering a neighbour reads as one solid object.
  final Color bodyColor;

  /// Soft drop shadow cast behind the tube. `null` means no shadow, which is
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
    final r = w / 2;
    final rimRy = tubeRimHalfHeight(w);

    // Tube walls: they start at the mouth ellipse's widest points and close
    // with a rounded bottom.
    final tubePath = Path()
      ..moveTo(0, rimRy)
      ..lineTo(0, h - r)
      ..arcToPoint(
        Offset(w, h - r),
        radius: Radius.circular(r),
        clockwise: false,
      )
      ..lineTo(w, rimRy);

    final glassPath = Path.from(tubePath)..close();
    final mouthRect = Rect.fromCenter(
      center: Offset(w / 2, rimRy),
      width: w,
      height: rimRy * 2,
    );

    // Soft shadow under the vessel: a blurred copy of the tube shape pushed a
    // little down, so the tube reads as standing on the board rather than being
    // painted flat onto it. Drawn before the opaque body, so only the halo that
    // falls outside the glass stays visible.
    final shadow = this.shadow;
    if (shadow != null) {
      canvas.drawPath(
        glassPath.shift(Offset(w * shadow.dx, w * shadow.dy)),
        Paint()
          ..color = shadow.color
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * shadow.blur),
      );
    }

    // Opaque body first: without it the empty head-space of a tube lets the
    // liquid of the tube behind show through.
    final body = Paint()..color = bodyColor;
    canvas.drawPath(glassPath, body);
    canvas.drawOval(mouthRect, body);

    // Liquid layers, clipped to the tube shape.
    canvas.save();
    canvas.clipPath(glassPath);

    final usableTop = tubeUsableTop(w, h);
    final layerHeight = (h - usableTop) / capacity;
    var surfaceTop = double.nan;
    final column = Rect.fromLTWH(0, 0, w, h);

    for (var i = 0; i < layers.length; i++) {
      final isTop = i == layers.length - 1;
      final fraction = isTop ? topLayerFraction.clamp(0.0, 1.0) : 1.0;
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
    final extraFraction = extraLayerFraction.clamp(0.0, 1.0);
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

    // Highlight on the liquid surface: a flattened lens of light, the way a
    // real water level catches it. Drawn only at the top of the column, never
    // as a stripe down the glass.
    if (!surfaceTop.isNaN && surfaceTop < h) {
      final lensHeight = (layerHeight * 0.14).clamp(2.5, 8.0);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(w / 2, surfaceTop + lensHeight * 0.5),
          width: w * 0.92,
          height: lensHeight,
        ),
        Paint()..color = Colors.white.withValues(alpha: 0.24),
      );
    }

    canvas.restore();

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = selected ? 3.5 : 2.5
      ..color = complete
          ? Colors.amber
          : selected
          ? selectedOutlineColor
          : hinted
          ? Colors.lightBlueAccent
          : outlineColor;

    canvas.drawPath(tubePath, stroke);

    // Mouth: a shallow ellipse. Its upper arc is the near rim and the lower arc
    // is the far rim seen through the glass, which is what makes the tube read
    // as an open vessel rather than a filled shape.
    canvas.drawOval(mouthRect, stroke);
  }

  /// Liquid fill: a touch lighter near the surface and deeper towards the
  /// bottom, so stacked layers read as volume instead of flat swatches.
  ///
  /// [column] spans the whole tube (not one layer), so two adjacent layers of
  /// the same colour meet seamlessly instead of showing a tone step.
  static Paint _liquidPaint(int colorIndex, Rect column) {
    final base = kPalette[colorIndex];
    return Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.lerp(base, Colors.white, 0.16)!,
          base,
          Color.lerp(base, Colors.black, 0.14)!,
        ],
        stops: const [0, 0.4, 1],
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
      oldDelegate.bodyColor != bodyColor ||
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
