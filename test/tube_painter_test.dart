import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:up_water_sort/core/tube_metrics.dart';
import 'package:up_water_sort/ui/widgets/tube_painter.dart';

const _w = 120.0;
const _h = 120.0 * 4.2;
const _capacity = 4;

/// Renders a bottle and returns a pixel sampler over its raw RGBA bytes.
Future<Color Function(double x, double y)> _sampler(List<int> layers) async {
  final recorder = ui.PictureRecorder();
  TubePainter(
    layers: layers,
    capacity: _capacity,
    selected: false,
    colorBlind: false,
    complete: false,
    outlineColor: const Color(0xFFCFFBFF),
    glowColor: const Color(0xFF7FE9FF),
  ).paint(Canvas(recorder), const Size(_w, _h));

  final image = await recorder.endRecording().toImage(_w.toInt(), _h.toInt());
  final bytes = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;

  return (double x, double y) {
    final i = (y.toInt() * _w.toInt() + x.toInt()) * 4;
    return Color.fromARGB(
      bytes.getUint8(i + 3),
      bytes.getUint8(i),
      bytes.getUint8(i + 1),
      bytes.getUint8(i + 2),
    );
  };
}

/// 8-bit blending at rounded corners can shift a channel by one step. That is
/// invisible on screen; only a real gradient difference (the old bug) exceeds
/// this tolerance.
bool _sameColor(Color a, Color b, {double tolerance = 2 / 255}) =>
    (a.r - b.r).abs() <= tolerance &&
    (a.g - b.g).abs() <= tolerance &&
    (a.b - b.b).abs() <= tolerance &&
    (a.a - b.a).abs() <= tolerance;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final usableTop = tubeUsableTop(_w, _h);
  final layerHeight = (_h - usableTop) / _capacity;

  test(
    'one palette colour looks identical at any height in the bottle',
    () async {
      // Blue at the base and the same blue at the top, separated by two other
      // colours. Regression guard: a vertical gradient sampled over the whole
      // column used to make these two blues look like different colours.
      final pixelAt = await _sampler(const [1, 5, 0, 1]);

      final bottomY = _h - layerHeight * 0.5; // middle of layer 0
      final topY =
          _h - 3 * layerHeight - layerHeight * 0.5; // middle of layer 3

      // Sample across the width, including inside both reflection streaks, so
      // no height-dependent overlay can slip through.
      for (final x in <double>[_w * 0.2, _w * 0.5, _w * 0.83]) {
        final top = pixelAt(x, topY);
        final bottom = pixelAt(x, bottomY);
        expect(
          _sameColor(top, bottom),
          isTrue,
          reason: 'same blue differs at x=$x: $top vs $bottom',
        );
      }
    },
  );

  test('adjacent layers of one colour meet without a tone step', () async {
    // A tube completed with a single colour must read as one continuous
    // column, not four stacked bands with seams between them.
    final pixelAt = await _sampler(const [1, 1, 1, 1]);

    for (var i = 1; i < _capacity; i++) {
      final boundary = _h - i * layerHeight;
      for (final x in <double>[_w * 0.2, _w * 0.5, _w * 0.83]) {
        final above = pixelAt(x, boundary - 2);
        final below = pixelAt(x, boundary + 2);
        expect(
          _sameColor(above, below),
          isTrue,
          reason: 'tone step at boundary $i, x=$x: $above vs $below',
        );
      }
    }
  });
}
