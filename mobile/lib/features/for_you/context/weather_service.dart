import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

enum WeatherKind { clear, cloudy, fog, drizzle, rain, thunderstorm }

/// Current weather at the user's position, part of the context for
/// recommendations.
@immutable
class Weather {
  const Weather({
    required this.temperature,
    required this.kind,
    this.isDay = true,
    this.precipitation = 0,
  });

  /// Degrees Celsius.
  final double temperature;
  final WeatherKind kind;
  final bool isDay;

  /// Millimetres in the last 15 minutes.
  final double precipitation;

  /// Whether it's raining enough to matter for outdoor plans.
  bool get isWet =>
      kind == WeatherKind.drizzle ||
      kind == WeatherKind.rain ||
      kind == WeatherKind.thunderstorm ||
      precipitation >= 0.5;

  String get label => switch (kind) {
    WeatherKind.clear => isDay ? 'Sunny' : 'Clear',
    WeatherKind.cloudy => 'Cloudy',
    WeatherKind.fog => 'Foggy',
    WeatherKind.drizzle => 'Drizzle',
    WeatherKind.rain => 'Rain',
    WeatherKind.thunderstorm => 'Thunderstorms',
  };

  IconData get icon => switch (kind) {
    WeatherKind.clear =>
      isDay ? Icons.wb_sunny_outlined : Icons.nightlight_outlined,
    WeatherKind.cloudy || WeatherKind.fog => Icons.cloud_outlined,
    WeatherKind.drizzle => Icons.grain_rounded,
    WeatherKind.rain => Icons.umbrella_outlined,
    WeatherKind.thunderstorm => Icons.thunderstorm_outlined,
  };

  /// Maps a WMO weather code, as used by Open-Meteo.
  static WeatherKind kindFromCode(int code) => switch (code) {
    0 || 1 => WeatherKind.clear,
    45 || 48 => WeatherKind.fog,
    >= 51 && <= 57 => WeatherKind.drizzle,
    (>= 61 && <= 67) || (>= 80 && <= 82) => WeatherKind.rain,
    >= 95 => WeatherKind.thunderstorm,
    _ => WeatherKind.cloudy,
  };
}

abstract interface class WeatherService {
  Future<Weather> current(LatLng at);
}

/// Weather from Open-Meteo (open-meteo.com): free for non-commercial use
/// with no key, under CC BY 4.0, so the app credits it where weather is
/// shown. Results are kept for 15 minutes per area.
class OpenMeteoWeatherService implements WeatherService {
  OpenMeteoWeatherService({http.Client? client})
    : _client = client ?? http.Client();

  static final shared = OpenMeteoWeatherService();

  static const attribution = 'Weather data by Open-Meteo.com';
  static const _maxAge = Duration(minutes: 15);

  final http.Client _client;
  final _cache = <String, (DateTime, Weather)>{};

  @override
  Future<Weather> current(LatLng at) async {
    // About a 10 km area shares one forecast.
    final key =
        '${at.latitude.toStringAsFixed(1)},${at.longitude.toStringAsFixed(1)}';
    if (_cache[key] case (final time, final weather)
        when DateTime.now().difference(time) < _maxAge) {
      return weather;
    }

    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': at.latitude.toStringAsFixed(4),
      'longitude': at.longitude.toStringAsFixed(4),
      'current': 'temperature_2m,precipitation,weather_code,is_day',
      'timezone': 'auto',
    });
    final response = await _client
        .get(uri)
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw http.ClientException('Weather ${response.statusCode}', uri);
    }
    final current =
        (jsonDecode(response.body) as Map<String, Object?>)['current']!
            as Map<String, Object?>;
    final weather = Weather(
      temperature: (current['temperature_2m']! as num).toDouble(),
      kind: Weather.kindFromCode((current['weather_code']! as num).toInt()),
      isDay: current['is_day'] == 1,
      precipitation: (current['precipitation'] as num?)?.toDouble() ?? 0,
    );
    _cache[key] = (DateTime.now(), weather);
    return weather;
  }
}
