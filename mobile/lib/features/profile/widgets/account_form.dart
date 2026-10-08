import 'package:flutter/material.dart';

import '../../../core/auth/auth_service.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/theme_context.dart';

/// A settings page holding one short form, e.g. to change the email: its
/// fields, any error from saving, and a button that shows progress while it
/// saves. Once saved it closes and shows [successMessage].
class AccountForm extends StatefulWidget {
  const AccountForm({
    super.key,
    required this.title,
    this.intro,
    required this.children,
    required this.submitLabel,
    required this.successMessage,
    required this.onSubmit,
  });

  final String title;
  final String? intro;
  final List<Widget> children;
  final String submitLabel;
  final String successMessage;

  /// Saves the form. An [AuthException] is shown above the button.
  final Future<void> Function() onSubmit;

  @override
  State<AccountForm> createState() => _AccountFormState();
}

class _AccountFormState extends State<AccountForm> {
  final _form = GlobalKey<FormState>();
  bool _saving = false;
  String? _error;

  Future<void> _submit() async {
    if (_saving || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSubmit();
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(widget.successMessage)));
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final error = _error;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: Text(widget.title, style: context.text.titleLarge)),
      body: Form(
        key: _form,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            20,
            AppSpace.sm,
            20,
            AppSpace.xxxl + MediaQuery.viewPaddingOf(context).bottom,
          ),
          children: [
            if (widget.intro case final intro?) ...[
              Text(intro, style: TextStyle(color: colors.textSecondary)),
              const SizedBox(height: AppSpace.xxl),
            ],
            for (var i = 0; i < widget.children.length; i++) ...[
              if (i > 0) const SizedBox(height: AppSpace.lg),
              widget.children[i],
            ],
            if (error != null) ...[
              const SizedBox(height: AppSpace.lg),
              Text(error, style: TextStyle(color: colors.danger)),
            ],
            const SizedBox(height: AppSpace.xxl),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(widget.submitLabel),
            ),
          ],
        ),
      ),
    );
  }
}
