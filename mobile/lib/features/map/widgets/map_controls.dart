import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/glass.dart';
import '../location/location_service.dart';

/// Round glass button floating over the map.
class MapRoundButton extends StatelessWidget {
  const MapRoundButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: AppShadows.soft(context.colors),
      ),
      child: Glass(
        borderRadius: BorderRadius.circular(26),
        opacity: 0.85,
        child: SizedBox.square(
          dimension: 52,
          child: IconButton(
            tooltip: tooltip,
            onPressed: onPressed,
            icon: Icon(icon, color: context.colors.textPrimary),
          ),
        ),
      ),
    );
  }
}

/// Map data credit, which the tile and routing providers require to stay
/// visible. Tapping it opens OpenStreetMap's page for reporting map
/// problems, the "fix the map" link the routing service asks for.
class MapAttribution extends StatelessWidget {
  const MapAttribution({super.key, required this.text});

  static final fixTheMap = Uri.parse('https://www.openstreetmap.org/fixthemap');

  final String text;

  @override
  Widget build(BuildContext context) {
    final color = context.colors.textSecondary;
    return Semantics(
      link: true,
      label: '$text. Report a map problem',
      child: GestureDetector(
        onTap: () => launchUrl(fixTheMap, mode: LaunchMode.externalApplication),
        child: Glass(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          opacity: 0.75,
          blur: 8,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(text, style: TextStyle(fontSize: 10.5, color: color)),
              const SizedBox(width: 3),
              Icon(Icons.open_in_new_rounded, size: 11, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

/// Explains why distances are missing and offers the fix. Shows nothing
/// once the location is known.
class LocationBanner extends StatelessWidget {
  const LocationBanner({
    super.key,
    required this.state,
    required this.onAction,
  });

  final LocationState state;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (
      IconData icon,
      String title,
      String? action,
    ) = switch (state.status) {
      LocationStatus.idle || LocationStatus.ready => (Icons.check, '', null),
      LocationStatus.locating => (
        Icons.my_location_rounded,
        'Finding your location…',
        null,
      ),
      LocationStatus.serviceDisabled => (
        Icons.location_disabled_rounded,
        'Location is turned off',
        'Turn on',
      ),
      LocationStatus.denied => (
        Icons.location_off_rounded,
        'Allow location to see distances',
        'Allow',
      ),
      LocationStatus.deniedForever => (
        Icons.location_off_rounded,
        'Location is blocked for TripC',
        'Settings',
      ),
      LocationStatus.unavailable => (
        Icons.gps_off_rounded,
        "Can't find your location",
        'Retry',
      ),
    };
    if (title.isEmpty || state.hasPosition) return const SizedBox.shrink();

    return Glass(
      borderRadius: BorderRadius.circular(AppRadius.md),
      opacity: 0.88,
      padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
      child: Row(
        children: [
          if (action == null)
            SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colors.brand,
              ),
            )
          else
            Icon(icon, size: 20, color: colors.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                title,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (action != null)
            TextButton(onPressed: onAction, child: Text(action)),
        ],
      ),
    );
  }
}
