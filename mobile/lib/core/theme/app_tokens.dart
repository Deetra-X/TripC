import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

import 'app_colors.dart';

/// Spacing on a 4-point grid.
abstract final class AppSpace {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 48;

  /// Horizontal page margin.
  static const double gutter = 24;
}

abstract final class AppRadius {
  static const double sm = 14;
  static const double md = 20;
  static const double lg = 28;
  static const double xl = 36;
  static const double pill = 999;
}

abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration base = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);

  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasized = Cubic(0.2, 0, 0, 1);
}

abstract final class AppShadows {
  /// Gentle lift for cards and controls.
  static List<BoxShadow> soft(TripCColors colors) => [
    BoxShadow(
      color: colors.shadow,
      blurRadius: 24,
      offset: const Offset(0, 10),
    ),
  ];

  /// Deeper shadow for hero cards and floating bars.
  static List<BoxShadow> raised(TripCColors colors) => [
    BoxShadow(
      color: colors.shadow.withValues(alpha: colors.shadow.a * 1.6),
      blurRadius: 32,
      offset: const Offset(0, 16),
    ),
  ];
}
