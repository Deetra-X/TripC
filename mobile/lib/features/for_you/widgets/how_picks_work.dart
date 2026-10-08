import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/theme_context.dart';
import '../context/weather_service.dart';
import '../recommendation/recommender.dart';

/// Explains how picks are ranked, so recommendations aren't a black box.
class HowPicksWork extends StatelessWidget {
  const HowPicksWork({super.key, this.weights = const RecommendationWeights()});

  final RecommendationWeights weights;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    String percent(double weight) => '${(weight * 100).round()}%';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceRaised,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: colors.hairline),
        ),
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          leading: Icon(Icons.tune_rounded, color: colors.brand),
          title: Text(
            'How your picks are chosen',
            style: context.text.titleSmall,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Part(
              weight: percent(weights.interest),
              title: 'Your interests',
              detail: "How closely a place's tags match what you love.",
            ),
            _Part(
              weight: percent(weights.quality),
              title: 'Quality',
              detail: 'Its rating, adjusted for how many reviews it has.',
            ),
            _Part(
              weight: percent(weights.proximity),
              title: 'Distance',
              detail: 'How far it is by road from where you are.',
            ),
            _Part(
              weight: percent(weights.context),
              title: 'Right now',
              detail: 'Opening hours, the weather and the time of day.',
            ),
            const SizedBox(height: AppSpace.sm),
            Text(
              'Road distances: OSRM with OpenStreetMap data. '
              '${OpenMeteoWeatherService.attribution}.',
              style: TextStyle(color: colors.textTertiary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _Part extends StatelessWidget {
  const _Part({
    required this.weight,
    required this.title,
    required this.detail,
  });

  final String weight;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 48,
            child: Text(
              weight,
              style: TextStyle(
                color: colors.brand,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$title. ',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: detail),
                ],
              ),
              style: TextStyle(color: colors.textSecondary, fontSize: 13.5),
            ),
          ),
        ],
      ),
    );
  }
}
