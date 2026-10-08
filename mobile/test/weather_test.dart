import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:tripc/features/for_you/context/weather_service.dart';

void main() {
  test('WMO weather codes map to kinds of weather', () {
    expect(Weather.kindFromCode(0), WeatherKind.clear);
    expect(Weather.kindFromCode(3), WeatherKind.cloudy);
    expect(Weather.kindFromCode(45), WeatherKind.fog);
    expect(Weather.kindFromCode(51), WeatherKind.drizzle);
    expect(Weather.kindFromCode(63), WeatherKind.rain);
    expect(Weather.kindFromCode(81), WeatherKind.rain);
    expect(Weather.kindFromCode(95), WeatherKind.thunderstorm);
  });

  test('drizzle and rain count as wet', () {
    expect(
      const Weather(temperature: 25, kind: WeatherKind.drizzle).isWet,
      isTrue,
    );
    expect(
      const Weather(temperature: 25, kind: WeatherKind.cloudy).isWet,
      isFalse,
    );
    expect(
      const Weather(
        temperature: 25,
        kind: WeatherKind.cloudy,
        precipitation: 1.2,
      ).isWet,
      isTrue,
    );
  });

  test('reads current weather from Open-Meteo and caches it', () async {
    final requests = <Uri>[];
    final service = OpenMeteoWeatherService(
      client: MockClient((request) async {
        requests.add(request.url);
        return http.Response(
          jsonEncode({
            'current': {
              'temperature_2m': 25.2,
              'precipitation': 0.1,
              'weather_code': 51,
              'is_day': 1,
            },
          }),
          200,
        );
      }),
    );

    final weather = await service.current(const LatLng(7.2936, 80.6413));
    await service.current(const LatLng(7.2901, 80.6402));

    expect(weather.temperature, 25.2);
    expect(weather.kind, WeatherKind.drizzle);
    expect(weather.label, 'Drizzle');
    expect(weather.isDay, isTrue);
    expect(requests, hasLength(1));
    expect(requests.single.host, 'api.open-meteo.com');
    expect(
      requests.single.queryParameters['current'],
      contains('weather_code'),
    );
  });
}
