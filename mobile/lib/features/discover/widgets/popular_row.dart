import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/glass.dart';
import '../discover_data.dart';
import 'place_art.dart';

class PopularRow extends StatelessWidget {
  const PopularRow({super.key, required this.places, required this.onOpen});

  final List<PopularPlace> places;
  final ValueChanged<PopularPlace> onOpen;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 210,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        itemCount: places.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) =>
            _PopularCard(place: places[i], onTap: () => onOpen(places[i])),
      ),
    );
  }
}

class _PopularCard extends StatelessWidget {
  const _PopularCard({required this.place, required this.onTap});

  final PopularPlace place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(26));
    final colors = context.colors;
    return Container(
      width: 150,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: AppShadows.soft(colors),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            PlaceArt(style: place.art),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.4, 1],
                  colors: [Colors.transparent, Color(0xC0111314)],
                ),
              ),
            ),
            Positioned(
              top: 10,
              left: 10,
              child: GlassChip(
                icon: Icons.star_rounded,
                iconColor: colors.accent,
                label: place.rating.toStringAsFixed(1),
              ),
            ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    place.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    place.region,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            Material(
              type: MaterialType.transparency,
              child: InkWell(onTap: onTap),
            ),
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  border: Border.all(color: colors.glassBorder, width: 1.2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
