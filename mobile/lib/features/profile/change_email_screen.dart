import 'package:flutter/material.dart';

import '../../core/auth/auth_service.dart';
import '../login/validators.dart';
import '../login/widgets/password_field.dart';
import 'widgets/account_form.dart';

/// Moves the account to a new email, confirmed with the password.
class ChangeEmailScreen extends StatefulWidget {
  const ChangeEmailScreen({super.key});

  @override
  State<ChangeEmailScreen> createState() => _ChangeEmailScreenState();
}

class _ChangeEmailScreenState extends State<ChangeEmailScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = AuthScope.of(context).currentUser?.email ?? '';
    return AccountForm(
      title: 'Change email',
      intro:
          'You log in with $current. Enter your new email and your password '
          'to confirm it.',
      submitLabel: 'Save email',
      successMessage: 'Email updated',
      onSubmit: () =>
          AuthScope.read(context)
              .changeEmail(email: _email.text, password: _password.text),
      children: [
        TextFormField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          validator: validateEmail,
          decoration: const InputDecoration(labelText: 'New email'),
        ),
        PasswordField(
          controller: _password,
          label: 'Password',
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.password],
          validator: (value) =>
              (value == null || value.isEmpty) ? 'Enter your password.' : null,
        ),
      ],
    );
  }
}
