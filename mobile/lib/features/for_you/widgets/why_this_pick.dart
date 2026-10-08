import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/theme_context.dart';
import '../../map/data/trip_estimate.dart';
import '../../map/widgets/category_badge.dart';
import '../recommendation/recommender.dart';

/// Shows how [pick]'s match was calculated: each part of the hybrid score
/// with its value, weight and contribution, then the reasons and cautions.
Future<void> showWhyThisPick(
  BuildContext context, {
  required Recommendation pick,
  required bool hasInterests,
  required bool hasLocation,
  required VoidCallback onShowOnMap,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.colors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (sheetContext) => _WhyThisPick(
      pick: pick,
      hasInterests: hasInterests,
      hasLocation: hasLocation,
      onShowOnMap: () {
        Navigator.of(sheetContext).pop();
        onShowOnMap();
      },
    ),
  );
}

class _WhyThisPick extends StatelessWidget {
  const _WhyThisPick({
    required this.pick,
    required this.hasInterests,
    required this.hasLocation,
    required this.onShowOnMap,
  });

  final Recommendation pick;
  final bool hasInterests;
  final bool hasLocation;
  final VoidCallback onShowOnMap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final place = pick.place;
    final weights = pick.weights;
    final rating = place.rating;
    final reviews = place.reviewCount;
    final roadMeters = pick.roadMeters;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpace.xxl,
        AppSpace.md,
        AppSpace.xxl,
        AppSpace.xxl + MediaQuery.viewPaddingOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpace.xl),
              decoration: BoxDecoration(
                color: colors.hairline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              CategoryBadge(category: place.category, size: 48),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.titleLarge,
                    ),
                    Text(
                      [
                        place.district,
                        place.category.label,
                      ].where((s) => s.isNotEmpty).join(' · '),
                      style: context.text.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.xl),
          Text('Why this pick?', style: context.text.titleMedium),
          const SizedBox(height: AppSpace.xs),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${pick.matchPercent}% match',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const TextSpan(
                  text:
                      ', the sum of the four parts below. Each part is '
                      'scored from 0 to 100% and multiplied by its weight.',
                ),
              ],
            ),
            style: TextStyle(color: colors.textSecondary, fontSize: 13.5),
          ),
          const SizedBox(height: AppSpace.lg),
          _Part(
            title: 'Your interests',
            value: pick.interestMatch,
            weight: weights.interest,
            detail: !hasInterests
                ? "You haven't chosen interests yet."
                : pick.sharedInterests.isEmpty
                ? 'Shares none of your interests.'
                : 'Shares ${pick.sharedInterests.map((t) => t.label).join(', ')} '
                      'with your interests (cosine similarity of the tags).',
          ),
          _Part(
            title: 'Quality',
            value: pick.quality,
            weight: weights.quality,
            detail: rating == null
                ? 'Not rated yet, so counted as average.'
                : 'Rated ${rating.toStringAsFixed(1)}'
                      '${reviews == null ? '' : ' by ${Recommender.thousands(reviews)} visitors'}'
                      ', adjusted for the number of reviews.',
          ),
          _Part(
            title: 'Distance',
            value: pick.proximity,
            weight: weights.proximity,
            detail: roadMeters != null
                ? '${formatDistance(roadMeters)} away by road. Nearer '
                      'places score higher.'
                : hasLocation
                ? 'Road distance not known yet, so the straight-line '
                      'distance is used.'
                : 'Your location is off, so distance counts as average.',
          ),
          _Part(
            title: 'Right now',
            value: pick.context,
            weight: weights.context,
            detail:
                'Opening hours, the weather near you and the time of day. '
                '50% means nothing in particular for or against it.',
          ),
          if (pick.reasons.isNotEmpty || pick.cautions.isNotEmpty) ...[
            const SizedBox(height: AppSpace.sm),
            for (final reason in pick.reasons)
              _Note(icon: Icons.check_circle_rounded, text: reason),
            for (final caution in pick.cautions)
              _Note(
                icon: Icons.error_outline_rounded,
                text: caution,
                warning: true,
              ),
          ],
          const SizedBox(height: AppSpace.xl),
          FilledButton.icon(
            onPressed: onShowOnMap,
            icon: const Icon(Icons.route_rounded),
            label: const Text('Show on map'),
          ),
        ],
      ),
    );
  }
}

class _Part extends StatelessWidget {
  const _Part({
    required this.title,
    required this.value,
    required this.weight,
    required this.detail,
  });

  final String title;

  /// From 0 to 1.
  final double value;
  final double weight;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final points = (value * weight * 100).toStringAsFixed(1);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: context.text.titleSmall)),
              Text(
                '${(value * 100).round()}% × ${(weight * 100).round()}% '
                '= $points',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value.clamp(0.0, 1.0),
              minHeight: 6,
              color: colors.brand,
              backgroundColor: colors.hairline,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            detail,
            style: TextStyle(color: colors.textSecondary, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.text, this.warning = false});

  final IconData icon;
  final String text;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = warning ? colors.danger : colors.brand;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: colors.textPrimary, fontSize: 13.5),
            ),
          ),
        ],
      ),
    );
  }
}
