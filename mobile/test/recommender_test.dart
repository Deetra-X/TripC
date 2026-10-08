import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:tripc/features/for_you/context/weather_service.dart';
import 'package:tripc/features/for_you/recommendation/recommender.dart';
import 'package:tripc/features/map/data/attraction.dart';

const _here = LatLng(7.29, 80.64);
final _noon = DateTime(2026, 10, 8, 12);
final _evening = DateTime(2026, 10, 8, 19);

Attraction _place(
  String id, {
  AttractionCategory category = AttractionCategory.other,
  Set<InterestTag> tags = const {},
  double? ratingScore,
  double? rating,
  bool? rainSensitive,
  String? indoorOutdoor,
  String? openTime,
  String? closeTime,
  bool hiddenGem = false,
}) {
  return Attraction(
    id: id,
    name: 'Place $id',
    category: category,
    location: _here,
    tags: tags,
    ratingScore: ratingScore,
    rating: rating,
    rainSensitive: rainSensitive,
    indoorOutdoor: indoorOutdoor,
    openTime: openTime,
    closeTime: closeTime,
    hiddenGem: hiddenGem,
  );
}

List<String> _ids(List<Recommendation> ranked) => [
  for (final pick in ranked) pick.place.id,
];

void main() {
  const recommender = Recommender();

  group('interest match', () {
    test('is the cosine similarity of the tag sets', () {
      expect(
        Recommender.cosineSimilarity(
          {InterestTag.nature, InterestTag.hiking},
          {InterestTag.nature},
        ),
        closeTo(1 / math.sqrt(2), 1e-9),
      );
      expect(
        Recommender.cosineSimilarity({InterestTag.beach}, {InterestTag.beach}),
        1,
      );
      expect(
        Recommender.cosineSimilarity({InterestTag.beach}, {InterestTag.hiking}),
        0,
      );
      expect(Recommender.cosineSimilarity({}, {InterestTag.hiking}), 0);
    });

    test('puts places matching the interests first, and says why', () {
      final ranked = recommender.rank(
        [
          _place('temple', tags: {InterestTag.religious}),
          _place('beach', tags: {InterestTag.beach, InterestTag.nature}),
        ],
        {InterestTag.beach},
        RecommendationContext(now: _noon),
      );

      expect(_ids(ranked), ['beach', 'temple']);
      expect(ranked.first.reasons.first, 'Because you like beaches');
      expect(ranked.last.reasons, isEmpty);
    });
  });

  test('the score is the weighted sum of its parts', () {
    final pick = recommender
        .rank(
          [
            _place('a', tags: {InterestTag.beach}, ratingScore: 0.8),
          ],
          {InterestTag.beach},
          RecommendationContext(now: _noon, position: _here),
        )
        .single;

    const w = RecommendationWeights();
    expect(pick.interestMatch, 1);
    expect(pick.quality, 0.8);
    expect(pick.proximity, closeTo(1, 1e-9));
    expect(pick.context, 0.5);
    expect(
      pick.score,
      closeTo(
        w.interest * 1 + w.quality * 0.8 + w.proximity * 1 + w.context * 0.5,
        1e-9,
      ),
    );
    expect(pick.matchPercent, (pick.score * 100).round());
  });

  test('unrated places count as average quality', () {
    final ranked = recommender.rank(
      [
        _place('low', ratingScore: 0.2),
        _place('unrated'),
        _place('high', ratingScore: 0.9),
      ],
      {},
      RecommendationContext(now: _noon),
    );

    expect(_ids(ranked), ['high', 'unrated', 'low']);
    expect(ranked[1].quality, Recommender.unratedQuality);
  });

  test('nearer places by road score higher; only road distances are shown', () {
    final ranked = recommender.rank(
      [_place('far'), _place('near'), _place('unknown')],
      {},
      RecommendationContext(
        now: _noon,
        position: _here,
        roadMeters: const {'far': 120000, 'near': 12000},
      ),
    );

    final byId = {for (final pick in ranked) pick.place.id: pick};
    expect(byId['near']!.proximity, greaterThan(byId['far']!.proximity));
    expect(byId['near']!.reasons, contains('12 km away'));
    expect(byId['far']!.reasons.any((r) => r.endsWith('away')), isFalse);
    // No road distance, so its straight-line distance ranks it but isn't
    // shown.
    expect(byId['unknown']!.roadMeters, isNull);
    expect(byId['unknown']!.reasons, isEmpty);
  });

  group('context', () {
    test('a closed place is pushed down and flagged', () {
      final ranked = recommender.rank(
        [
          _place('closed', openTime: '14:00', closeTime: '18:00'),
          _place('open', openTime: '08:00', closeTime: '17:00'),
        ],
        {},
        RecommendationContext(now: _noon),
      );

      expect(_ids(ranked), ['open', 'closed']);
      expect(ranked.first.reasons, contains('Open now'));
      expect(ranked.last.cautions, ['Closed now · opens 14:00']);
    });

    test('opening hours can run past midnight', () {
      final club = _place('club', openTime: '20:00', closeTime: '02:00');
      expect(Recommender.isOpenAt(club, DateTime(2026, 1, 1, 23)), isTrue);
      expect(Recommender.isOpenAt(club, DateTime(2026, 1, 1, 1)), isTrue);
      expect(Recommender.isOpenAt(club, DateTime(2026, 1, 1, 12)), isFalse);
      expect(Recommender.isOpenAt(_place('x'), _noon), isNull);
    });

    test('rain favours indoor places over rain-sensitive ones', () {
      final ranked = recommender.rank(
        [
          _place('falls', rainSensitive: true, indoorOutdoor: 'outdoor'),
          _place('museum', indoorOutdoor: 'indoor'),
        ],
        {},
        RecommendationContext(
          now: _noon,
          position: _here,
          weather: const Weather(temperature: 24, kind: WeatherKind.rain),
        ),
      );

      expect(_ids(ranked), ['museum', 'falls']);
      expect(ranked.first.reasons, contains('Good on a rainy day'));
      expect(ranked.last.cautions, ['Rain now · best on dry days']);
    });

    test('fine weather favours outdoor places', () {
      final pick = recommender
          .rank(
            [_place('falls', rainSensitive: true, indoorOutdoor: 'outdoor')],
            {},
            RecommendationContext(
              now: _noon,
              position: _here,
              weather: const Weather(temperature: 29, kind: WeatherKind.clear),
            ),
          )
          .single;

      expect(pick.context, greaterThan(0.5));
      expect(pick.reasons, contains('Good weather for it'));
    });

    test("the user's weather doesn't count for places far away", () {
      const far = Attraction(
        id: 'far',
        name: 'Far falls',
        category: AttractionCategory.waterfalls,
        location: LatLng(6.0, 80.2),
        rainSensitive: true,
      );
      final pick = recommender
          .rank(
            [far],
            {},
            RecommendationContext(
              now: _noon,
              position: _here,
              weather: const Weather(temperature: 24, kind: WeatherKind.rain),
            ),
          )
          .single;

      expect(pick.context, 0.5);
      expect(pick.cautions, isEmpty);
    });

    test('nightlife ranks higher in the evening', () {
      final bar = _place('bar', category: AttractionCategory.nightlife);
      final atNoon = recommender
          .rank([bar], {}, RecommendationContext(now: _noon))
          .single;
      final atNight = recommender
          .rank([bar], {}, RecommendationContext(now: _evening))
          .single;

      expect(atNight.score, greaterThan(atNoon.score));
      expect(atNight.reasons, contains('Good for tonight'));
    });
  });

  test('hidden gems and top ratings are named as reasons', () {
    final pick = recommender
        .rank(
          [_place('gem', hiddenGem: true, rating: 4.6)],
          {},
          RecommendationContext(now: _noon),
        )
        .single;

    expect(pick.reasons, containsAll(['Hidden gem', 'Rated 4.6']));
  });

  test('ratings of 4 or more are a reason, with the review count', () {
    final ranked = recommender.rank(
      [
        const Attraction(
          id: 'falls',
          name: 'Falls',
          category: AttractionCategory.waterfalls,
          rating: 4.4,
          reviewCount: 1524,
        ),
        _place('meh', rating: 3.8),
      ],
      {},
      RecommendationContext(now: _noon),
    );

    final byId = {for (final pick in ranked) pick.place.id: pick};
    expect(byId['falls']!.reasons, ['Rated 4.4 by 1,524 visitors']);
    expect(byId['meh']!.reasons, isEmpty);
  });

  test('picks keep what is needed to explain them', () {
    const weights = RecommendationWeights(
      interest: 0.5,
      quality: 0.2,
      proximity: 0.2,
      context: 0.1,
    );
    final pick = const Recommender(weights: weights)
        .rank(
          [
            _place('a', tags: {InterestTag.beach, InterestTag.nature}),
          ],
          {InterestTag.beach, InterestTag.hiking},
          RecommendationContext(now: _noon),
        )
        .single;

    expect(pick.weights, same(weights));
    expect(pick.sharedInterests, {InterestTag.beach});
    // The parts, weighted, add up to the score.
    expect(
      pick.score,
      closeTo(
        0.5 * pick.interestMatch +
            0.2 * pick.quality +
            0.2 * pick.proximity +
            0.1 * pick.context,
        1e-9,
      ),
    );
  });

  test('top picks take at most two from each category', () {
    final ranked = recommender.rank(
      [
        for (var i = 0; i < 4; i++)
          _place(
            'temple$i',
            category: AttractionCategory.religious,
            ratingScore: 0.9,
          ),
        _place('beach', category: AttractionCategory.beaches, ratingScore: 0.1),
        _place('falls', category: AttractionCategory.waterfalls),
      ],
      {},
      RecommendationContext(now: _noon),
    );

    final top = Recommender.diversify(ranked, count: 4);
    expect(
      top.where((p) => p.place.category == AttractionCategory.religious),
      hasLength(2),
    );
    expect(_ids(top), containsAll(['beach', 'falls']));

    // With too few categories it tops the list up in rank order.
    expect(Recommender.diversify(ranked, count: 6), hasLength(6));
  });

  test('day parts follow the clock', () {
    expect(DayPart.at(DateTime(2026, 1, 1, 6)), DayPart.morning);
    expect(DayPart.at(DateTime(2026, 1, 1, 13)), DayPart.afternoon);
    expect(DayPart.at(DateTime(2026, 1, 1, 18)), DayPart.evening);
    expect(DayPart.at(DateTime(2026, 1, 1, 23)), DayPart.night);
  });
}
