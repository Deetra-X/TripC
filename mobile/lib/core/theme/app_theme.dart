import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(seedColor: AppColors.teal700)
        .copyWith(
          primary: AppColors.teal700,
          onPrimary: Colors.white,
          primaryContainer: AppColors.teal100,
          onPrimaryContainer: AppColors.teal900,
          secondary: AppColors.teal600,
          onSecondary: Colors.white,
          tertiary: AppColors.teal800,
          onTertiary: AppColors.teal100,
          onSurface: AppColors.teal900,
          outline: AppColors.teal400,
        );

    return ThemeData(colorScheme: colorScheme);
  }
}
