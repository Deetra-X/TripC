import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/theme_context.dart';
import '../../saved/widgets/save_button.dart';
import '../data/attraction.dart';
import '../data/trip_estimate.dart';
import '../routing/route_service.dart';
import 'category_badge.dart';
import 'explore_sheet.dart';

/// Sheet view for a chosen destination: what it is, and how far it is by
/// road and how long it takes to get there.
class DestinationPanel extends StatelessWidget {
  const DestinationPanel({
    super.key,
    required this.scrollController,
    required this.bottomPadding,
    required this.attraction,
    required this.point,
    required this.hasLocation,
    required this.route,
    required this.routing,
    required this.routeError,
    required this.straightLine,
    required this.onRetryRoute,
    required this.mode,
    required this.onModeChanged,
    required this.onShowRoute,
    required this.onEnableLocation,
    required this.onClose,
  });

  final ScrollController scrollController;
  final double bottomPadding;

  /// Null for a pin the user dropped on the map.
  final Attraction? attraction;
  final LatLng point;

  /// Whether the user's position is known.
  final bool hasLocation;

  /// The road route, once found.
  final RoadRoute? route;
  final bool routing;

  /// Why no road route could be found, if so.
  final String? routeError;

  /// Straight-line distance, shown only as a fallback when there is no road
  /// route.
  final TripEstimate? straightLine;
  final VoidCallback onRetryRoute;
  final TravelMode mode;
  final ValueChanged<TravelMode> onModeChanged;
  final VoidCallback onShowRoute;
  final VoidCallback onEnableLocation;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final place = attraction;
    final route = this.route;

    return ListView(
      controller: scrollController,
      padding: EdgeInsets.fromLTRB(
        AppSpace.xl,
        0,
        AppSpace.xl,
        bottomPadding + AppSpace.lg,
      ),
      children: [
        const SheetHandle(),
        Row(
          children: [
            if (place != null)
              CategoryBadge(category: place.category, size: 48)
            else
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppPalette.coral,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.push_pin_rounded, color: Colors.white),
              ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place?.name ?? 'Dropped pin',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.titleLarge,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    place == null
                        ? _formatPoint(point)
                        : [
                            place.district,
                            place.category.label,
                          ].where((s) => s.isNotEmpty).join(' · '),
                    style: context.text.bodySmall,
                  ),
                ],
              ),
            ),
            if (place != null) SaveButton(place: place),
            IconButton(
              tooltip: 'Close',
              onPressed: onClose,
              icon: Icon(Icons.close_rounded, color: colors.textSecondary),
            ),
          ],
        ),
        if (place != null) ..._facts(context, place),
        const SizedBox(height: AppSpace.xl),
        if (!hasLocation)
          _Notice(
            icon: Icons.location_off_rounded,
            message: 'Turn on location to see the route and distance.',
            action: TextButton(
              onPressed: onEnableLocation,
              child: const Text('Turn on'),
            ),
          )
        else ...[
          if (route != null)
            Row(
              children: [
                Expanded(
                  child: _Stat(
                    value: formatDistance(route.meters),
                    label: 'By road',
                  ),
                ),
                Expanded(
                  child: _Stat(
                    value: formatDuration(route.duration),
                    label: mode == TravelMode.walk ? 'On foot' : 'By car',
                  ),
                ),
              ],
            )
          else if (routing)
            Row(
              children: [
                SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: colors.brand,
                  ),
                ),
                const SizedBox(width: AppSpace.md),
                Text(
                  'Finding the best road route…',
                  style: TextStyle(color: colors.textSecondary),
                ),
              ],
            )
          else if (routeError != null)
            _Notice(
              icon: Icons.wrong_location_outlined,
              message: [
                'No road route: $routeError',
                if (straightLine != null)
                  '≈ ${straightLine!.distanceLabel} in a straight line.',
              ].join('\n'),
              action: TextButton(
                onPressed: onRetryRoute,
                child: const Text('Retry'),
              ),
            ),
          const SizedBox(height: AppSpace.lg),
          SegmentedButton<TravelMode>(
            expandedInsets: EdgeInsets.zero,
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                value: TravelMode.walk,
                icon: Icon(Icons.directions_walk_rounded),
                label: Text('Walk'),
              ),
              ButtonSegment(
                value: TravelMode.drive,
                icon: Icon(Icons.directions_car_rounded),
                label: Text('Drive'),
              ),
            ],
            selected: {mode},
            onSelectionChanged: (selection) => onModeChanged(selection.first),
          ),
          if (route != null) ...[
            const SizedBox(height: AppSpace.sm),
            Text(
              'Fastest route along the roads, from OSRM using OpenStreetMap '
              'data.',
              style: TextStyle(color: colors.textTertiary, fontSize: 12),
            ),
            const SizedBox(height: AppSpace.lg),
            FilledButton.icon(
              onPressed: onShowRoute,
              icon: const Icon(Icons.route_rounded),
              label: const Text('Show route on map'),
            ),
          ],
        ],
        // The description comes last so distance and time stay in view.
        if (place?.description case final description?) ...[
          const SizedBox(height: AppSpace.xl),
          Text(
            description,
            style: context.text.bodyMedium?.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  /// Rating, hidden-gem status, opening hours and conditions.
  List<Widget> _facts(BuildContext context, Attraction place) {
    final colors = context.colors;
    final rating = place.rating;
    final reviews = place.reviewCount;
    final facts = [
      if (rating != null)
        _Fact(
          icon: Icons.star_rounded,
          iconColor: colors.accent,
          label: reviews != null
              ? '${rating.toStringAsFixed(1)} (${_thousands(reviews)})'
              : rating.toStringAsFixed(1),
        ),
      if (place.hiddenGem)
        _Fact(
          icon: Icons.diamond_outlined,
          iconColor: colors.accent,
          label: 'Hidden gem',
        ),
      if (place.openTime != null && place.closeTime != null)
        _Fact(
          icon: Icons.schedule_rounded,
          label: '${place.openTime}–${place.closeTime}',
        ),
      if (place.indoorOutdoor case final setting?)
        _Fact(
          icon: setting == 'indoor'
              ? Icons.roofing_rounded
              : Icons.wb_sunny_outlined,
          label: switch (setting) {
            'indoor' => 'Indoor',
            'outdoor' => 'Outdoor',
            _ => 'Indoor & outdoor',
          },
        ),
      if (place.rainSensitive == true)
        const _Fact(icon: Icons.umbrella_rounded, label: 'Best on dry days'),
    ];
    return [
      if (facts.isNotEmpty) ...[
        const SizedBox(height: AppSpace.lg),
        Wrap(spacing: AppSpace.sm, runSpacing: AppSpace.sm, children: facts),
      ],
    ];
  }
}

String _formatPoint(LatLng point) {
  final lat = point.latitude;
  final lng = point.longitude;
  return '${lat.abs().toStringAsFixed(4)}° ${lat >= 0 ? 'N' : 'S'}, '
      '${lng.abs().toStringAsFixed(4)}° ${lng >= 0 ? 'E' : 'W'}';
}

/// 1524 → "1,524".
String _thousands(int n) =>
    n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.label, this.iconColor});

  final IconData icon;
  final String label;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: colors.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: iconColor ?? colors.textSecondary),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// A boxed message with an icon and an optional action.
class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.message, this.action});

  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.hairline),
      ),
      child: Row(
        children: [
          Icon(icon, color: colors.textSecondary),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Text(message, style: TextStyle(color: colors.textSecondary)),
          ),
          ?action,
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: context.text.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(label, style: context.text.bodySmall),
      ],
    );
  }
}
