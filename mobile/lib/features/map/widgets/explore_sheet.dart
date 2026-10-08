import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/theme_context.dart';
import '../data/attraction.dart';
import 'category_badge.dart';

enum PlaceSort { nearest, rating }

/// Rounded surface of the map's bottom sheet with a drag handle.
class MapSheetSurface extends StatelessWidget {
  const MapSheetSurface({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    const radius = BorderRadius.vertical(top: Radius.circular(AppRadius.lg));
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: radius,
        border: Border(top: BorderSide(color: colors.hairline)),
        boxShadow: AppShadows.raised(colors),
      ),
      child: ClipRRect(borderRadius: radius, child: child),
    );
  }
}

class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 10, bottom: 12),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: context.colors.hairline,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

/// Browse view of the sheet: search, category filters and the places list.
class ExploreSheet extends StatelessWidget {
  const ExploreSheet({
    super.key,
    required this.scrollController,
    required this.bottomPadding,
    required this.places,
    required this.unmappedCount,
    required this.loading,
    required this.failed,
    required this.onRetry,
    required this.category,
    required this.onCategoryChanged,
    required this.sort,
    required this.onSortChanged,
    required this.canSortByDistance,
    required this.onQueryChanged,
    required this.onSearchFocused,
    required this.distanceOf,
    required this.onSelect,
  });

  final ScrollController scrollController;
  final double bottomPadding;
  final List<Attraction> places;

  /// Matching places left off the map because they have no coordinates yet.
  final int unmappedCount;
  final bool loading;
  final bool failed;
  final VoidCallback onRetry;
  final AttractionCategory? category;
  final ValueChanged<AttractionCategory?> onCategoryChanged;
  final PlaceSort sort;
  final ValueChanged<PlaceSort> onSortChanged;
  final bool canSortByDistance;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onSearchFocused;

  /// Distance from the user, or null while their location is unknown.
  final String? Function(Attraction) distanceOf;
  final ValueChanged<Attraction> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final nearest = sort == PlaceSort.nearest && canSortByDistance;

    return ListView(
      controller: scrollController,
      padding: EdgeInsets.only(bottom: bottomPadding + AppSpace.lg),
      children: [
        const SheetHandle(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.xl),
          child: TextField(
            onChanged: onQueryChanged,
            onTap: onSearchFocused,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Find places or regions',
              prefixIcon: Icon(Icons.search_rounded, color: colors.textPrimary),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                borderSide: BorderSide(color: colors.hairline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                borderSide: BorderSide(color: colors.hairline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                borderSide: BorderSide(color: colors.brand, width: 1.5),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpace.md),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.xl),
          child: Row(
            spacing: AppSpace.sm,
            children: [
              _FilterChip(
                label: 'All',
                icon: Icons.tune_rounded,
                selected: category == null,
                onTap: () => onCategoryChanged(null),
              ),
              for (final c in AttractionCategory.values)
                if (c != AttractionCategory.other)
                  _FilterChip(
                    label: c.label,
                    icon: c.icon,
                    iconColor: c.color,
                    selected: category == c,
                    onTap: () => onCategoryChanged(c),
                  ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        if (loading)
          const _Message(
            icon: null,
            title: 'Loading places…',
            showSpinner: true,
          )
        else if (failed)
          _Message(
            icon: Icons.cloud_off_rounded,
            title: "Couldn't load places",
            action: TextButton(onPressed: onRetry, child: const Text('Retry')),
          )
        else ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpace.xl, 0, AppSpace.sm, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${places.length} ${places.length == 1 ? 'place' : 'places'}',
                    style: context.text.titleMedium,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => onSortChanged(
                    sort == PlaceSort.nearest
                        ? PlaceSort.rating
                        : PlaceSort.nearest,
                  ),
                  icon: const Icon(Icons.swap_vert_rounded, size: 18),
                  label: Text(nearest ? 'Nearest' : 'Top rated'),
                ),
              ],
            ),
          ),
          if (places.isEmpty)
            _Message(
              icon: Icons.search_off_rounded,
              title: 'No places match',
              action: TextButton(
                onPressed: () => onCategoryChanged(null),
                child: const Text('Show all categories'),
              ),
            ),
          for (final place in places)
            _PlaceTile(
              key: ValueKey('place-${place.id}'),
              place: place,
              distance: distanceOf(place),
              onTap: () => onSelect(place),
            ),
          if (unmappedCount > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.xl,
                AppSpace.md,
                AppSpace.xl,
                0,
              ),
              child: Text(
                unmappedCount == 1
                    ? '1 more place has no coordinates yet.'
                    : '$unmappedCount more places have no coordinates yet.',
                style: TextStyle(color: colors.textTertiary, fontSize: 12.5),
              ),
            ),
        ],
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.iconColor,
  });

  final String label;
  final IconData icon;
  final Color? iconColor;
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
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
                icon,
                size: 16,
                color: selected ? foreground : iconColor ?? foreground,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontSize: 13.5,
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

class _PlaceTile extends StatelessWidget {
  const _PlaceTile({
    super.key,
    required this.place,
    required this.distance,
    required this.onTap,
  });

  final Attraction place;
  final String? distance;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final rating = place.rating;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.xl,
          vertical: 10,
        ),
        child: Row(
          children: [
            CategoryBadge(category: place.category, size: 48),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      place.district,
                      place.category.label,
                    ].where((s) => s.isNotEmpty).join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (distance != null)
                  Text(
                    distance!,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                if (rating != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded, size: 14, color: colors.accent),
                      const SizedBox(width: 2),
                      Text(
                        rating.toStringAsFixed(1),
                        style: context.text.bodySmall,
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    this.action,
    this.showSpinner = false,
  });

  final IconData? icon;
  final String title;
  final Widget? action;
  final bool showSpinner;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.xxl),
      child: Column(
        children: [
          if (showSpinner)
            SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: colors.brand,
              ),
            )
          else if (icon != null)
            Icon(icon, size: 32, color: colors.textTertiary),
          const SizedBox(height: AppSpace.md),
          Text(title, style: TextStyle(color: colors.textSecondary)),
          ?action,
        ],
      ),
    );
  }
}
