import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/theme_context.dart';

class SearchRow extends StatelessWidget {
  const SearchRow({super.key, required this.onVoice, required this.onFilters});

  final VoidCallback onVoice;
  final VoidCallback onFilters;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: colors.surfaceRaised.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: colors.hairline),
                boxShadow: AppShadows.soft(colors),
              ),
              child: Center(
                child: TextField(
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search places & trails',
                    hintStyle: TextStyle(
                      color: colors.textTertiary,
                      fontSize: 14,
                    ),
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: colors.textPrimary,
                    ),
                    suffixIcon: IconButton(
                      tooltip: 'Voice search',
                      onPressed: onVoice,
                      icon: Icon(
                        Icons.mic_none_rounded,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.inverse,
              boxShadow: AppShadows.soft(colors),
            ),
            child: IconButton(
              tooltip: 'Filters',
              onPressed: onFilters,
              icon: Icon(Icons.tune_rounded, color: colors.onInverse),
            ),
          ),
        ],
      ),
    );
  }
}
