import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/glass.dart';
import '../../map/data/trip_estimate.dart';
import '../../map/widgets/category_badge.dart';
import '../recommendation/recommender.dart';

/// The main reason for a pick, or a pointer to its score breakdown.
String _mainReason(Recommendation pick) => pick.reasons.isNotEmpty
    ? pick.reasons.first
    : 'See why it scored ${pick.matchPercent}%';

/// A large card for one of the top picks, with its match and main reason.
/// Tapping the match explains the score; tapping elsewhere opens the place.
class TopPickCard extends StatelessWidget {
  const TopPickCard({
    super.key,
    required this.pick,
    required this.onTap,
    required this.onExplain,
  });

  final Recommendation pick;
  final VoidCallback onTap;
  final VoidCallback onExplain;

  @override
  Widget build(BuildContext context) {
    final place = pick.place;
    final color = place.category.color;
    final reason = _mainReason(pick);
    const radius = BorderRadius.all(Radius.circular(AppRadius.lg));

    return Semantics(
      button: true,
      label: '${place.name}, ${pick.matchPercent}% match',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 268,
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: AppShadows.soft(context.colors),
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Category artwork until places have photos.
                DecoratedBox(
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
                ),
                Positioned(
                  right: -24,
                  top: 36,
                  child: Icon(
                    place.category.icon,
                    size: 190,
                    color: Colors.white.withValues(alpha: 0.16),
                  ),
                ),
                Positioned(
                  top: 14,
                  left: 14,
                  right: 14,
                  // Both chips may shrink, so long labels or large text
                  // truncate instead of overflowing.
                  child: Row(
                    children: [
                      Flexible(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Semantics(
                            button: true,
                            label: 'Why this pick?',
                            child: GestureDetector(
                              onTap: onExplain,
                              child: GlassChip(
                                icon: Icons.auto_awesome,
                                iconColor: AppPalette.champagne200,
                                label: '${pick.matchPercent}% match · Why?',
                                onImage: true,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (pick.roadMeters case final meters?) ...[
                        const SizedBox(width: AppSpace.sm),
                        Flexible(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: GlassChip(
                              icon: Icons.directions_car_rounded,
                              label: formatDistance(meters),
                              onImage: true,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Positioned(
                  left: 10,
                  right: 10,
                  bottom: 10,
                  child: Glass(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    tint: AppPalette.charcoal900,
                    opacity: 0.5,
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          reason,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppPalette.champagne200,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          place.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            height: 1.15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          [
                            place.district,
                            place.category.label,
                          ].where((s) => s.isNotEmpty).join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        if (pick.cautions.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          _Caution(text: pick.cautions.first, onImage: true),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A recommendation as a list row: thumbnail, name, place, key facts and
/// the main reason. Tapping the match explains the score; tapping elsewhere
/// opens the place.
class PickRow extends StatelessWidget {
  const PickRow({
    super.key,
    required this.pick,
    required this.onTap,
    required this.onExplain,
  });

  final Recommendation pick;
  final VoidCallback onTap;
  final VoidCallback onExplain;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final place = pick.place;
    final rating = place.rating;
    final meters = pick.roadMeters;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            CategoryBadge(category: place.category, size: 68),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    place.district.isEmpty
                        ? 'Sri Lanka'
                        : '${place.district}, Sri Lanka',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text.rich(
                    TextSpan(
                      children: [
                        if (rating != null) ...[
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Icon(
                              Icons.star_rounded,
                              size: 15,
                              color: colors.accent,
                            ),
                          ),
                          TextSpan(text: ' ${rating.toStringAsFixed(1)} · '),
                        ],
                        TextSpan(text: place.category.label),
                        if (meters != null)
                          TextSpan(text: ' · ${formatDistance(meters)}'),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _mainReason(pick),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.brand,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (pick.cautions.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    _Caution(text: pick.cautions.first),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpace.md),
            MatchBadge(percent: pick.matchPercent, onTap: onExplain),
          ],
        ),
      ),
    );
  }
}

/// The overall match, e.g. "84%". Tapping it explains the score.
class MatchBadge extends StatelessWidget {
  const MatchBadge({super.key, required this.percent, required this.onTap});

  final int percent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Tooltip(
      message: 'Why this pick?',
      child: Material(
        color: colors.accentSoft,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          onTap: onTap,
          child: SizedBox(
            width: 58,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                children: [
                  Text(
                    '$percent%',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Why?',
                    style: TextStyle(
                      color: colors.brand,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Caution extends StatelessWidget {
  const _Caution({required this.text, this.onImage = false});

  final String text;
  final bool onImage;

  @override
  Widget build(BuildContext context) {
    final color = onImage ? AppPalette.coralLight : context.colors.danger;
    return Row(
      children: [
        Icon(Icons.info_outline_rounded, size: 13, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
