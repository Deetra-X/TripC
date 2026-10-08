import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_palette.dart';
import 'app_tokens.dart';
import 'app_typography.dart';

abstract final class AppTheme {
  static final ThemeData light = _build(TripCColors.light, Brightness.light);
  static final ThemeData dark = _build(TripCColors.dark, Brightness.dark);

  static ThemeData _build(TripCColors c, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final text = AppTypography.textTheme(c);

    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.brand,
      onPrimary: c.onBrand,
      primaryContainer: c.brandSoft,
      onPrimaryContainer: c.textPrimary,
      secondary: c.accent,
      onSecondary: isDark ? AppPalette.ink900 : AppPalette.paper,
      secondaryContainer: c.accentSoft,
      onSecondaryContainer: c.textPrimary,
      tertiary: isDark ? AppPalette.teal400 : AppPalette.teal800,
      onTertiary: isDark ? AppPalette.ink900 : AppPalette.paper,
      error: c.danger,
      onError: isDark ? AppPalette.ink900 : AppPalette.paper,
      surface: c.background,
      onSurface: c.textPrimary,
      onSurfaceVariant: c.textSecondary,
      surfaceContainerLowest: isDark
          ? AppPalette.charcoal950
          : AppPalette.paper,
      surfaceContainerLow: c.surface,
      surfaceContainer: isDark
          ? const Color(0xFF1C2021)
          : const Color(0xFFF3EEE4),
      surfaceContainerHigh: isDark
          ? AppPalette.charcoal800
          : AppPalette.ivory200,
      surfaceContainerHighest: isDark
          ? const Color(0xFF262B2D)
          : const Color(0xFFE9E2D4),
      outline: isDark ? const Color(0xFF4A5052) : const Color(0xFFC9C0AF),
      outlineVariant: c.hairline,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: c.inverse,
      onInverseSurface: c.onInverse,
      inversePrimary: isDark ? AppPalette.teal700 : AppPalette.teal300,
      surfaceTint: Colors.transparent,
    );

    OutlineInputBorder fieldBorder(Color color, [double width = 1]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return ThemeData(
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.background,
      canvasColor: c.background,
      fontFamily: AppTypography.fontFamily,
      textTheme: text,
      extensions: [c],
      iconTheme: IconThemeData(color: c.textPrimary),
      dividerTheme: DividerThemeData(color: c.hairline, thickness: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: c.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(180, 54),
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.xxxl),
          shape: const StadiumBorder(),
          textStyle: text.labelLarge?.copyWith(fontSize: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.brand,
          textStyle: text.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.textPrimary,
          side: BorderSide(color: c.hairline),
          shape: const StadiumBorder(),
          minimumSize: const Size(64, 48),
          textStyle: text.labelLarge,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          foregroundColor: c.textSecondary,
          selectedForegroundColor: c.textPrimary,
          selectedBackgroundColor: c.accentSoft,
          side: BorderSide(color: c.hairline),
          textStyle: text.labelMedium,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surfaceRaised,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpace.xl,
          vertical: 18,
        ),
        hintStyle: TextStyle(color: c.textTertiary),
        labelStyle: TextStyle(color: c.textSecondary),
        floatingLabelStyle: TextStyle(color: c.brand),
        border: fieldBorder(c.hairline),
        enabledBorder: fieldBorder(c.hairline),
        focusedBorder: fieldBorder(c.brand, 1.5),
        errorBorder: fieldBorder(c.danger),
        focusedErrorBorder: fieldBorder(c.danger, 1.5),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.inverse,
        contentTextStyle: text.labelLarge?.copyWith(color: c.onInverse),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: c.inverse,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        textStyle: text.labelMedium?.copyWith(color: c.onInverse),
      ),
    );
  }
}
