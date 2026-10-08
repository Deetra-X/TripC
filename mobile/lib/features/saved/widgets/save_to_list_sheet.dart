import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/theme_context.dart';
import '../../map/data/attraction.dart';
import '../data/saved_places.dart';
import 'list_card.dart';
import 'list_name_dialog.dart';

/// Lets the user put [place] in Favourites, any of their lists or a new
/// list. Each tap applies straight away.
Future<void> showSaveToList(BuildContext context, Attraction place) {
  final saved = SavedScope.read(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.colors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    // The sheet sits above the screen that opened it, so it gets the saved
    // places again.
    builder: (_) => SavedScope(
      saved: saved,
      child: _SaveToList(place: place),
    ),
  );
}

class _SaveToList extends StatelessWidget {
  const _SaveToList({required this.place});

  final Attraction place;

  Future<void> _newList(BuildContext context, SavedPlaces saved) async {
    final name = await showListNameDialog(context, saved: saved);
    if (name != null) saved.createList(name, placeId: place.id);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final saved = SavedScope.of(context);
    final lists = [saved.favourites, ...saved.customLists()];

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
          Text('Save to a list', style: context.text.headlineSmall),
          const SizedBox(height: AppSpace.xs),
          Text(
            place.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.text.bodyMedium?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          for (final list in lists)
            _ListOption(
              key: ValueKey('option-${list.id}'),
              list: list,
              selected: list.placeIds.contains(place.id),
              onTap: () => saved.toggle(list.id, place.id),
            ),
          _Option(
            leading: Icon(Icons.add_rounded, color: colors.brand),
            title: 'New list',
            subtitle: 'Start a list with this place',
            onTap: () => _newList(context, saved),
          ),
          const SizedBox(height: AppSpace.xl),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

class _ListOption extends StatelessWidget {
  const _ListOption({
    super.key,
    required this.list,
    required this.selected,
    required this.onTap,
  });

  final SavedList list;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return _Option(
      leading: Icon(
        list.isFavourites ? Icons.favorite_rounded : Icons.bookmarks_outlined,
        color: list.isFavourites ? colors.brand : colors.textSecondary,
      ),
      title: list.name,
      subtitle: list.count == 0 ? 'Nothing yet' : placeCount(list.count),
      selected: selected,
      onTap: onTap,
    );
  }
}

/// A row in the sheet; with [selected] it's a checkbox.
class _Option extends StatelessWidget {
  const _Option({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.selected,
  });

  final Widget leading;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool? selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final selected = this.selected;
    return Semantics(
      button: selected == null,
      checked: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colors.surfaceRaised,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: colors.hairline),
                ),
                child: leading,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.titleSmall,
                    ),
                    Text(subtitle, style: context.text.bodySmall),
                  ],
                ),
              ),
              if (selected != null)
                AnimatedSwitcher(
                  duration: AppMotion.fast,
                  child: Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    key: ValueKey(selected),
                    color: selected ? colors.brand : colors.textTertiary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
