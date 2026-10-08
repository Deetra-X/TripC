import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/theme_context.dart';
import '../../map/data/attraction.dart';
import 'list_cover.dart';

/// "1 place", "3 places".
String placeCount(int count) => count == 1 ? '1 place' : '$count places';

/// A list in the Saved grid: its cover, name and how many places it has.
class ListCard extends StatelessWidget {
  const ListCard({
    super.key,
    required this.title,
    required this.places,
    required this.emptyIcon,
    required this.onTap,
  });

  final String title;
  final List<Attraction> places;
  final IconData emptyIcon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final count = places.isEmpty ? 'Nothing yet' : placeCount(places.length);
    return Semantics(
      button: true,
      label: '$title, $count',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: ListCover(places: places, emptyIcon: emptyIcon),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.titleMedium,
            ),
            const SizedBox(height: 2),
            Text(count, style: context.text.bodySmall),
          ],
        ),
      ),
    );
  }
}

/// The last card in the grid of the user's lists, for making another.
class NewListCard extends StatelessWidget {
  const NewListCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      label: 'New list',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: colors.hairline, width: 1.5),
                ),
                child: Center(
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.brandSoft,
                    ),
                    child: Icon(Icons.add_rounded, color: colors.brand),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text('New list', style: context.text.titleMedium),
            const SizedBox(height: 2),
            Text('Plan another trip', style: context.text.bodySmall),
          ],
        ),
      ),
    );
  }
}
