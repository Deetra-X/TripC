import 'package:flutter/material.dart';

import '../../../core/auth/profile_avatar.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/user_avatar.dart';

/// The profile pictures to choose from, with a ring around the chosen one.
class AvatarPicker extends StatelessWidget {
  const AvatarPicker({
    super.key,
    required this.name,
    required this.selected,
    required this.onChanged,
  });

  /// For the initial.
  final String name;
  final ProfileAvatar selected;
  final ValueChanged<ProfileAvatar> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Wrap(
      spacing: AppSpace.sm,
      runSpacing: AppSpace.sm,
      children: [
        for (final avatar in ProfileAvatar.values)
          Semantics(
            button: true,
            selected: avatar == selected,
            label: avatar.label,
            child: Tooltip(
              message: avatar.label,
              child: GestureDetector(
                onTap: () => onChanged(avatar),
                child: AnimatedContainer(
                  duration: AppMotion.fast,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: avatar == selected
                          ? colors.brand
                          : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                  child: UserAvatar(
                    name: name,
                    avatar: avatar,
                    size: 52,
                    border: Border.all(color: colors.hairline),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
