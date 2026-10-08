import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:tripc/features/for_you/context/weather_service.dart';
import 'package:tripc/features/map/data/attraction.dart';
import 'package:tripc/features/map/data/attraction_repository.dart';
import 'package:tripc/features/map/data/trip_estimate.dart';
import 'package:tripc/features/map/location/location_service.dart';
import 'package:tripc/features/map/map_dependencies.dart';
import 'package:tripc/features/map/routing/route_service.dart';

/// The Temple of the Sacred Tooth Relic, Kandy.
const kandy = LatLng(7.2936, 80.6413);

/// A small, fixed set of places so tests don't depend on the spreadsheet.
/// Nallur Kovil (id 2) has no neighbouring markers at island zoom, so taps
/// on it can't land on another place.
const testPlaces = [
  Attraction(
    id: '1',
    name: 'Temple of the Sacred Tooth Relic',
    category: AttractionCategory.religious,
    location: kandy,
    district: 'Kandy',
    rating: 4.8,
    reviewCount: 41250,
    bayesianRating: 4.79,
    ratingScore: 0.9,
    tags: {InterestTag.religious, InterestTag.cultureHistory},
  ),
  Attraction(
    id: '2',
    name: 'Nallur Kandaswamy Kovil',
    category: AttractionCategory.religious,
    location: LatLng(9.6747, 80.0296),
    district: 'Jaffna',
    rating: 4.8,
    tags: {InterestTag.religious, InterestTag.cultureHistory},
  ),
  Attraction(
    id: '3',
    name: 'Sigiriya',
    category: AttractionCategory.historical,
    location: LatLng(7.9570, 80.7603),
    district: 'Matale',
    rating: 4.7,
    ratingScore: 0.8,
    tags: {InterestTag.cultureHistory, InterestTag.hiking, InterestTag.scenic},
  ),
  Attraction(
    id: '4',
    name: 'Mirissa Beach',
    category: AttractionCategory.beaches,
    location: LatLng(5.9449, 80.4590),
    district: 'Matara',
    indoorOutdoor: 'outdoor',
    rainSensitive: true,
    tags: {InterestTag.beach, InterestTag.nature},
  ),
  Attraction(
    id: '5',
    name: 'Arugam Bay',
    category: AttractionCategory.beaches,
    location: LatLng(6.8410, 81.8370),
    district: 'Ampara',
    tags: {InterestTag.beach},
  ),
  Attraction(
    id: '6',
    name: 'Kumari Ella',
    category: AttractionCategory.waterfalls,
    location: LatLng(6.9130, 80.1842),
    district: 'Colombo',
    description: 'A small waterfall near Colombo that feeds the Kelani River.',
    rating: 4.4,
    reviewCount: 1524,
    hiddenGem: true,
    indoorOutdoor: 'outdoor',
    rainSensitive: true,
    openTime: '07:30',
    closeTime: '18:00',
    tags: {InterestTag.nature, InterestTag.family},
  ),
  Attraction(
    id: '7',
    name: 'Riverside Garden',
    category: AttractionCategory.gardens,
    district: 'Galle',
    tags: {InterestTag.nature, InterestTag.family},
  ),
];

const sunny = Weather(temperature: 28, kind: WeatherKind.clear);

/// Weather without a network.
class FakeWeatherService implements WeatherService {
  FakeWeatherService([this.weather = sunny]);

  Weather weather;
  bool fail = false;

  @override
  Future<Weather> current(LatLng at) async {
    if (fail) throw StateError('offline');
    return weather;
  }
}

/// [testPlaces] that can go on the map.
final mappedTestPlaces = testPlaces.where((p) => p.location != null).toList();

/// Location service that reports [state] when started, without GPS.
class FakeLocationService extends LocationService {
  FakeLocationService(this.state);

  LocationState state;
  int starts = 0;
  int settingsOpened = 0;

  @override
  Future<void> start() async {
    starts++;
    value = state;
  }

  @override
  Future<void> openSettings() async => settingsOpened++;
}

class FakeAttractions implements AttractionRepository {
  FakeAttractions({this.fail = false});

  bool fail;

  @override
  Future<List<Attraction>> fetchAll() async {
    if (fail) throw StateError('offline');
    return testPlaces;
  }
}

/// Transparent tiles, so tests never touch the network.
class BlankTileProvider extends TileProvider {
  BlankTileProvider();

  static final _png = Uint8List.fromList([
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, //
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, //
    0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, //
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, //
    0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82, //
  ]);

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      MemoryImage(_png);
}

/// Map dependencies with no GPS or network: the user is in Kandy unless
/// [location] says otherwise.
MapDependencies fakeMapDependencies({
  required Widget child,
  FakeLocationService? location,
  FakeAttractions? attractions,
  FakeRouteService? routes,
  FakeWeatherService? weather,
}) {
  return MapDependencies(
    attractions: attractions ?? FakeAttractions(),
    createLocation: () =>
        location ??
        FakeLocationService(
          const LocationState(LocationStatus.ready, position: kandy),
        ),
    routes: routes ?? FakeRouteService(),
    weather: weather ?? FakeWeatherService(),
    tileProvider: BlankTileProvider(),
    child: child,
  );
}

/// Road routes without a network: roads are taken to be [detour] times
/// longer than the straight line, at fixed speeds.
class FakeRouteService implements RouteService {
  FakeRouteService({this.routeError, this.distancesFail = false});

  static const detour = 1.4;

  /// When set, [route] fails with this message.
  String? routeError;
  bool distancesFail;
  final routeModes = <TravelMode>[];

  static double roadMeters(LatLng from, LatLng to) =>
      TripEstimate.between(from, to).meters * detour;

  static Duration duration(double meters, TravelMode mode) => Duration(
    seconds: (meters / (mode == TravelMode.walk ? 1.25 : 12)).round(),
  );

  @override
  Future<RoadRoute> route(LatLng from, LatLng to, TravelMode mode) async {
    routeModes.add(mode);
    if (routeError case final message?) throw RouteException(message);
    final meters = roadMeters(from, to);
    return RoadRoute(
      // A bend in the road, so the route isn't a straight line.
      path: [from, LatLng(from.latitude, to.longitude), to],
      meters: meters,
      duration: duration(meters, mode),
    );
  }

  @override
  Future<List<RoadDistance?>> distances(
    LatLng from,
    List<LatLng> to,
    TravelMode mode,
  ) async {
    if (distancesFail) throw const RouteException('offline');
    return [
      for (final point in to)
        RoadDistance(
          roadMeters(from, point),
          duration(roadMeters(from, point), mode),
        ),
    ];
  }
}
