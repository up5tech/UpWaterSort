import 'dart:math' show max;

/// Vertical fraction of the tube height taken by the cap (the solid lid on top
/// of the bottle).
const double _kCapFactor = 0.048;

/// Vertical fraction taken by the narrow neck below the cap.
const double _kNeckFactor = 0.070;

/// Vertical fraction taken by the curved shoulder that widens the neck out to
/// the body. The cap + neck + shoulder form the empty "headspace" above the
/// liquid, so a bottle filled to the brim still leaves the neck clear.
const double _kShoulderFactor = 0.062;

/// Half-width of the neck, as a fraction of the tube width.
const double _kNeckHalfFactor = 0.19;

/// Height of the solid cap, in pixels.
double tubeCapHeight(double height) => height * _kCapFactor;

/// Y of the bottom of the neck (top of the shoulder), in pixels.
double bottleNeckBottom(double height) => height * (_kCapFactor + _kNeckFactor);

/// Y where the body reaches full width (bottom of the shoulder), in pixels.
double bottleShoulderBottom(double height) =>
    height * (_kCapFactor + _kNeckFactor + _kShoulderFactor);

/// Half-width of the neck, in pixels.
double bottleNeckHalfWidth(double width) => width * _kNeckHalfFactor;

/// Distance from the top of the tube widget down to the highest liquid level:
/// the body begins below the shoulder, so liquid never pokes into the neck.
///
/// Kept in sync with the painter and the pour animation, which both measure
/// liquid levels from this line down to the bottom.
double tubeUsableTop(double width, double height) =>
    max(height * 0.08, bottleShoulderBottom(height));
