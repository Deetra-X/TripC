import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTypography {
  static const String fontFamily = 'Manrope';

  static TextTheme textTheme(TripCColors colors) {
    TextStyle style(
      double size,
      double height,
      FontWeight weight, {
      double spacing = 0,
      Color? color,
    }) {
      return TextStyle(
        fontFamily: fontFamily,
        fontSize: size,
        height: height,
        fontWeight: weight,
        letterSpacing: spacing,
        color: color ?? colors.textPrimary,
      );
    }

    return TextTheme(
      displayLarge: style(44, 1.05, FontWeight.w800, spacing: -1.2),
      displayMedium: style(40, 1.05, FontWeight.w800, spacing: -1),
      displaySmall: style(36, 1.08, FontWeight.w800, spacing: -0.8),
      headlineLarge: style(32, 1.12, FontWeight.w800, spacing: -0.6),
      headlineMedium: style(28, 1.15, FontWeight.w700, spacing: -0.5),
      headlineSmall: style(24, 1.2, FontWeight.w700, spacing: -0.3),
      titleLarge: style(20, 1.25, FontWeight.w700, spacing: -0.2),
      titleMedium: style(17, 1.3, FontWeight.w700, spacing: -0.1),
      titleSmall: style(15, 1.3, FontWeight.w600),
      bodyLarge: style(16, 1.5, FontWeight.w500),
      bodyMedium: style(15, 1.45, FontWeight.w500),
      bodySmall: style(
        13,
        1.4,
        FontWeight.w500,
        spacing: 0.1,
        color: colors.textSecondary,
      ),
      labelLarge: style(15, 1.2, FontWeight.w700, spacing: 0.1),
      labelMedium: style(13, 1.2, FontWeight.w600, spacing: 0.2),
      labelSmall: style(12, 1.2, FontWeight.w600, spacing: 0.3),
    );
  }
}
