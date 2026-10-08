import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../theme/theme_context.dart';

/// The user's initial in a champagne circle, opening their profile.
class ProfileButton extends StatelessWidget {
  const ProfileButton({super.key, required this.name, required this.onTap});

  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Your profile',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppPalette.champagne100,
            border: Border.all(color: context.colors.hairline),
          ),
          child: Text(
            name.isEmpty ? '?' : name[0].toUpperCase(),
            style: const TextStyle(
              color: AppPalette.ink900,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
