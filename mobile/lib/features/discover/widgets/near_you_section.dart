import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/glass.dart';
import '../discover_data.dart';
import 'map_preview.dart';
import 'place_art.dart';
import 'section_header.dart';

enum TravelMode { walk, drive }

class NearYouSection extends StatefulWidget {
  const NearYouSection({
    super.key,
    required this.places,
    required this.onOpenMap,
    required this.onOpenPlace,
  });

  final List<NearbyPlace> places;
  final VoidCallback onOpenMap;
  final ValueChanged<NearbyPlace> onOpenPlace;

  @override
  State<NearYouSection> createState() => _NearYouSectionState();
}

class _NearYouSectionState extends State<NearYouSection> {
  TravelMode _mode = TravelMode.walk;

  @override
  Widget build(BuildContext context) {
    final places = widget.places;
    return Column(
      children: [
        SectionHeader(
          title: 'Near you',
          subtitle: 'Around Kandy, within 7 km',
          trailing: _ModeToggle(
            mode: _mode,
            onChanged: (mode) => setState(() => _mode = mode),
          ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: MapPreview(places: places, onOpenMap: widget.onOpenMap),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 206,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            itemCount: places.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) => _NearbyCard(
              number: i + 1,
              place: places[i],
              mode: _mode,
              onTap: () => widget.onOpenPlace(places[i]),
            ),
          ),
        ),
      ],
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.mode, required this.onChanged});

  final TravelMode mode;
  final ValueChanged<TravelMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: colors.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ModeOption(
            icon: Icons.directions_walk_rounded,
            label: 'Walk',
            selected: mode == TravelMode.walk,
            onTap: () => onChanged(TravelMode.walk),
          ),
          _ModeOption(
            icon: Icons.directions_car_outlined,
            label: 'Drive',
            selected: mode == TravelMode.drive,
            onTap: () => onChanged(TravelMode.drive),
          ),
        ],
      ),
    );
  }
}

class _ModeOption extends StatelessWidget {
  const _ModeOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final foreground = selected ? colors.textPrimary : colors.textSecondary;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.base,
          curve: AppMotion.standard,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? colors.surfaceRaised : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            boxShadow: [
              if (selected)
                BoxShadow(
                  color: colors.shadow,
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: foreground),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontSize: 13,
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

class _NearbyCard extends StatelessWidget {
  const _NearbyCard({
    required this.number,
    required this.place,
    required this.mode,
    required this.onTap,
  });

  final int number;
  final NearbyPlace place;
  final TravelMode mode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final minutes = mode == TravelMode.walk
        ? place.walkMinutes
        : place.driveMinutes;

    return Container(
      width: 196,
      decoration: BoxDecoration(
        color: colors.surfaceRaised.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.hairline),
        boxShadow: AppShadows.soft(colors),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(23),
                ),
                child: SizedBox(
                  height: 112,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      PlaceArt(style: place.art),
                      Positioned(
                        top: 10,
                        left: 10,
                        child: _DistanceBadge(
                          number: number,
                          color: place.pinColor,
                          distanceKm: place.distanceKm,
                        ),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: GlassChip(label: place.openLabel, onImage: true),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        place.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 15,
                          height: 1.2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.star_rounded,
                            size: 15,
                            color: colors.accent,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              '${place.rating} · ${place.kind}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                          Icon(
                            mode == TravelMode.walk
                                ? Icons.directions_walk_rounded
                                : Icons.directions_car_outlined,
                            size: 14,
                            color: colors.brand,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '$minutes min',
                            style: TextStyle(
                              color: colors.brand,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DistanceBadge extends StatelessWidget {
  const _DistanceBadge({
    required this.number,
    required this.color,
    required this.distanceKm,
  });

  final int number;
  final Color color;
  final double distanceKm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 10, 4),
      decoration: BoxDecoration(
        color: AppPalette.paper.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Text(
              '$number',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$distanceKm km',
            style: const TextStyle(
              color: AppPalette.ink900,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
