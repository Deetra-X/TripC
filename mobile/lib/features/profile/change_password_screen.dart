import 'package:flutter/material.dart';

import '../../core/auth/auth_service.dart';
import '../login/validators.dart';
import '../login/widgets/password_field.dart';
import 'widgets/account_form.dart';

/// Sets a new password, after checking the current one.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AccountForm(
      title: 'Change password',
      intro: 'Use at least 8 characters.',
      submitLabel: 'Save password',
      successMessage: 'Password changed',
      onSubmit: () =>
          AuthScope.read(context)
              .changePassword(current: _current.text, newPassword: _new.text),
      children: [
        PasswordField(
          controller: _current,
          label: 'Current password',
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.password],
          validator: (value) => (value == null || value.isEmpty)
              ? 'Enter your current password.'
              : null,
        ),
        PasswordField(
          controller: _new,
          label: 'New password',
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.newPassword],
          validator: validateNewPassword,
        ),
        PasswordField(
          controller: _confirm,
          label: 'Confirm new password',
          textInputAction: TextInputAction.done,
          validator: (value) =>
              value != _new.text ? 'Passwords do not match.' : null,
        ),
      ],
    );
  }
}
