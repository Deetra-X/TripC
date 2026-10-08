import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:tripc/features/map/data/trip_estimate.dart';
import 'package:tripc/features/map/routing/route_service.dart';

const _kandy = LatLng(7.2936, 80.6413);
const _kumariElla = LatLng(6.9130, 80.1842);

/// An OSRM route response, shaped like routing.openstreetmap.de's.
Map<String, Object?> _routeResponse({double endSnap = 12}) => {
  'code': 'Ok',
  'waypoints': [
    {
      'distance': 8.0,
      'location': [80.6413, 7.2936],
    },
    {
      'distance': endSnap,
      'location': [80.1842, 6.9130],
    },
  ],
  'routes': [
    {
      'distance': 92801.4,
      'duration': 6905.2,
      'geometry': {
        'type': 'LineString',
        'coordinates': [
          [80.6413, 7.2936],
          [80.4, 7.1],
          [80.1842, 6.9130],
        ],
      },
    },
  ],
};

void main() {
  late List<Uri> requests;

  OsrmRouteService service(Map<String, Object?> Function(Uri) respond) {
    requests = [];
    return OsrmRouteService(
      minInterval: Duration.zero,
      client: MockClient((request) async {
        requests.add(request.url);
        return http.Response(jsonEncode(respond(request.url)), 200);
      }),
    );
  }

  test('reads the road route, its length and its duration', () async {
    final osrm = service((_) => _routeResponse());

    final route = await osrm.route(_kandy, _kumariElla, TravelMode.drive);

    expect(route.meters, closeTo(92801.4, 0.1));
    expect(route.duration, const Duration(seconds: 6905));
    expect(route.path, const [
      LatLng(7.2936, 80.6413),
      LatLng(7.1, 80.4),
      LatLng(6.9130, 80.1842),
    ]);
    // OSRM takes longitude first.
    expect(
      requests.single.path,
      '/routed-car/route/v1/driving/80.641300,7.293600;80.184200,6.913000',
    );
    expect(requests.single.queryParameters['geometries'], 'geojson');
  });

  test('uses the foot profile for walking and caches routes', () async {
    final osrm = service((_) => _routeResponse());

    await osrm.route(_kandy, _kumariElla, TravelMode.walk);
    await osrm.route(_kandy, _kumariElla, TravelMode.walk);

    expect(requests, hasLength(1));
    expect(requests.single.path, startsWith('/routed-foot/route/v1/foot/'));
  });

  test('refuses a destination far from any road', () async {
    final osrm = service((_) => _routeResponse(endSnap: 32177));

    expect(
      () => osrm.route(_kandy, const LatLng(8.9, 79.3), TravelMode.drive),
      throwsA(
        isA<RouteException>().having(
          (e) => e.message,
          'message',
          'This spot is 32 km from the nearest road.',
        ),
      ),
    );
  });

  test('reports server errors', () async {
    final osrm = service(
      (_) => {'code': 'NoRoute', 'message': 'Impossible route'},
    );

    expect(
      () => osrm.route(_kandy, _kumariElla, TravelMode.drive),
      throwsA(isA<RouteException>()),
    );
  });

  test('gets road distances in batches the server accepts', () async {
    final targets = [for (var i = 0; i < 150; i++) LatLng(7 + i / 1000, 80.5)];
    final osrm = service((uri) {
      final points = uri.pathSegments.last.split(';').length;
      return {
        'code': 'Ok',
        'distances': [
          [0, for (var i = 1; i < points; i++) i == 2 ? null : 1000.0 * i],
        ],
        'durations': [
          [0, for (var i = 1; i < points; i++) i == 2 ? null : 60.0 * i],
        ],
        'destinations': [
          for (var i = 0; i < points; i++) {'distance': i == 3 ? 5000 : 5},
        ],
      };
    });

    final distances = await osrm.distances(_kandy, targets, TravelMode.drive);

    expect(requests, hasLength(2));
    for (final uri in requests) {
      expect(uri.pathSegments.last.split(';').length, lessThanOrEqualTo(100));
      expect(uri.queryParameters['sources'], '0');
    }
    expect(distances, hasLength(150));
    expect(distances[0]!.meters, 1000);
    expect(distances[0]!.duration, const Duration(minutes: 1));
    // No road route to the second point, and the third is far off-road.
    expect(distances[1], isNull);
    expect(distances[2], isNull);
    expect(distances[3]!.meters, 4000);
  });
}
