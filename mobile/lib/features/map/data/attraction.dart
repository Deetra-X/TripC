import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

/// The categories used in the places table. Each is drawn on the map with
/// its own colour and icon, which stay the same in light and dark themes.
enum AttractionCategory {
  religious(
    'Religious Sites',
    'Religious',
    Icons.temple_buddhist,
    Color(0xFFB9853A),
  ),
  historical(
    'Historical Sites',
    'Historical',
    Icons.account_balance,
    Color(0xFF9C4A3A),
  ),
  wildlife('Wildlife & Nature', 'Wildlife', Icons.pets, Color(0xFFD2742A)),
  mountains(
    'Mountains & Viewpoints',
    'Mountains',
    Icons.landscape,
    Color(0xFF2E7D7A),
  ),
  waterfalls('Waterfalls', 'Waterfalls', Icons.water_drop, Color(0xFF2A9FBF)),
  beaches('Beaches', 'Beaches', Icons.beach_access, Color(0xFF2F80B7)),
  gardens('Gardens & Parks', 'Gardens', Icons.local_florist, Color(0xFF3E8E5E)),
  nightlife(
    'Nightlife (Clubs & Pubs)',
    'Nightlife',
    Icons.nightlife,
    Color(0xFF7B5EA7),
  ),
  other('Other', 'Other', Icons.place, Color(0xFF6B6F6B));

  const AttractionCategory(this.sourceName, this.label, this.icon, this.color);

  /// The name used in the places table, e.g. "Mountains & Viewpoints".
  final String sourceName;

  /// Short name for chips and lists, e.g. "Mountains".
  final String label;
  final IconData icon;
  final Color color;

  /// Matches a category from the table by its full or short name. Unknown
  /// names become [other].
  static AttractionCategory fromName(String? name) {
    final key = name?.trim().toLowerCase() ?? '';
    for (final category in values) {
      if (key == category.sourceName.toLowerCase() ||
          key == category.label.toLowerCase() ||
          key == category.name) {
        return category;
      }
    }
    return other;
  }
}

/// The 0/1 interest tags of the places table, used for cosine similarity.
enum InterestTag {
  nature('tag_nature', 'Nature', Icons.park),
  hiking('tag_hiking', 'Hiking', Icons.hiking),
  scenic('tag_scenic', 'Scenic views', Icons.landscape),
  cultureHistory(
    'tag_culture_history',
    'Culture & history',
    Icons.account_balance,
  ),
  religious('tag_religious', 'Religious sites', Icons.temple_buddhist),
  beach('tag_beach', 'Beaches', Icons.beach_access),
  wildlife('tag_wildlife', 'Wildlife', Icons.pets),
  nightlife('tag_nightlife', 'Nightlife', Icons.nightlife),
  family('tag_family', 'Family friendly', Icons.family_restroom);

  const InterestTag(this.column, this.label, this.icon);

  final String column;
  final String label;
  final IconData icon;
}

/// A row of the places table.
class Attraction {
  const Attraction({
    required this.id,
    required this.name,
    required this.category,
    this.location,
    this.district = '',
    this.province = '',
    this.description,
    this.rating,
    this.reviewCount,
    this.bayesianRating,
    this.ratingScore,
    this.hiddenGem = false,
    this.tags = const {},
    this.indoorOutdoor,
    this.rainSensitive,
    this.openTime,
    this.closeTime,
  });

  /// Reads a row using the table's column names, from Supabase or from
  /// places.json (see tool/export_places.py).
  factory Attraction.fromMap(Map<String, Object?> row) {
    final lat = _number(row['latitude']);
    final lng = _number(row['longitude']);
    return Attraction(
      id: '${row['place_id'] ?? row['place_name']}',
      name: _text(row['place_name']) ?? 'Unnamed place',
      category: AttractionCategory.fromName(_text(row['category'])),
      location: lat != null && lng != null ? LatLng(lat, lng) : null,
      district: _text(row['district']) ?? '',
      province: _text(row['province']) ?? '',
      description: _text(row['description']),
      rating: _number(row['avg_rating']),
      reviewCount: _number(row['review_count'])?.round(),
      bayesianRating: _number(row['bayesian_rating']),
      ratingScore: _number(row['rating_score_0_1']),
      hiddenGem: _flag(row['hidden_gem']) ?? false,
      tags: {
        for (final tag in InterestTag.values)
          if (_flag(row[tag.column]) ?? false) tag,
      },
      indoorOutdoor: _text(row['indoor_outdoor']),
      rainSensitive: _flag(row['rain_sensitive']),
      openTime: _text(row['open_time']),
      closeTime: _text(row['close_time']),
    );
  }

  final String id;
  final String name;
  final AttractionCategory category;

  /// Null until coordinates are collected; such places can't go on the map.
  final LatLng? location;
  final String district;
  final String province;
  final String? description;

  /// Star rating as collected, e.g. from Google Maps.
  final double? rating;
  final int? reviewCount;

  /// Rating adjusted for how many reviews it has.
  final double? bayesianRating;

  /// The Bayesian rating rescaled to 0–1, for the weighted hybrid score.
  final double? ratingScore;

  /// Fewer reviews than the trust threshold in the places table.
  final bool hiddenGem;
  final Set<InterestTag> tags;

  /// "indoor", "outdoor" or "mixed".
  final String? indoorOutdoor;

  /// Whether rain makes the visit unsafe or pointless.
  final bool? rainSensitive;

  /// 24-hour times such as "07:30".
  final String? openTime;
  final String? closeTime;

  /// Score for ranking: the Bayesian rating when known, since it is fairer
  /// to places with few reviews, otherwise the raw rating.
  double? get rankingScore => bayesianRating ?? rating;
}

String? _text(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

double? _number(Object? value) => switch (value) {
  num() => value.toDouble(),
  String() => double.tryParse(value.trim()),
  _ => null,
};

bool? _flag(Object? value) => switch (value) {
  bool() => value,
  num() => value != 0,
  String() => switch (value.trim().toLowerCase()) {
    '1' || 'y' || 'yes' || 'true' => true,
    '0' || 'n' || 'no' || 'false' => false,
    _ => null,
  },
  _ => null,
};
