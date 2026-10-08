import 'package:flutter/material.dart';

import '../../core/auth/auth_service.dart';
import '../../core/auth/profile_avatar.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/theme_context.dart';
import '../../core/widgets/user_avatar.dart';
import 'widgets/account_form.dart';
import 'widgets/avatar_picker.dart';

/// Changes what others see of the user: their picture, name, where they're
/// from and a line about them.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final AuthUser _user = AuthScope.read(context).currentUser!;
  late final _name = TextEditingController(text: _user.name);
  late final _home = TextEditingController(text: _user.home);
  late final _about = TextEditingController(text: _user.about);
  late ProfileAvatar _avatar = _user.avatar;

  @override
  void dispose() {
    _name.dispose();
    _home.dispose();
    _about.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AccountForm(
      title: 'Edit profile',
      submitLabel: 'Save changes',
      successMessage: 'Profile updated',
      onSubmit: () => AuthScope.read(context).updateProfile(
        name: _name.text,
        home: _home.text,
        about: _about.text,
        avatar: _avatar,
      ),
      children: [
        // The pictures show the initial of the name as it's typed.
        ListenableBuilder(
          listenable: _name,
          builder: (context, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: UserAvatar(
                  name: _name.text,
                  avatar: _avatar,
                  size: 96,
                  border: Border.all(color: colors.hairline),
                ),
              ),
              const SizedBox(height: AppSpace.xl),
              Text(
                'Profile picture',
                style: context.text.labelMedium?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              AvatarPicker(
                name: _name.text,
                selected: _avatar,
                onChanged: (avatar) => setState(() => _avatar = avatar),
              ),
            ],
          ),
        ),
        TextFormField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          maxLength: 50,
          decoration: const InputDecoration(labelText: 'Name'),
          validator: (value) =>
              (value?.trim() ?? '').isEmpty ? 'Enter your name.' : null,
        ),
        TextFormField(
          controller: _home,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          maxLength: 60,
          decoration: const InputDecoration(
            labelText: "Where you're from",
            hintText: 'e.g. Colombo, Sri Lanka',
          ),
        ),
        TextFormField(
          controller: _about,
          textCapitalization: TextCapitalization.sentences,
          minLines: 2,
          maxLines: 4,
          maxLength: 160,
          decoration: const InputDecoration(
            labelText: 'About you',
            hintText: 'e.g. Weekend hiker, always chasing waterfalls',
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }
}
