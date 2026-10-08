import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import 'widgets/place_art.dart';

// Sample content for the Discover screen until the recommender and a places
// API are connected.

enum PlaceCategory {
  culture('Culture', ArtStyle.sunset),
  beaches('Beaches', ArtStyle.coast),
  nature('Nature', ArtStyle.highlands),
  wildlife('Wildlife', ArtStyle.forest);

  const PlaceCategory(this.label, this.art);

  final String label;
  final ArtStyle art;
}

class Recommendation {
  const Recommendation({
    required this.name,
    required this.region,
    required this.travelTime,
    required this.rating,
    required this.match,
    required this.reason,
    required this.category,
    required this.art,
  });

  final String name;
  final String region;
  final String travelTime;
  final double rating;
  final int match;
  final String reason;
  final PlaceCategory category;
  final ArtStyle art;
}

class NearbyPlace {
  const NearbyPlace({
    required this.name,
    required this.kind,
    required this.distanceKm,
    required this.openLabel,
    required this.rating,
    required this.walkMinutes,
    required this.driveMinutes,
    required this.pinColor,
    required this.mapPosition,
    required this.art,
  });

  final String name;
  final String kind;
  final double distanceKm;
  final String openLabel;
  final double rating;
  final int walkMinutes;
  final int driveMinutes;
  final Color pinColor;

  /// Where the pin sits on the map preview, as fractions of its size.
  final Offset mapPosition;
  final ArtStyle art;
}

class PopularPlace {
  const PopularPlace({
    required this.name,
    required this.region,
    required this.rating,
    required this.art,
  });

  final String name;
  final String region;
  final double rating;
  final ArtStyle art;
}

const recommendations = [
  Recommendation(
    name: 'Sigiriya',
    region: 'Matale',
    travelTime: '2 h away',
    rating: 4.8,
    match: 96,
    reason: 'Because you like ancient history',
    category: PlaceCategory.culture,
    art: ArtStyle.sigiriya,
  ),
  Recommendation(
    name: 'Mirissa Beach',
    region: 'Matara',
    travelTime: '4 h away',
    rating: 4.7,
    match: 91,
    reason: 'Because you like quiet beaches',
    category: PlaceCategory.beaches,
    art: ArtStyle.coast,
  ),
  Recommendation(
    name: 'Horton Plains',
    region: 'Nuwara Eliya',
    travelTime: '3 h away',
    rating: 4.7,
    match: 89,
    reason: 'Clear skies there this morning',
    category: PlaceCategory.nature,
    art: ArtStyle.highlands,
  ),
  Recommendation(
    name: 'Dambulla Cave Temple',
    region: 'Matale',
    travelTime: '1.5 h away',
    rating: 4.7,
    match: 88,
    reason: 'Because you like ancient history',
    category: PlaceCategory.culture,
    art: ArtStyle.sunset,
  ),
  Recommendation(
    name: 'Yala National Park',
    region: 'Hambantota',
    travelTime: '5 h away',
    rating: 4.6,
    match: 84,
    reason: 'Leopard sightings are high this month',
    category: PlaceCategory.wildlife,
    art: ArtStyle.forest,
  ),
];

const nearbyPlaces = [
  NearbyPlace(
    name: 'Kandy Lake',
    kind: 'Scenic',
    distanceKm: 0.4,
    openLabel: 'Open 24h',
    rating: 4.6,
    walkMinutes: 5,
    driveMinutes: 2,
    pinColor: AppPalette.teal700,
    mapPosition: Offset(0.55, 0.5),
    art: ArtStyle.coast,
  ),
  NearbyPlace(
    name: 'Temple of the Sacred Tooth Relic',
    kind: 'Culture',
    distanceKm: 0.6,
    openLabel: 'Open now',
    rating: 4.8,
    walkMinutes: 8,
    driveMinutes: 3,
    pinColor: AppPalette.coral,
    mapPosition: Offset(0.66, 0.4),
    art: ArtStyle.sunset,
  ),
  NearbyPlace(
    name: 'Udawatta Kele Sanctuary',
    kind: 'Nature',
    distanceKm: 1.2,
    openLabel: 'Open now',
    rating: 4.4,
    walkMinutes: 15,
    driveMinutes: 6,
    pinColor: AppPalette.teal600,
    mapPosition: Offset(0.74, 0.2),
    art: ArtStyle.forest,
  ),
  NearbyPlace(
    name: 'Bahirawakanda Temple',
    kind: 'Viewpoint',
    distanceKm: 1.8,
    openLabel: 'Open now',
    rating: 4.5,
    walkMinutes: 24,
    driveMinutes: 8,
    pinColor: Color(0xFFE08A2C),
    mapPosition: Offset(0.27, 0.52),
    art: ArtStyle.dusk,
  ),
  NearbyPlace(
    name: 'Royal Botanic Gardens',
    kind: 'Nature',
    distanceKm: 6.2,
    openLabel: 'Till 5 pm',
    rating: 4.7,
    walkMinutes: 75,
    driveMinutes: 18,
    pinColor: Color(0xFF2F5D9E),
    mapPosition: Offset(0.15, 0.82),
    art: ArtStyle.highlands,
  ),
];

const popularPlaces = [
  PopularPlace(
    name: 'Nine Arches Bridge',
    region: 'Ella',
    rating: 4.8,
    art: ArtStyle.highlands,
  ),
  PopularPlace(
    name: 'Galle Fort',
    region: 'Galle',
    rating: 4.7,
    art: ArtStyle.coast,
  ),
  PopularPlace(
    name: 'Ritigala Monastery',
    region: 'Anuradhapura',
    rating: 4.6,
    art: ArtStyle.forest,
  ),
  PopularPlace(
    name: "Adam's Peak",
    region: 'Nuwara Eliya',
    rating: 4.8,
    art: ArtStyle.dusk,
  ),
  PopularPlace(
    name: 'Pidurangala Rock',
    region: 'Matale',
    rating: 4.7,
    art: ArtStyle.sunset,
  ),
];
