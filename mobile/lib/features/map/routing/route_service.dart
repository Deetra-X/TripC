import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../data/trip_estimate.dart';

/// A route along the road network.
class RoadRoute {
  const RoadRoute({
    required this.path,
    required this.meters,
    required this.duration,
  });

  /// The roads to follow, from the start to the destination.
  final List<LatLng> path;
  final double meters;
  final Duration duration;
}

/// How far a place is by road, and how long it takes.
class RoadDistance {
  const RoadDistance(this.meters, this.duration);

  final double meters;
  final Duration duration;
}

class RouteException implements Exception {
  const RouteException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Finds routes and distances along roads rather than in straight lines.
abstract interface class RouteService {
  /// The best route by road from [from] to [to].
  Future<RoadRoute> route(LatLng from, LatLng to, TravelMode mode);

  /// Road distance from [from] to each point in [to], in the same order;
  /// null where no road reaches it.
  Future<List<RoadDistance?>> distances(
    LatLng from,
    List<LatLng> to,
    TravelMode mode,
  );
}

/// Routes from OSRM (Open Source Routing Machine), hosted by FOSSGIS at
/// routing.openstreetmap.de. OSRM finds shortest paths through the
/// OpenStreetMap road network with a sped-up form of Dijkstra's algorithm,
/// weighting roads by travel time, so the route is the fastest one, as in
/// most navigation apps.
///
/// The free service asks for at most one request per second, a valid user
/// agent and visible attribution. Requests are therefore queued and spaced
/// out, and results are cached.
class OsrmRouteService implements RouteService {
  OsrmRouteService({
    http.Client? client,
    this.baseUrl = 'https://routing.openstreetmap.de',
    this.minInterval = const Duration(seconds: 1),
  }) : _client = client ?? http.Client();

  /// Shared by every map, so the rate limit and cache apply app-wide.
  static final shared = OsrmRouteService();

  /// A start or end point further than this from any road can't be reached
  /// by road; OSRM would otherwise quietly use the nearest road.
  static const maxSnapMeters = 1500.0;

  /// The server's limit on points in one table request, origin included.
  static const _tableSize = 100;
  static const _timeout = Duration(seconds: 15);

  final http.Client _client;
  final String baseUrl;
  final Duration minInterval;

  Future<void> _queue = Future.value();
  DateTime _lastRequest = DateTime.fromMillisecondsSinceEpoch(0);
  final _routes = <String, RoadRoute>{};
  final _tables = <String, Future<List<RoadDistance?>>>{};

  @override
  Future<RoadRoute> route(LatLng from, LatLng to, TravelMode mode) async {
    final key = '${mode.name} ${_key(from)} ${_key(to)}';
    if (_routes[key] case final cached?) return cached;

    final body = await _get(
      'route',
      mode,
      [from, to],
      {'overview': 'full', 'geometries': 'geojson'},
    );
    final waypoints = (body['waypoints']! as List).cast<Map<String, Object?>>();
    _checkSnap(waypoints.first, 'You are');
    _checkSnap(waypoints.last, 'This spot is');

    final best = (body['routes']! as List).first as Map<String, Object?>;
    final geometry = best['geometry']! as Map<String, Object?>;
    final route = RoadRoute(
      path: [
        for (final point in (geometry['coordinates']! as List).cast<List>())
          LatLng((point[1] as num).toDouble(), (point[0] as num).toDouble()),
      ],
      meters: (best['distance']! as num).toDouble(),
      duration: Duration(seconds: (best['duration']! as num).round()),
    );
    if (_routes.length > 50) _routes.remove(_routes.keys.first);
    return _routes[key] = route;
  }

  @override
  Future<List<RoadDistance?>> distances(
    LatLng from,
    List<LatLng> to,
    TravelMode mode,
  ) {
    // Several screens may ask for the same table, possibly at the same
    // moment; they share one request. The origin is rounded to about 100 m.
    final key =
        '${mode.name} '
        '${from.latitude.toStringAsFixed(3)},${from.longitude.toStringAsFixed(3)} '
        '${Object.hashAll(to.map(_key))}';
    if (_tables[key] case final pending?) return pending;
    if (_tables.length > 10) _tables.remove(_tables.keys.first);
    final request = _tables[key] = _fetchDistances(from, to, mode);
    // A failed request isn't kept, so the next call tries again.
    request.then(
      (_) {},
      onError: (Object _) {
        _tables.remove(key);
      },
    );
    return request;
  }

  Future<List<RoadDistance?>> _fetchDistances(
    LatLng from,
    List<LatLng> to,
    TravelMode mode,
  ) async {
    final results = <RoadDistance?>[];
    for (var start = 0; start < to.length; start += _tableSize - 1) {
      final batch = to.sublist(
        start,
        math.min(start + _tableSize - 1, to.length),
      );
      final body = await _get(
        'table',
        mode,
        [from, ...batch],
        {'sources': '0', 'annotations': 'distance,duration'},
      );
      final meters = (body['distances']! as List).first as List;
      final seconds = (body['durations']! as List).first as List;
      final points = (body['destinations']! as List)
          .cast<Map<String, Object?>>();
      // Index 0 is the origin itself.
      for (var i = 1; i <= batch.length; i++) {
        final distance = meters[i] as num?;
        final duration = seconds[i] as num?;
        final snap = (points[i]['distance'] as num?) ?? 0;
        results.add(
          distance == null || duration == null || snap > maxSnapMeters
              ? null
              : RoadDistance(
                  distance.toDouble(),
                  Duration(seconds: duration.round()),
                ),
        );
      }
    }
    return results;
  }

  void _checkSnap(Map<String, Object?> waypoint, String subject) {
    final meters = (waypoint['distance'] as num?)?.toDouble() ?? 0;
    if (meters > maxSnapMeters) {
      throw RouteException(
        '$subject ${formatDistance(meters)} from the nearest road.',
      );
    }
  }

  /// Sends one request at a time, at least [minInterval] apart.
  Future<Map<String, Object?>> _get(
    String service,
    TravelMode mode,
    List<LatLng> points,
    Map<String, String> query,
  ) {
    final profile = switch (mode) {
      TravelMode.walk => 'routed-foot/$service/v1/foot',
      TravelMode.drive => 'routed-car/$service/v1/driving',
    };
    final coordinates = points
        .map(
          (p) =>
              '${p.longitude.toStringAsFixed(6)},${p.latitude.toStringAsFixed(6)}',
        )
        .join(';');
    final uri = Uri.parse('$baseUrl/$profile/$coordinates')
        .replace(queryParameters: query);

    final request = _queue.then((_) async {
      final wait = _lastRequest.add(minInterval).difference(DateTime.now());
      if (wait > Duration.zero) await Future<void>.delayed(wait);
      _lastRequest = DateTime.now();
      final response = await _client
          .get(
            uri,
            // Browsers set their own user agent and refuse to override it.
            headers: kIsWeb
                ? null
                : const {
                    'User-Agent':
                        'TripC/0.1 (research prototype; '
                        'com.deetrax.tripc)',
                  },
          )
          .timeout(_timeout);
      final body = jsonDecode(response.body) as Map<String, Object?>;
      if (response.statusCode != 200 || body['code'] != 'Ok') {
        throw RouteException(
          body['message'] as String? ?? 'No road route found.',
        );
      }
      return body;
    });
    _queue = request.then((_) {}, onError: (Object _) {});
    return request;
  }
}

String _key(LatLng p) =>
    '${p.latitude.toStringAsFixed(4)},${p.longitude.toStringAsFixed(4)}';
