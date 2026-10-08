import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/theme_context.dart';
import '../../map/data/attraction.dart';

/// Lets the user choose the interests that personalise For You. Returns the
/// new selection, or null if they close the sheet.
Future<Set<InterestTag>?> showInterestPicker(
  BuildContext context,
  Set<InterestTag> current,
) {
  return showModalBottomSheet<Set<InterestTag>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.colors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (_) => _InterestPicker(initial: current),
  );
}

class _InterestPicker extends StatefulWidget {
  const _InterestPicker({required this.initial});

  final Set<InterestTag> initial;

  @override
  State<_InterestPicker> createState() => _InterestPickerState();
}

class _InterestPickerState extends State<_InterestPicker> {
  late final _selected = {...widget.initial};

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpace.xxl,
        AppSpace.md,
        AppSpace.xxl,
        AppSpace.xxl + MediaQuery.viewPaddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpace.xl),
              decoration: BoxDecoration(
                color: colors.hairline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text('What do you love?', style: context.text.headlineSmall),
          const SizedBox(height: AppSpace.sm),
          Text(
            'Pick a few. We use them to rank places around Sri Lanka for '
            'you.',
            style: context.text.bodyMedium?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpace.xl),
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              for (final tag in InterestTag.values)
                _InterestChip(
                  tag: tag,
                  selected: _selected.contains(tag),
                  onTap: () => setState(
                    () => _selected.contains(tag)
                        ? _selected.remove(tag)
                        : _selected.add(tag),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpace.xxl),
          FilledButton(
            onPressed: _selected.isEmpty
                ? null
                : () => Navigator.of(context).pop(_selected),
            child: Text(
              _selected.isEmpty ? 'Pick at least one' : 'Show my picks',
            ),
          ),
        ],
      ),
    );
  }
}

class _InterestChip extends StatelessWidget {
  const _InterestChip({
    required this.tag,
    required this.selected,
    required this.onTap,
  });

  final InterestTag tag;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final foreground = selected ? colors.onInverse : colors.textPrimary;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.base,
          curve: AppMotion.standard,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? colors.inverse : colors.surfaceRaised,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: selected ? colors.inverse : colors.hairline,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? Icons.check_rounded : tag.icon,
                size: 17,
                color: selected ? foreground : colors.brand,
              ),
              const SizedBox(width: 6),
              Text(
                tag.label,
                style: TextStyle(
                  color: foreground,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
