import 'package:flutter/material.dart';

import '../auth/profile_avatar.dart';
import '../theme/app_palette.dart';

/// The user's profile picture: their initial or the travel icon they chose,
/// in a circle.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    required this.avatar,
    this.size = 48,
    this.border,
  });

  final String name;
  final ProfileAvatar avatar;
  final double size;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    final icon = avatar.icon;
    final trimmed = name.trim();
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: avatar.color,
          border: border,
        ),
        child: icon == null
            ? Text(
                trimmed.isEmpty ? '?' : trimmed[0].toUpperCase(),
                style: TextStyle(
                  color: AppPalette.ink900,
                  fontSize: size * 0.4,
                  fontWeight: FontWeight.w700,
                ),
              )
            : Icon(icon, color: Colors.white, size: size * 0.5),
      ),
    );
  }
}
