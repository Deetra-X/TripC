import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

/// The picture on a user's profile: their initial, or a travel icon. Stands
/// in for photo uploads until profiles are stored in Supabase.
enum ProfileAvatar {
  initial('Initial', null, AppPalette.champagne100),
  hiker('Hiker', Icons.hiking_rounded, Color(0xFF2E7D7A)),
  beach('Beach', Icons.beach_access_rounded, Color(0xFF2F80B7)),
  temple('Temple', Icons.temple_buddhist_rounded, Color(0xFFB9853A)),
  wildlife('Wildlife', Icons.pets_rounded, Color(0xFFD2742A)),
  tea('Tea', Icons.emoji_food_beverage_rounded, Color(0xFF3E8E5E)),
  surf('Surf', Icons.surfing_rounded, Color(0xFF2A9FBF)),
  train('Train', Icons.train_rounded, AppPalette.teal700),
  camera('Camera', Icons.photo_camera_rounded, Color(0xFF7B5EA7));

  const ProfileAvatar(this.label, this.icon, this.color);

  final String label;

  /// Null for the initial.
  final IconData? icon;
  final Color color;
}
