import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/theme/theme_context.dart';
import '../for_you/data/taste_profile.dart';
import '../map/data/attraction.dart';
import 'data/saved_places.dart';
import 'widgets/list_card.dart';
import 'widgets/list_cover.dart';
import 'widgets/list_name_dialog.dart';
import 'widgets/saved_empty_state.dart';
import 'widgets/saved_place_row.dart';

/// One list, or Recently viewed, with its places; tapping one shows it on
/// the map. Places can be swiped out of a list, and the user's own lists
/// renamed or deleted.
class SavedListScreen extends StatefulWidget {
  const SavedListScreen({
    super.key,
    required this.listId,
    required this.places,
    required this.onOpenPlace,
    required this.onExplore,
  });

  /// Null for Recently viewed.
  final String? listId;

  /// Every place, by id.
  final Map<String, Attraction> places;
  final ValueChanged<Attraction> onOpenPlace;
  final VoidCallback onExplore;

  @override
  State<SavedListScreen> createState() => _SavedListScreenState();
}

enum _ListAction { rename, delete }

class _SavedListScreenState extends State<SavedListScreen> {
  /// The list as last shown, so the page still has it while it closes after
  /// the list is deleted.
  SavedList? _list;

  void _open(Attraction place) {
    Navigator.of(context).pop();
    widget.onOpenPlace(place);
  }

  void _explore() {
    Navigator.of(context).pop();
    widget.onExplore();
  }

  void _showUndo(String message, VoidCallback undo) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          action: SnackBarAction(label: 'Undo', onPressed: undo),
        ),
      );
  }

  void _remove(SavedPlaces saved, SavedList list, Attraction place) {
    final index = list.placeIds.indexOf(place.id);
    saved.remove(list.id, place.id);
    _showUndo(
      'Removed from ${list.name}',
      () => saved.add(list.id, place.id, index: index),
    );
  }

  void _clearHistory(TasteProfile taste) {
    final ids = taste.recentlyViewed;
    taste.clearRecentlyViewed();
    _showUndo('Cleared recently viewed', () {
      for (final id in ids.reversed) {
        taste.viewed(id);
      }
    });
  }

  Future<void> _onAction(
    _ListAction action,
    SavedPlaces saved,
    SavedList list,
  ) async {
    switch (action) {
      case _ListAction.rename:
        final name = await showListNameDialog(
          context,
          saved: saved,
          renaming: list,
        );
        if (name != null) saved.renameList(list.id, name);
      case _ListAction.delete:
        final colors = context.colors;
        final delete = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: colors.surfaceRaised,
            title: Text('Delete "${list.name}"?'),
            content: const Text(
              'Only the list goes. Its places stay on the map and in your '
              'other lists.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: colors.danger),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        if (delete != true || !mounted) return;
        Navigator.of(context).pop();
        saved.deleteList(list.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final saved = SavedScope.of(context);
    final taste = TasteScope.of(context);
    final colors = context.colors;

    final listId = widget.listId;
    if (listId != null) _list = saved.list(listId) ?? _list;
    final list = _list;
    final recent = listId == null;
    final ids = recent ? taste.recentlyViewed : list?.placeIds ?? const [];
    final places = [for (final id in ids) ?widget.places[id]];
    final emptyIcon = recent
        ? Icons.history_rounded
        : list?.isFavourites ?? false
        ? Icons.favorite_border_rounded
        : Icons.bookmarks_outlined;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        actions: [
          if (recent && places.isNotEmpty)
            TextButton(
              onPressed: () => _clearHistory(taste),
              child: const Text('Clear'),
            ),
          if (list != null && !list.isFavourites)
            PopupMenuButton<_ListAction>(
              tooltip: 'List options',
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (action) => _onAction(action, saved, list),
              itemBuilder: (_) => const [
                PopupMenuItem(value: _ListAction.rename, child: Text('Rename')),
                PopupMenuItem(
                  value: _ListAction.delete,
                  child: Text('Delete list'),
                ),
              ],
            ),
          const SizedBox(width: AppSpace.sm),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.only(
          bottom: AppSpace.xxxl + MediaQuery.viewPaddingOf(context).bottom,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              height: 180,
              child: ListCover(
                places: places,
                emptyIcon: emptyIcon,
                radius: AppRadius.lg,
              ),
            ),
          ),
          const SizedBox(height: AppSpace.xl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recent ? 'Recently viewed' : list?.name ?? '',
                  style: context.text.headlineMedium,
                ),
                const SizedBox(height: AppSpace.xs),
                Text(
                  recent
                      ? '${placeCount(places.length)} · the last ones you '
                            'opened on the map'
                      : placeCount(places.length),
                  style: TextStyle(color: colors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          if (places.isEmpty)
            SavedEmptyState(
              icon: emptyIcon,
              title: 'Nothing here yet',
              message: recent
                  ? 'Places you open on the map show up here.'
                  : 'Tap the heart on a place on the map to save it here.',
              actionLabel: 'Explore the map',
              onAction: _explore,
            )
          else
            for (var i = 0; i < places.length; i++) ...[
              if (i > 0)
                Divider(
                  height: 1,
                  indent: 20,
                  endIndent: 20,
                  color: colors.hairline,
                ),
              _row(saved, list, places[i]),
            ],
        ],
      ),
    );
  }

  /// In a list, places can be swiped away; Recently viewed only shows them.
  Widget _row(SavedPlaces saved, SavedList? list, Attraction place) {
    final row = SavedPlaceRow(
      key: ValueKey('row-${place.id}'),
      place: place,
      onTap: () => _open(place),
    );
    if (list == null) return row;
    return Dismissible(
      key: ValueKey('dismiss-${place.id}'),
      direction: DismissDirection.endToStart,
      background: const _RemoveBackground(),
      onDismissed: (_) => _remove(saved, list, place),
      child: row,
    );
  }
}

class _RemoveBackground extends StatelessWidget {
  const _RemoveBackground();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      color: colors.danger,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: AppSpace.xxl),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.delete_outline_rounded, color: colors.onInverse),
          const SizedBox(width: AppSpace.sm),
          Text(
            'Remove',
            style: TextStyle(
              color: colors.onInverse,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
