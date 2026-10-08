import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tripc/core/auth/auth_service.dart';
import 'package:tripc/core/theme/app_theme.dart';
import 'package:tripc/core/theme/theme_controller.dart';
import 'package:tripc/features/home/home_screen.dart';

import 'fakes.dart';

/// Wraps [home] the way TripCApp does: auth, the theme choice and both
/// themes. The map gets fake GPS, data and tiles, so tests stay offline.
Widget testApp({
  required AuthService auth,
  required ThemeController theme,
  required Widget home,
}) {
  return fakeMapDependencies(
    child: AuthScope(
      auth: auth,
      child: ThemeScope(
        controller: theme,
        child: ValueListenableBuilder<ThemeMode>(
          valueListenable: theme,
          builder: (_, mode, _) => MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: mode,
            home: home,
          ),
        ),
      ),
    ),
  );
}

/// Pumps the signed-in home screen on a phone-sized screen and returns the
/// theme controller driving it.
Future<ThemeController> pumpSignedInHome(
  WidgetTester tester, {
  ThemeMode mode = ThemeMode.system,
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  // The map's pulsing location dot would otherwise keep pumpAndSettle busy.
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
  final theme = ThemeController()..value = mode;
  await tester.pumpWidget(
    testApp(auth: auth, theme: theme, home: const HomeScreen()),
  );
  await tester.pumpAndSettle();
  return theme;
}
