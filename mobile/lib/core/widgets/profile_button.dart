import 'package:flutter/material.dart';

import '../auth/auth_service.dart';
import '../theme/theme_context.dart';
import 'user_avatar.dart';

/// The user's profile picture, opening their profile.
class ProfileButton extends StatelessWidget {
  const ProfileButton({super.key, required this.user, required this.onTap});

  final AuthUser user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Your profile',
      child: GestureDetector(
        onTap: onTap,
        child: UserAvatar(
          name: user.name,
          avatar: user.avatar,
          border: Border.all(color: context.colors.hairline),
        ),
      ),
    );
  }
}
