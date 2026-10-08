import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_tokens.dart';
import '../data/attraction.dart';

// Markers sit on the map tiles, so they use fixed colours that read on both
// the light and dark map styles.

/// An attraction on the map: its category icon on its category colour.
/// Zoomed out it shrinks to a small dot, so a whole island of places stays
/// readable; the selected place always shows its icon.
class AttractionMarker extends StatelessWidget {
  const AttractionMarker({
    super.key,
    required this.attraction,
    required this.selected,
    required this.onTap,
  });

  /// Size of the marker's box; markers grow into it when selected.
  static const double extent = 56;

  /// Below this zoom level, unselected markers are drawn as dots.
  static const double iconZoom = 9;

  final Attraction attraction;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = attraction.category.color;
    final zoom = MapCamera.maybeOf(context)?.zoom ?? iconZoom;
    final dot = !selected && zoom < iconZoom;
    final size = selected
        ? 50.0
        : dot
        ? 16.0
        : 36.0;
    return Semantics(
      button: true,
      selected: selected,
      label: attraction.name,
      // Only the marker itself (or a small area round a dot) is tappable, so
      // neighbouring markers don't steal each other's taps.
      child: Center(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: SizedBox.square(
            dimension: math.max(size, 28),
            child: Center(
              child: AnimatedContainer(
                duration: AppMotion.base,
                curve: AppMotion.standard,
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  border: Border.all(
                    color: selected ? AppPalette.champagne200 : Colors.white,
                    width: selected
                        ? 3
                        : dot
                        ? 2
                        : 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0x55000000),
                      blurRadius: dot ? 4 : 8,
                      offset: Offset(0, dot ? 1 : 3),
                    ),
                    if (selected)
                      BoxShadow(
                        color: color.withValues(alpha: 0.55),
                        blurRadius: 18,
                      ),
                  ],
                ),
                child: dot
                    ? null
                    : Icon(
                        attraction.category.icon,
                        color: Colors.white,
                        size: size * 0.5,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A destination the user dropped by tapping the map. Its tip marks the
/// point, so place it with `Alignment.topCenter`.
class DroppedPinMarker extends StatelessWidget {
  const DroppedPinMarker({super.key});

  static const Size size = Size(44, 52);

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.location_on,
      size: 52,
      color: AppPalette.coral,
      shadows: [
        Shadow(color: Color(0x66000000), blurRadius: 8, offset: Offset(0, 3)),
      ],
    );
  }
}

/// The user's position: a blue dot with a pulsing halo.
class UserLocationDot extends StatefulWidget {
  const UserLocationDot({super.key});

  static const double extent = 64;
  static const Color blue = Color(0xFF3B82F6);

  @override
  State<UserLocationDot> createState() => _UserLocationDotState();
}

class _UserLocationDotState extends State<UserLocationDot>
    with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulse.stop();
    } else if (!_pulse.isAnimating) {
      _pulse.repeat();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Your location',
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, _) {
          final t = _pulse.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 22 + 42 * t,
                height: 22 + 42 * t,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: UserLocationDot.blue.withValues(alpha: 0.35 * (1 - t)),
                ),
              ),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: UserLocationDot.blue,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: const [
                    BoxShadow(color: Color(0x663B82F6), blurRadius: 10),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Distance label drawn on the map, e.g. halfway along the route.
class DistancePill extends StatelessWidget {
  const DistancePill({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppPalette.ink900,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.9),
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        label,
        maxLines: 1,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
