import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/theme_context.dart';
import '../discover_data.dart';
import 'place_art.dart';

/// Horizontal filter chips; a null selection means "All".
class CategoryChips extends StatelessWidget {
  const CategoryChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final PlaceCategory? selected;
  final ValueChanged<PlaceCategory?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        spacing: 8,
        children: [
          _Chip(
            label: 'All',
            art: ArtStyle.sigiriya,
            selected: selected == null,
            onTap: () => onSelected(null),
          ),
          for (final category in PlaceCategory.values)
            _Chip(
              label: category.label,
              art: category.art,
              selected: selected == category,
              onTap: () => onSelected(category),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.art,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final ArtStyle art;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.base,
          curve: AppMotion.standard,
          padding: const EdgeInsets.fromLTRB(5, 5, 16, 5),
          decoration: BoxDecoration(
            color: selected
                ? colors.inverse
                : colors.surfaceRaised.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: selected
                  ? colors.accent.withValues(alpha: 0.5)
                  : colors.hairline,
            ),
            boxShadow: [
              if (selected)
                BoxShadow(
                  color: colors.accent.withValues(alpha: 0.25),
                  blurRadius: 14,
                ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipOval(
                child: SizedBox.square(
                  dimension: 36,
                  child: PlaceArt(style: art),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: selected ? colors.onInverse : colors.textPrimary,
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
