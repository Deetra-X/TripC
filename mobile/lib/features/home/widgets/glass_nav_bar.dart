import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/glass.dart';

// The bar stays dark in both themes, so its contents use fixed light colours.
const _selected = AppPalette.champagne300;

class GlassNavItem {
  const GlassNavItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// Floating dark-glass bottom bar. The selected tab grows into a glowing
/// pill with its label.
class GlassNavBar extends StatelessWidget {
  const GlassNavBar({
    super.key,
    required this.items,
    required this.index,
    required this.onSelected,
  });

  final List<GlassNavItem> items;
  final int index;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: AppShadows.raised(colors),
        ),
        child: Glass(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          tint: colors.navTint,
          opacity: 0.92,
          blur: 20,
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < items.length; i++)
                // Only the selected tab can shrink, truncating its label on
                // narrow screens or with large text.
                Flexible(
                  fit: FlexFit.loose,
                  flex: i == index ? 1 : 0,
                  child: _NavButton(
                    item: items[i],
                    selected: i == index,
                    onTap: () => onSelected(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final GlassNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: item.label,
      child: Semantics(
        button: true,
        selected: selected,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: AppMotion.standard,
            height: 52,
            padding: EdgeInsets.symmetric(horizontal: selected ? 18 : 16),
            decoration: BoxDecoration(
              color: selected
                  ? _selected.withValues(alpha: 0.14)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: selected
                    ? _selected.withValues(alpha: 0.4)
                    : Colors.transparent,
              ),
              boxShadow: [
                if (selected)
                  BoxShadow(
                    color: _selected.withValues(alpha: 0.18),
                    blurRadius: 16,
                  ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  item.icon,
                  size: 22,
                  color: selected ? _selected : Colors.white70,
                ),
                Flexible(
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: AppMotion.standard,
                    child: selected
                        ? Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Text(
                              item.label,
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
