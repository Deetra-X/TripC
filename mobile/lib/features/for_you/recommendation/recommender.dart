import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import '../../map/data/attraction.dart';
import '../../map/data/trip_estimate.dart';
import '../context/weather_service.dart';

/// How much each part of the hybrid score counts; they add up to 1. These
/// are starting values to tune and evaluate, not final research results.
class RecommendationWeights {
  const RecommendationWeights({
    this.interest = 0.40,
    this.quality = 0.25,
    this.proximity = 0.20,
    this.context = 0.15,
  });

  /// Cosine similarity between the user's interests and the place's tags.
  final double interest;

  /// The place's rating_score_0_1.
  final double quality;

  /// How close the place is, by road where known.
  final double proximity;

  /// Opening hours, weather and time of day.
  final double context;
}

enum DayPart {
  morning('Morning'),
  afternoon('Afternoon'),
  evening('Evening'),
  night('Night');

  const DayPart(this.label);

  final String label;

  static DayPart at(DateTime time) => switch (time.hour) {
    >= 5 && < 12 => morning,
    >= 12 && < 17 => afternoon,
    >= 17 && < 21 => evening,
    _ => night,
  };
}

/// What's true right now: where the user is, the time and the weather.
class RecommendationContext {
  const RecommendationContext({
    required this.now,
    this.position,
    this.roadMeters = const {},
    this.weather,
  });

  final DateTime now;
  final LatLng? position;

  /// Road distances from the user, by place id, where known.
  final Map<String, double> roadMeters;
  final Weather? weather;
}

class Recommendation {
  const Recommendation({
    required this.place,
    required this.weights,
    required this.score,
    required this.interestMatch,
    required this.quality,
    required this.proximity,
    required this.context,
    required this.reasons,
    required this.cautions,
    this.sharedInterests = const {},
    this.roadMeters,
  });

  final Attraction place;

  /// The weights the score was calculated with.
  final RecommendationWeights weights;

  /// The weighted hybrid score, from 0 to 1.
  final double score;

  // The parts of the score, each from 0 to 1, kept for explanations and
  // evaluation.
  final double interestMatch;
  final double quality;
  final double proximity;
  final double context;

  /// The user's interests that this place's tags share.
  final Set<InterestTag> sharedInterests;

  /// Why the place suits the user, most important first.
  final List<String> reasons;

  /// Things that count against it right now, e.g. "Closed now".
  final List<String> cautions;

  /// Distance by road, if known.
  final double? roadMeters;

  int get matchPercent => (score * 100).round();
}

/// Ranks places with a weighted hybrid of content-based filtering (interest
/// tags), quality (Bayesian rating), proximity and live context.
class Recommender {
  const Recommender({this.weights = const RecommendationWeights()});

  /// Distance at which the proximity score falls to about 37% (1/e).
  static const proximityScaleKm = 60.0;

  /// Quality for places without a rating yet: the middle of the scale.
  static const unratedQuality = 0.5;

  /// The weather where the user is only counts for places this close; the
  /// weather further away can be quite different.
  static const weatherRadiusKm = 25.0;

  final RecommendationWeights weights;

  List<Recommendation> rank(
    Iterable<Attraction> places,
    Set<InterestTag> interests,
    RecommendationContext context,
  ) {
    final ranked = [
      for (final place in places) _score(place, interests, context),
    ]..sort((a, b) => b.score.compareTo(a.score));
    return ranked;
  }

  /// Cosine similarity between two sets of tags treated as 0/1 vectors:
  /// shared tags divided by the geometric mean of their sizes.
  static double cosineSimilarity(Set<InterestTag> a, Set<InterestTag> b) {
    if (a.isEmpty || b.isEmpty) return 0;
    return a.intersection(b).length / math.sqrt(a.length * b.length);
  }

  /// Whether [place] is open at [time], or null if its hours aren't known.
  /// Handles hours that run past midnight, e.g. 20:00–02:00.
  static bool? isOpenAt(Attraction place, DateTime time) {
    final open = _minutes(place.openTime);
    final close = _minutes(place.closeTime);
    if (open == null || close == null) return null;
    final now = time.hour * 60 + time.minute;
    return open <= close
        ? now >= open && now < close
        : now >= open || now < close;
  }

  /// The best [count] picks with at most [perCategory] from any category,
  /// so the top of the list isn't all one kind of place.
  static List<Recommendation> diversify(
    List<Recommendation> ranked, {
    int count = 6,
    int perCategory = 2,
  }) {
    final picked = <Recommendation>[];
    final perCategoryCount = <AttractionCategory, int>{};
    for (final pick in ranked) {
      if (picked.length == count) break;
      final category = pick.place.category;
      if ((perCategoryCount[category] ?? 0) >= perCategory) continue;
      picked.add(pick);
      perCategoryCount.update(category, (n) => n + 1, ifAbsent: () => 1);
    }
    // Too few categories to fill the list: top it up in rank order.
    for (final pick in ranked) {
      if (picked.length == count) break;
      if (!picked.contains(pick)) picked.add(pick);
    }
    return picked;
  }

  Recommendation _score(
    Attraction place,
    Set<InterestTag> interests,
    RecommendationContext context,
  ) {
    final reasons = <String>[];
    final cautions = <String>[];

    final interest = cosineSimilarity(interests, place.tags);
    final shared = InterestTag.values.where(
      (tag) => interests.contains(tag) && place.tags.contains(tag),
    );
    if (shared.isNotEmpty) {
      reasons.add(
        'Because you like ${shared.take(2).map(_liking).join(' & ')}',
      );
    }

    final roadMeters = context.roadMeters[place.id];
    final position = context.position;
    final location = place.location;
    final meters =
        roadMeters ??
        (position != null && location != null
            ? TripEstimate.between(position, location).meters
            : null);
    final proximity = meters == null
        ? 0.5
        : math.exp(-meters / 1000 / proximityScaleKm);
    // Only road distances are shown; straight lines only help the ranking.
    if (roadMeters != null && roadMeters < 30000) {
      reasons.add('${formatDistance(roadMeters)} away');
    }

    final contextScore = _contextScore(
      place,
      context,
      reasons,
      cautions,
      nearby: meters != null && meters <= weatherRadiusKm * 1000,
    );

    final quality = place.ratingScore ?? unratedQuality;
    if (place.hiddenGem) reasons.add('Hidden gem');
    if (place.rating case final rating? when rating >= 4.0) {
      final reviews = place.reviewCount;
      reasons.add(
        reviews == null
            ? 'Rated ${rating.toStringAsFixed(1)}'
            : 'Rated ${rating.toStringAsFixed(1)} by '
                  '${thousands(reviews)} visitors',
      );
    }

    return Recommendation(
      place: place,
      weights: weights,
      score:
          weights.interest * interest +
          weights.quality * quality +
          weights.proximity * proximity +
          weights.context * contextScore,
      interestMatch: interest,
      quality: quality,
      proximity: proximity,
      context: contextScore,
      sharedInterests: shared.toSet(),
      reasons: reasons,
      cautions: cautions,
      roadMeters: roadMeters,
    );
  }

  /// 1524 → "1,524".
  static String thousands(int n) => n.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );

  /// Starts neutral at 0.5 and moves with opening hours, the weather (for
  /// [nearby] places only) and the time of day.
  double _contextScore(
    Attraction place,
    RecommendationContext context,
    List<String> reasons,
    List<String> cautions, {
    required bool nearby,
  }) {
    var score = 0.5;

    switch (isOpenAt(place, context.now)) {
      case true:
        score += 0.2;
        reasons.add('Open now');
      case false:
        score -= 0.4;
        cautions.add('Closed now · opens ${place.openTime}');
      case null:
        break;
    }

    if (context.weather case final weather? when nearby) {
      final outdoor =
          place.indoorOutdoor == 'outdoor' || place.rainSensitive == true;
      if (weather.isWet) {
        if (place.rainSensitive == true) {
          score -= 0.3;
          cautions.add('${weather.label} now · best on dry days');
        } else if (place.indoorOutdoor == 'indoor') {
          score += 0.25;
          reasons.add('Good on a rainy day');
        }
      } else if (weather.isDay && outdoor) {
        score += 0.15;
        reasons.add('Good weather for it');
      }
    }

    if (place.category == AttractionCategory.nightlife) {
      final part = DayPart.at(context.now);
      if (part == DayPart.evening || part == DayPart.night) {
        score += 0.2;
        reasons.add('Good for tonight');
      } else {
        score -= 0.1;
      }
    }

    return score.clamp(0.0, 1.0);
  }

  static String _liking(InterestTag tag) => switch (tag) {
    InterestTag.family => 'family outings',
    _ => tag.label.toLowerCase(),
  };

  static int? _minutes(String? time) {
    final match = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(time ?? '');
    if (match == null) return null;
    return int.parse(match[1]!) * 60 + int.parse(match[2]!);
  }
}
