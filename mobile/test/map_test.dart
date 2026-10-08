import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:tripc/core/auth/auth_service.dart';
import 'package:tripc/core/theme/theme_controller.dart';
import 'package:tripc/features/map/data/attraction.dart';
import 'package:tripc/features/map/data/attraction_repository.dart';
import 'package:tripc/features/map/data/trip_estimate.dart';
import 'package:tripc/features/map/location/location_service.dart';
import 'package:tripc/features/map/map_screen.dart';
import 'package:tripc/features/map/widgets/map_markers.dart';

import 'fakes.dart';
import 'test_app.dart';

final _nallur = testPlaces.firstWhere((p) => p.id == '2');
final _arugamBay = testPlaces.firstWhere((p) => p.id == '5');
final _kumariElla = testPlaces.firstWhere((p) => p.id == '6');

Future<void> _pumpMap(
  WidgetTester tester, {
  FakeLocationService? location,
  FakeAttractions? attractions,
  FakeRouteService? routes,
  ThemeMode mode = ThemeMode.light,
}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

  await tester.pumpWidget(
    testApp(
      auth: AuthService(),
      theme: ThemeController()..value = mode,
      home: fakeMapDependencies(
        location: location,
        attractions: attractions,
        routes: routes,
        child: const Scaffold(body: MapScreen()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

FakeLocationService _at(LatLng position) => FakeLocationService(
  LocationState(LocationStatus.ready, position: position),
);

Finder _marker(Attraction place) => find.byKey(ValueKey('marker-${place.id}'));

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  group('trip estimates', () {
    test('format distances and durations for people', () {
      expect(formatDistance(54), '50 m');
      expect(formatDistance(950), '950 m');
      expect(formatDistance(1234), '1.2 km');
      expect(formatDistance(15400), '15 km');
      expect(formatDuration(const Duration(minutes: 45)), '45 min');
      expect(formatDuration(const Duration(minutes: 60)), '1 h');
      expect(formatDuration(const Duration(minutes: 125)), '2 h 5 min');
    });

    test('measure the straight-line distance between two places', () {
      const colombo = LatLng(6.9271, 79.8612);
      final km = TripEstimate.between(kandy, colombo).meters / 1000;
      expect(km, inInclusiveRange(90, 100));
    });
  });

  group('places table rows', () {
    test('are read using the table column names', () {
      final place = Attraction.fromMap({
        'place_id': 42,
        'place_name': 'Ella Rock',
        'province': 'Uva Province',
        'district': 'Badulla',
        'category': 'Mountains & Viewpoints',
        'latitude': '6.854',
        'longitude': 81.04,
        'description': ' A steep hike. ',
        'tag_nature': 1,
        'tag_hiking': '1',
        'tag_scenic': true,
        'tag_beach': 0,
        'indoor_outdoor': 'outdoor',
        'rain_sensitive': 'yes',
        'open_time': '05:00',
        'close_time': '17:00',
        'avg_rating': 4.7,
        'review_count': 3200,
        'bayesian_rating': 4.66,
        'hidden_gem': 'No',
      });
      expect(place.id, '42');
      expect(place.category, AttractionCategory.mountains);
      expect(place.location, const LatLng(6.854, 81.04));
      expect(place.district, 'Badulla');
      expect(place.description, 'A steep hike.');
      expect(place.tags, {
        InterestTag.nature,
        InterestTag.hiking,
        InterestTag.scenic,
      });
      expect(place.rainSensitive, isTrue);
      expect(place.hiddenGem, isFalse);
      expect(place.reviewCount, 3200);
      expect(place.rankingScore, 4.66);
    });

    test('without coordinates or an id still load, off the map', () {
      final place = Attraction.fromMap({
        'place_name': 'Bellwood',
        'category': 'Gardens & Parks',
      });
      expect(place.id, 'Bellwood');
      expect(place.location, isNull);
      expect(place.rankingScore, isNull);
    });

    test('match categories by full or short name', () {
      expect(
        AttractionCategory.fromName('Wildlife & Nature'),
        AttractionCategory.wildlife,
      );
      expect(
        AttractionCategory.fromName('Nightlife (Clubs & Pubs)'),
        AttractionCategory.nightlife,
      );
      expect(
        AttractionCategory.fromName(' beaches '),
        AttractionCategory.beaches,
      );
      expect(AttractionCategory.fromName('Zoo'), AttractionCategory.other);
      expect(AttractionCategory.fromName(null), AttractionCategory.other);
    });

    test('with a repeated place_id are kept apart', () {
      final places = parsePlaces([
        {'place_id': 289, 'place_name': 'A'},
        {'place_id': 289, 'place_name': 'B'},
        {'place_id': 290, 'place_name': 'C'},
      ]);
      expect(places.map((p) => p.id), ['289', '289-2', '290']);
    });

    test('in the spreadsheet export are all usable', () {
      final file = File('assets/data/places.json');
      final rows = (jsonDecode(file.readAsStringSync()) as List)
          .cast<Map<String, Object?>>();
      final places = parsePlaces(rows);

      expect(places, isNotEmpty);
      expect(places.map((p) => p.id).toSet(), hasLength(places.length));
      expect(
        places.where((p) => p.category == AttractionCategory.other),
        isEmpty,
        reason: 'every category in the sheet should have a map style',
      );
      final mapped = places.where((p) => p.location != null).toList();
      expect(mapped, isNotEmpty);
      for (final place in mapped) {
        expect(place.location!.latitude, inInclusiveRange(5.7, 10.0));
        expect(place.location!.longitude, inInclusiveRange(79.4, 82.1));
      }
    });
  });

  testWidgets('shows mapped places and the user, nearest first', (
    tester,
  ) async {
    await _pumpMap(tester, location: _at(kandy));

    expect(
      find.byType(AttractionMarker),
      findsNWidgets(mappedTestPlaces.length),
    );
    expect(find.byType(UserLocationDot), findsOneWidget);
    expect(find.text('${mappedTestPlaces.length} places'), findsOneWidget);
    expect(find.text('Nearest'), findsOneWidget);

    // Tapping search raises the sheet, revealing the list.
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    final tiles = find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith('place-'),
    );
    expect(tiles, findsNWidgets(mappedTestPlaces.length));
    // The user is standing at the Temple of the Tooth, so it comes first.
    expect(
      (tester.widgetList(tiles).first.key! as ValueKey<String>).value,
      'place-1',
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('place-1')),
        matching: find.text('0 m'),
      ),
      findsOneWidget,
    );
    expect(find.text('1 more place has no coordinates yet.'), findsOneWidget);
  });

  testWidgets('tapping a marker draws the road route with its distance', (
    tester,
  ) async {
    final routes = FakeRouteService();
    await _pumpMap(tester, location: _at(kandy), routes: routes);
    final meters = FakeRouteService.roadMeters(kandy, _nallur.location!);
    final straight = TripEstimate.between(kandy, _nallur.location!);

    await tester.tap(_marker(_nallur));
    await tester.pumpAndSettle();

    expect(find.text(_nallur.name), findsOneWidget);
    expect(find.text('By road'), findsOneWidget);
    // Shown in the panel and on the route itself.
    expect(find.text(formatDistance(meters)), findsNWidgets(2));
    expect(find.text(straight.distanceLabel), findsNothing);
    expect(
      find.text(
        formatDuration(FakeRouteService.duration(meters, TravelMode.drive)),
      ),
      findsOneWidget,
    );
    expect(find.text('By car'), findsOneWidget);
    final route = tester.widget<PolylineLayer>(find.byType(PolylineLayer));
    expect(route.polylines.first.points, hasLength(3));
    expect(routes.routeModes, [TravelMode.drive]);

    await _tapVisible(tester, find.text('Walk'));
    expect(routes.routeModes, [TravelMode.drive, TravelMode.walk]);
    expect(
      find.text(
        formatDuration(FakeRouteService.duration(meters, TravelMode.walk)),
      ),
      findsOneWidget,
    );
    expect(find.text('On foot'), findsOneWidget);

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.text('By road'), findsNothing);
    expect(find.byType(PolylineLayer), findsNothing);
    expect(find.text('${mappedTestPlaces.length} places'), findsOneWidget);
  });

  testWidgets('without a road route the map says so and can retry', (
    tester,
  ) async {
    final routes = FakeRouteService(
      routeError: 'This spot is 32 km from the nearest road.',
    );
    await _pumpMap(tester, location: _at(kandy), routes: routes);
    final straight = TripEstimate.between(kandy, _nallur.location!);

    await tester.tap(_marker(_nallur));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('No road route: This spot is 32 km'),
      findsOneWidget,
    );
    // The straight line is only a fallback, and marked as one.
    expect(
      find.textContaining('≈ ${straight.distanceLabel} in a straight line'),
      findsOneWidget,
    );
    expect(find.text('≈ ${straight.distanceLabel}'), findsOneWidget);
    expect(find.text('By road'), findsNothing);

    routes.routeError = null;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('By road'), findsOneWidget);
    expect(find.textContaining('No road route'), findsNothing);
  });

  testWidgets('the list shows road distances', (tester) async {
    await _pumpMap(tester, location: _at(kandy));
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    final road = FakeRouteService.roadMeters(kandy, _arugamBay.location!);
    expect(
      find.descendant(
        of: find.byKey(ValueKey('place-${_arugamBay.id}')),
        matching: find.text(formatDistance(road)),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('≈'), findsNothing);
  });

  testWidgets('if road distances fail, the list marks them approximate', (
    tester,
  ) async {
    await _pumpMap(
      tester,
      location: _at(kandy),
      routes: FakeRouteService(distancesFail: true),
    );
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    final straight = TripEstimate.between(kandy, _arugamBay.location!);
    expect(
      find.descendant(
        of: find.byKey(ValueKey('place-${_arugamBay.id}')),
        matching: find.text('≈ ${straight.distanceLabel}'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a place shows its rating, gem status, hours and conditions', (
    tester,
  ) async {
    await _pumpMap(tester, location: _at(kandy));

    await tester.tap(_marker(_kumariElla));
    await tester.pumpAndSettle();

    expect(find.text('Kumari Ella'), findsOneWidget);
    expect(find.text('Colombo · Waterfalls'), findsOneWidget);
    expect(find.text('4.4 (1,524)'), findsOneWidget);
    expect(find.text('Hidden gem'), findsOneWidget);
    expect(find.text('07:30–18:00'), findsOneWidget);
    expect(find.text('Outdoor'), findsOneWidget);
    expect(find.text('Best on dry days'), findsOneWidget);

    // Distance comes first; the description follows further down.
    final description = find.text(
      _kumariElla.description!,
      skipOffstage: false,
    );
    expect(
      tester.getTopLeft(description).dy,
      greaterThan(tester.getTopLeft(find.text('By road')).dy),
    );
    await tester.ensureVisible(description);
    await tester.pumpAndSettle();
    expect(find.text(_kumariElla.description!), findsOneWidget);
  });

  testWidgets('tapping the map drops a pin and shows its distance', (
    tester,
  ) async {
    await _pumpMap(tester, location: _at(kandy));

    // Open sea west of the island, away from every marker.
    await tester.tapAt(const Offset(24, 300));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.text('Dropped pin'), findsOneWidget);
    expect(find.byType(DroppedPinMarker), findsOneWidget);
    expect(find.byType(DistancePill), findsOneWidget);
    expect(find.text('By road'), findsOneWidget);
  });

  testWidgets('category chips filter markers and the list', (tester) async {
    await _pumpMap(tester, location: _at(kandy));
    final beaches = mappedTestPlaces
        .where((p) => p.category == AttractionCategory.beaches)
        .length;

    await _tapVisible(tester, find.text('Beaches'));

    expect(find.byType(AttractionMarker), findsNWidgets(beaches));
    expect(find.text('$beaches places'), findsOneWidget);
  });

  testWidgets('search finds places by district', (tester) async {
    await _pumpMap(tester, location: _at(kandy));

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'jaffna');
    await tester.pumpAndSettle();

    expect(find.text('1 place'), findsOneWidget);
    expect(find.byType(AttractionMarker), findsOneWidget);
    expect(find.text(_nallur.name), findsOneWidget);
  });

  testWidgets('without permission the map explains and can ask again', (
    tester,
  ) async {
    final location = FakeLocationService(
      const LocationState(LocationStatus.denied),
    );
    await _pumpMap(tester, location: location);

    expect(find.text('Allow location to see distances'), findsOneWidget);
    expect(find.byType(UserLocationDot), findsNothing);
    expect(find.text('Top rated'), findsOneWidget);

    // The banner covers the far north, so pick Arugam Bay mid-island.
    await tester.tap(_marker(_arugamBay));
    await tester.pumpAndSettle();
    expect(find.text(_arugamBay.name), findsOneWidget);
    expect(
      find.text('Turn on location to see the route and distance.'),
      findsOneWidget,
    );
    expect(find.byType(DistancePill), findsNothing);

    // Permission is granted on the second request.
    location.state = const LocationState(LocationStatus.ready, position: kandy);
    await tester.tap(find.text('Allow'));
    await tester.pumpAndSettle();
    expect(location.starts, 2);
    expect(find.text('Allow location to see distances'), findsNothing);
    // With a position, the road route to the open destination follows.
    expect(find.text('By road'), findsOneWidget);
  });

  testWidgets('blocked location sends the user to settings', (tester) async {
    final location = FakeLocationService(
      const LocationState(LocationStatus.deniedForever),
    );
    await _pumpMap(tester, location: location);

    await tester.tap(find.text('Settings'));
    await tester.pump();
    expect(location.settingsOpened, 1);
  });

  testWidgets('a failed load offers a retry', (tester) async {
    final attractions = FakeAttractions(fail: true);
    await _pumpMap(tester, attractions: attractions);

    expect(find.text("Couldn't load places"), findsOneWidget);
    expect(find.byType(AttractionMarker), findsNothing);

    attractions.fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('${mappedTestPlaces.length} places'), findsOneWidget);
    expect(
      find.byType(AttractionMarker),
      findsNWidgets(mappedTestPlaces.length),
    );
  });

  testWidgets('lays out in dark mode with a destination open', (tester) async {
    await _pumpMap(tester, location: _at(kandy), mode: ThemeMode.dark);

    await tester.tap(_marker(_kumariElla));
    await tester.pumpAndSettle();

    expect(find.text('Kumari Ella'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
