import 'package:flutter/material.dart';

import '../../../core/theme/theme_context.dart';
import '../../map/data/attraction.dart';
import '../data/saved_places.dart';
import 'save_to_list_sheet.dart';

/// Heart that saves a place to Favourites or one of the user's lists; it's
/// filled once the place is saved anywhere. Shows nothing where there are
/// no saved places, e.g. a map shown on its own.
class SaveButton extends StatelessWidget {
  const SaveButton({super.key, required this.place});

  final Attraction place;

  @override
  Widget build(BuildContext context) {
    final saved = SavedScope.maybeOf(context);
    if (saved == null) return const SizedBox.shrink();
    final colors = context.colors;
    return IconButton(
      tooltip: 'Save',
      isSelected: saved.isSaved(place.id),
      onPressed: () => showSaveToList(context, place),
      icon: Icon(Icons.favorite_border_rounded, color: colors.textSecondary),
      selectedIcon: Icon(Icons.favorite_rounded, color: colors.brand),
    );
  }
}
