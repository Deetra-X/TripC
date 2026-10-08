import 'package:flutter/material.dart';

import '../../../core/theme/theme_context.dart';
import '../data/saved_places.dart';

/// Asks for a name for a new list, or a new name for [renaming]. Returns the
/// name without surrounding spaces, or null if the user cancels.
Future<String?> showListNameDialog(
  BuildContext context, {
  required SavedPlaces saved,
  SavedList? renaming,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _ListNameDialog(saved: saved, renaming: renaming),
  );
}

class _ListNameDialog extends StatefulWidget {
  const _ListNameDialog({required this.saved, required this.renaming});

  final SavedPlaces saved;
  final SavedList? renaming;

  @override
  State<_ListNameDialog> createState() => _ListNameDialogState();
}

class _ListNameDialogState extends State<_ListNameDialog> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.renaming?.name);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String? _validate(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Give your list a name';
    if (widget.saved.nameTaken(name, exceptId: widget.renaming?.id)) {
      return 'You already have a list called "$name"';
    }
    return null;
  }

  void _submit() {
    if (_form.currentState!.validate()) {
      Navigator.of(context).pop(_name.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final renaming = widget.renaming != null;
    return AlertDialog(
      backgroundColor: context.colors.surfaceRaised,
      title: Text(renaming ? 'Rename list' : 'New list'),
      content: Form(
        key: _form,
        child: TextFormField(
          controller: _name,
          autofocus: true,
          maxLength: SavedPlaces.maxNameLength,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(hintText: 'e.g. Kandy weekend'),
          validator: _validate,
          onFieldSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _submit,
          child: Text(renaming ? 'Save' : 'Create'),
        ),
      ],
    );
  }
}
