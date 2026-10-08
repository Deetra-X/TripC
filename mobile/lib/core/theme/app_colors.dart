import 'package:flutter/material.dart';

import 'app_palette.dart';

/// Semantic colour roles for TripC, available as `context.colors`.
class TripCColors extends ThemeExtension<TripCColors> {
  const TripCColors({
    required this.background,
    required this.surface,
    required this.surfaceRaised,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.hairline,
    required this.brand,
    required this.onBrand,
    required this.brandSoft,
    required this.accent,
    required this.accentSoft,
    required this.inverse,
    required this.onInverse,
    required this.glassTint,
    required this.glassBorder,
    required this.navTint,
    required this.shadow,
    required this.glowPrimary,
    required this.glowSecondary,
    required this.danger,
  });

  /// Page background.
  final Color background;

  /// Quiet containers that sit on the background.
  final Color surface;

  /// Cards, fields and controls that lift off the page.
  final Color surfaceRaised;

  final Color textPrimary;
  final Color textSecondary;

  /// Hints and placeholders only; too faint for body text.
  final Color textTertiary;

  /// Thin borders and dividers.
  final Color hairline;

  final Color brand;
  final Color onBrand;
  final Color brandSoft;

  /// Champagne, used sparingly for ratings, matches and active states.
  final Color accent;
  final Color accentSoft;

  /// High-contrast fill (charcoal on ivory, pearl on charcoal).
  final Color inverse;
  final Color onInverse;

  final Color glassTint;
  final Color glassBorder;

  /// The floating navigation bar.
  final Color navTint;

  /// Shadow colour, alpha included.
  final Color shadow;

  /// Soft glows in the ambient background.
  final Color glowPrimary;
  final Color glowSecondary;

  final Color danger;

  static const light = TripCColors(
    background: AppPalette.ivory100,
    surface: AppPalette.ivory50,
    surfaceRaised: AppPalette.paper,
    textPrimary: AppPalette.ink900,
    textSecondary: AppPalette.ink600,
    textTertiary: AppPalette.ink400,
    hairline: AppPalette.ivory300,
    brand: AppPalette.teal700,
    onBrand: AppPalette.paper,
    brandSoft: Color(0xFFDCEBE7),
    accent: AppPalette.champagne600,
    accentSoft: AppPalette.champagne100,
    inverse: AppPalette.ink900,
    onInverse: AppPalette.pearl100,
    glassTint: AppPalette.paper,
    glassBorder: Color(0x8CFFFFFF),
    navTint: Color(0xFF1B1F1F),
    shadow: Color(0x1F3A2F1E),
    glowPrimary: Color(0x99B7E6E5),
    glowSecondary: Color(0x80F1E2C4),
    danger: AppPalette.coral,
  );

  static const dark = TripCColors(
    background: AppPalette.charcoal900,
    surface: AppPalette.charcoal850,
    surfaceRaised: AppPalette.charcoal800,
    textPrimary: AppPalette.pearl100,
    textSecondary: AppPalette.pearl400,
    textTertiary: AppPalette.pearl600,
    hairline: AppPalette.charcoal700,
    brand: AppPalette.teal300,
    onBrand: Color(0xFF0E2B2A),
    brandSoft: Color(0xFF1E3534),
    accent: AppPalette.champagne300,
    accentSoft: Color(0xFF3A3122),
    inverse: AppPalette.pearl100,
    onInverse: AppPalette.ink900,
    glassTint: AppPalette.charcoal800,
    glassBorder: Color(0x26FFFFFF),
    navTint: AppPalette.charcoal800,
    shadow: Color(0x66000000),
    glowPrimary: Color(0x4D317978),
    glowSecondary: Color(0x2ED6B87C),
    danger: AppPalette.coralLight,
  );

  @override
  TripCColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceRaised,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? hairline,
    Color? brand,
    Color? onBrand,
    Color? brandSoft,
    Color? accent,
    Color? accentSoft,
    Color? inverse,
    Color? onInverse,
    Color? glassTint,
    Color? glassBorder,
    Color? navTint,
    Color? shadow,
    Color? glowPrimary,
    Color? glowSecondary,
    Color? danger,
  }) {
    return TripCColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      hairline: hairline ?? this.hairline,
      brand: brand ?? this.brand,
      onBrand: onBrand ?? this.onBrand,
      brandSoft: brandSoft ?? this.brandSoft,
      accent: accent ?? this.accent,
      accentSoft: accentSoft ?? this.accentSoft,
      inverse: inverse ?? this.inverse,
      onInverse: onInverse ?? this.onInverse,
      glassTint: glassTint ?? this.glassTint,
      glassBorder: glassBorder ?? this.glassBorder,
      navTint: navTint ?? this.navTint,
      shadow: shadow ?? this.shadow,
      glowPrimary: glowPrimary ?? this.glowPrimary,
      glowSecondary: glowSecondary ?? this.glowSecondary,
      danger: danger ?? this.danger,
    );
  }

  @override
  TripCColors lerp(TripCColors? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return TripCColors(
      background: mix(background, other.background),
      surface: mix(surface, other.surface),
      surfaceRaised: mix(surfaceRaised, other.surfaceRaised),
      textPrimary: mix(textPrimary, other.textPrimary),
      textSecondary: mix(textSecondary, other.textSecondary),
      textTertiary: mix(textTertiary, other.textTertiary),
      hairline: mix(hairline, other.hairline),
      brand: mix(brand, other.brand),
      onBrand: mix(onBrand, other.onBrand),
      brandSoft: mix(brandSoft, other.brandSoft),
      accent: mix(accent, other.accent),
      accentSoft: mix(accentSoft, other.accentSoft),
      inverse: mix(inverse, other.inverse),
      onInverse: mix(onInverse, other.onInverse),
      glassTint: mix(glassTint, other.glassTint),
      glassBorder: mix(glassBorder, other.glassBorder),
      navTint: mix(navTint, other.navTint),
      shadow: mix(shadow, other.shadow),
      glowPrimary: mix(glowPrimary, other.glowPrimary),
      glowSecondary: mix(glowSecondary, other.glowSecondary),
      danger: mix(danger, other.danger),
    );
  }
}
