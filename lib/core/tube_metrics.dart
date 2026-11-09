import 'dart:math' show max;

/// Half-height of the mouth ellipse, relative to the tube width.
const double _kRimHeightFactor = 0.13;

/// Vertical radius of the tube mouth.
///
/// Shared by the tube painter and the pour animation, so the mouth, the highest
/// liquid level and the falling stream line up exactly.
double tubeRimHalfHeight(double width) => width * _kRimHeightFactor;

/// Distance from the top of the tube widget down to the highest liquid level:
/// below the mouth ellipse, so liquid never pokes through the opening.
double tubeUsableTop(double width, double height) =>
    max(height * 0.08, tubeRimHalfHeight(width) * 2.2);
