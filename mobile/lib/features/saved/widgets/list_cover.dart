import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/theme_context.dart';
import '../../map/data/attraction.dart';

/// A list's cover: artwork for up to four of its places, or an icon while
/// the list is empty. Photos replace the artwork once places have them.
class ListCover extends StatelessWidget {
  const ListCover({
    super.key,
    required this.places,
    required this.emptyIcon,
    this.radius = AppRadius.md,
  });

  final List<Attraction> places;
  final IconData emptyIcon;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final shown = places.take(4).toList();
    return ExcludeSemantics(
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          // Shows between the tiles of the mosaic.
          color: shown.isEmpty ? colors.surfaceRaised : colors.background,
          borderRadius: BorderRadius.circular(radius),
          border: shown.isEmpty ? Border.all(color: colors.hairline) : null,
        ),
        child: shown.isEmpty
            ? Center(
                child: Icon(emptyIcon, size: 34, color: colors.textSecondary),
              )
            : _mosaic(shown),
      ),
    );
  }

  /// One place fills the cover; two sit side by side; three are one tall
  /// tile and two small ones; four make a grid.
  static Widget _mosaic(List<Attraction> shown) {
    Widget tile(int i) => Expanded(child: _Art(category: shown[i].category));
    const gap = SizedBox.square(dimension: 2);
    return switch (shown.length) {
      1 => _Art(category: shown.first.category),
      2 => Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [tile(0), gap, tile(1)],
      ),
      3 => Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          tile(0),
          gap,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [tile(1), gap, tile(2)],
            ),
          ),
        ],
      ),
      _ => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [tile(0), gap, tile(1)],
            ),
          ),
          gap,
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [tile(2), gap, tile(3)],
            ),
          ),
        ],
      ),
    };
  }
}

/// A category's colour and icon, until places have photos.
class _Art extends StatelessWidget {
  const _Art({required this.category});

  final AttractionCategory category;

  @override
  Widget build(BuildContext context) {
    final color = category.color;
    return LayoutBuilder(
      builder: (context, constraints) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(color, Colors.white, 0.25)!,
              Color.lerp(color, Colors.black, 0.35)!,
            ],
          ),
        ),
        child: Center(
          child: Icon(
            category.icon,
            size: constraints.biggest.shortestSide * 0.4,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ),
    );
  }
}
