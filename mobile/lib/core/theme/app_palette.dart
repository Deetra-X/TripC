import 'package:flutter/material.dart';

/// Raw TripC colours. Widgets should use the semantic roles in
/// `TripCColors` (via `context.colors`) so they adapt to light and dark;
/// reach for these directly only for content that looks the same in both,
/// such as illustrations and text over imagery.
abstract final class AppPalette {
  // Brand teal, darkest to lightest.
  static const Color teal900 = Color(0xFF113B3A);
  static const Color teal800 = Color(0xFF184948);
  static const Color teal700 = Color(0xFF235E5D);
  static const Color teal600 = Color(0xFF317978);
  static const Color teal400 = Color(0xFF599D9C);
  static const Color teal300 = Color(0xFF7FBDB7);
  static const Color teal100 = Color(0xFFB7E6E5);

  // Warm ivory neutrals.
  static const Color paper = Color(0xFFFFFFFF);
  static const Color ivory50 = Color(0xFFFBF9F4);
  static const Color ivory100 = Color(0xFFF6F2EA);
  static const Color ivory200 = Color(0xFFEFE9DE);
  static const Color ivory300 = Color(0xFFE7E0D3);

  // Ink, for text on ivory.
  static const Color ink900 = Color(0xFF17191A);
  static const Color ink600 = Color(0xFF5C605C);
  static const Color ink400 = Color(0xFF8A8D88);

  // Charcoal neutrals.
  static const Color charcoal950 = Color(0xFF0C0E0F);
  static const Color charcoal900 = Color(0xFF111314);
  static const Color charcoal850 = Color(0xFF181B1C);
  static const Color charcoal800 = Color(0xFF202425);
  static const Color charcoal700 = Color(0xFF2B3032);

  // Pearl, for text on charcoal.
  static const Color pearl100 = Color(0xFFF3EFE7);
  static const Color pearl400 = Color(0xFFA9ABA6);
  static const Color pearl600 = Color(0xFF74776F);

  // Champagne accent: deeper on ivory for contrast, lighter on charcoal.
  static const Color champagne600 = Color(0xFFA88447);
  static const Color champagne300 = Color(0xFFD6B87C);
  static const Color champagne200 = Color(0xFFE2C78F);
  static const Color champagne100 = Color(0xFFF1E6D0);

  static const Color coral = Color(0xFFE5574F);
  static const Color coralLight = Color(0xFFF0736B);
}
