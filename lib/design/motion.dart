/// Motion tokens. Motion here has one job: to be breathed with. If a
/// transition competes with the orb, the transition is cut.
library;

import 'package:flutter/animation.dart';

class CcMotion {
  const CcMotion._();

  /// One full breath cycle: 4s in, 1s hold, 6s out, 0.5s rest.
  static const Duration breath = Duration(milliseconds: 11500);

  /// Screen change.
  static const Duration settle = Duration(milliseconds: 280);

  /// Press feedback.
  static const Duration tap = Duration(milliseconds: 100);

  /// CALM -> ACUTE. The room dimming.
  static const Duration dim = Duration(milliseconds: 780);

  /// ACUTE -> CALM. The room coming back; slower than you think.
  static const Duration lift = Duration(milliseconds: 680);

  // Reduced-motion variants: nothing moves, everything cross-fades.
  static const Duration settleReduced = Duration.zero;
  static const Duration tapReduced = Duration.zero;
  static const Duration dimReduced = Duration(milliseconds: 120);
  static const Duration liftReduced = Duration(milliseconds: 120);

  static const Curve settleCurve = Curves.easeOut; // never bouncy
  static const Curve tapCurve = Curves.easeOut;
  static const Curve dimCurve = Curves.easeInOut;

  /// "Crest" — asymmetric breath easing, for anything that has to be expressed
  /// as a curve rather than the analytic amplitude in `breath.dart`.
  static const Curve crestIn = Cubic(0.16, 0.62, 0.24, 1.0);
  static const Curve crestOut = Cubic(0.32, 0.0, 0.72, 0.42);

  /// Every motion token has a reduced variant. Reduced motion is a visual
  /// preference, not a request to stop pacing the breath — the orb's amplitude
  /// is handled separately, in `breath.dart`.
  static Duration reduce(Duration d, {required bool reduced}) {
    if (!reduced) return d;
    if (d == dim) return dimReduced;
    if (d == lift) return liftReduced;
    return Duration.zero;
  }
}
