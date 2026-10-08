import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:tripc/core/auth/auth_service.dart';
import 'package:tripc/core/theme/theme_controller.dart';
import 'package:tripc/features/for_you/context/weather_service.dart';
import 'package:tripc/features/for_you/for_you_screen.dart';
import 'package:tripc/features/for_you/widgets/pick_widgets.dart';
import 'package:tripc/features/home/home_screen.dart';
import 'package:tripc/features/map/location/location_service.dart';
import 'package:tripc/features/map/map_screen.dart';

import 'fakes.dart';
import 'test_app.dart';

/// Signs in, wraps the home screen with [weather] and [location], and opens
/// For You.
Future<void> _openForYou(
  WidgetTester tester, {
  FakeWeatherService? weather,
  FakeLocationService? location,
  ThemeMode mode = ThemeMode.light,
}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

  final auth = AuthService();
  await tester.runAsync(
    () => auth.signUp(
      name: 'Nimal Perera',
      email: 'nimal@example.com',
      password: 'secret123',
    ),
  );
  await tester.pumpWidget(
    testApp(
      auth: auth,
      theme: ThemeController()..value = mode,
      home: fakeMapDependencies(
        weather: weather,
        location: location,
        child: const HomeScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('For you'));
  await tester.pumpAndSettle();
}

Future<void> _chooseInterests(WidgetTester tester, List<String> labels) async {
  await tester.tap(find.text('Choose interests'));
  await tester.pumpAndSettle();
  for (final label in labels) {
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }
  await tester.tap(find.text('Show my picks'));
  await tester.pumpAndSettle();
}

Finder get _page => find
    .descendant(
      of: find.byType(ForYouScreen),
      matching: find.byType(Scrollable),
    )
    .first;

void main() {
  testWidgets('sits between Discover and Map in the navigation', (
    tester,
  ) async {
    await _openForYou(tester);

    final order = ['Discover', 'For you', 'Map', 'Saved', 'Profile'];
    final xs = [
      for (final tab in order) tester.getCenter(find.byTooltip(tab)).dx,
    ];
    expect(xs, orderedEquals([...xs]..sort()));
  });

  testWidgets('shows where, the weather and the time of day', (tester) async {
    await _openForYou(tester);

    expect(find.text('For you'), findsWidgets);
    expect(find.textContaining('Around Kandy'), findsOneWidget);
    expect(find.textContaining('28° · Sunny'), findsOneWidget);
    expect(find.text(OpenMeteoWeatherService.attribution), findsOneWidget);
  });

  testWidgets('asks for interests, then ranks places for them', (tester) async {
    await _openForYou(tester);

    expect(find.text('Tell us what you love'), findsOneWidget);
    expect(find.text('Popular right now'), findsOneWidget);

    await _chooseInterests(tester, ['Beaches']);

    expect(find.text('Top picks for you'), findsOneWidget);
    expect(find.text('Your interests'), findsOneWidget);
    expect(find.text('Beaches'), findsOneWidget);
    // The best pick is a beach, explained by the interest.
    final first = tester.widget<TopPickCard>(find.byType(TopPickCard).first);
    expect(first.pick.place.tags.map((t) => t.name), contains('beach'));
    expect(first.pick.reasons.first, 'Because you like beaches');
    expect(find.text('Because you like beaches'), findsWidgets);
  });

  testWidgets('a pick opens on the map, then shows under Keep exploring', (
    tester,
  ) async {
    await _openForYou(tester);
    await _chooseInterests(tester, ['Beaches']);

    final first = tester.widget<TopPickCard>(find.byType(TopPickCard).first);
    final name = first.pick.place.name;
    await tester.tap(find.byType(TopPickCard).first);
    await tester.pumpAndSettle();

    expect(find.byType(MapScreen), findsOneWidget);
    expect(find.text(name), findsOneWidget);
    expect(find.text('By road'), findsOneWidget);

    await tester.tap(find.byTooltip('For you'));
    await tester.pumpAndSettle();
    final recent = find.byKey(ValueKey('recent-${first.pick.place.id}'));
    await tester.scrollUntilVisible(recent, 200, scrollable: _page);
    expect(recent, findsOneWidget);
    expect(find.text('Keep exploring'), findsOneWidget);
    expect(find.text('Recently viewed'), findsOneWidget);
  });

  testWidgets('warns about nearby rain-sensitive places when it rains', (
    tester,
  ) async {
    // Standing in Mirissa, whose beach is rain-sensitive.
    await _openForYou(
      tester,
      location: FakeLocationService(
        const LocationState(
          LocationStatus.ready,
          position: LatLng(5.9480, 80.4560),
        ),
      ),
      weather: FakeWeatherService(
        const Weather(temperature: 24, kind: WeatherKind.rain),
      ),
    );
    await _chooseInterests(tester, ['Beaches']);

    expect(find.textContaining('24° · Rain'), findsOneWidget);
    expect(
      find.text('Rain now · best on dry days', skipOffstage: false),
      findsWidgets,
    );
  });

  testWidgets('every pick shows why it was suggested', (tester) async {
    await _openForYou(tester);
    await _chooseInterests(tester, ['Nature']);

    // With six test places they're all top picks; rows show reasons the
    // same way.
    final cards = tester.widgetList<TopPickCard>(
      find.byType(TopPickCard, skipOffstage: false),
    );
    expect(cards, isNotEmpty);
    for (final card in cards) {
      final reason = card.pick.reasons.isNotEmpty
          ? card.pick.reasons.first
          : 'See why it scored ${card.pick.matchPercent}%';
      expect(
        find.descendant(
          of: find.byWidget(card, skipOffstage: false),
          matching: find.text(reason, skipOffstage: false),
          skipOffstage: false,
        ),
        findsOneWidget,
      );
    }
    expect(
      find.text('Because you like nature', skipOffstage: false),
      findsWidgets,
    );
  });

  testWidgets('Why? shows how the match was calculated', (tester) async {
    await _openForYou(tester);
    await _chooseInterests(tester, ['Beaches']);
    final pick = tester
        .widget<TopPickCard>(find.byType(TopPickCard).first)
        .pick;

    await tester.tap(find.textContaining('match · Why?').first);
    await tester.pumpAndSettle();

    expect(find.text('Why this pick?'), findsOneWidget);
    final sheet = find.byType(BottomSheet);
    for (final part in ['Your interests', 'Quality', 'Distance', 'Right now']) {
      expect(
        find.descendant(of: sheet, matching: find.text(part)),
        findsOneWidget,
      );
    }
    final w = pick.weights;
    final interestPoints = (pick.interestMatch * w.interest * 100)
        .toStringAsFixed(1);
    expect(
      find.text(
        '${(pick.interestMatch * 100).round()}% × '
        '${(w.interest * 100).round()}% = $interestPoints',
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining('Shares Beaches with your interests'),
      findsOneWidget,
    );

    await tester.ensureVisible(find.text('Show on map'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show on map'));
    await tester.pumpAndSettle();
    expect(find.text('Why this pick?'), findsNothing);
    expect(find.text(pick.place.name), findsOneWidget);
    expect(find.text('By road'), findsOneWidget);
  });

  testWidgets('explains how picks are chosen', (tester) async {
    await _openForYou(tester);

    await tester.scrollUntilVisible(
      find.text('How your picks are chosen'),
      300,
      scrollable: _page,
    );
    await tester.tap(find.text('How your picks are chosen'));
    await tester.pumpAndSettle();

    expect(find.text('40%'), findsOneWidget);
    expect(find.textContaining('Open-Meteo'), findsWidgets);
  });

  testWidgets('lays out in dark mode', (tester) async {
    await _openForYou(tester, mode: ThemeMode.dark);
    await _chooseInterests(tester, ['Nature', 'Beaches']);

    await tester.scrollUntilVisible(
      find.text('How your picks are chosen'),
      300,
      scrollable: _page,
    );
    expect(tester.takeException(), isNull);
  });
}
