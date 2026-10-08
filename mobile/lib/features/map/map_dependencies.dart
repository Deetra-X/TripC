import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';

import '../for_you/context/weather_service.dart';
import 'data/attraction_repository.dart';
import 'location/location_service.dart';
import 'routing/route_service.dart';

/// Lets an ancestor choose where the Map and For You get their places,
/// location, road routes, weather and tiles. Without one they use the
/// bundled places, the device's GPS, OSRM, Open-Meteo and online tiles.
/// Tests use it to supply fakes.
class MapDependencies extends InheritedWidget {
  const MapDependencies({
    super.key,
    required this.attractions,
    required this.createLocation,
    this.routes,
    this.weather,
    this.tileProvider,
    required super.child,
  });

  final AttractionRepository attractions;

  /// Creates a location service; each screen disposes its own.
  final LocationService Function() createLocation;

  final RouteService? routes;
  final WeatherService? weather;
  final TileProvider? tileProvider;

  static MapDependencies? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<MapDependencies>();

  @override
  bool updateShouldNotify(MapDependencies oldWidget) => false;
}
