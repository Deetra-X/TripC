import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tripc/core/auth/auth_service.dart';
import 'package:tripc/core/theme/app_colors.dart';
import 'package:tripc/core/theme/app_theme.dart';
import 'package:tripc/core/theme/app_typography.dart';
import 'package:tripc/core/theme/theme_controller.dart';
import 'package:tripc/core/widgets/ambient_background.dart';
import 'package:tripc/features/home/home_screen.dart';
import 'package:tripc/features/login/auth_gate.dart';
import 'package:tripc/features/profile/widgets/day_night_switch.dart';

import 'test_app.dart';

/// WCAG 2 contrast ratio between two opaque colours.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

// Home stays built under pages opened over it, such as Settings.
Brightness _brightness(WidgetTester tester) =>
    Theme.of(tester.element(find.byType(HomeScreen, skipOffstage: false)))
        .brightness;

Color _backgroundColour(WidgetTester tester) => tester
    .widget<ColoredBox>(
      find
          .descendant(
            of: find.byType(AmbientBackground, skipOffstage: false),
            matching: find.byType(ColoredBox, skipOffstage: false),
            skipOffstage: false,
          )
          .first,
    )
    .color;

void main() {
  for (final (name, c) in [
    ('light', TripCColors.light),
    ('dark', TripCColors.dark),
  ]) {
    test('$name colours meet WCAG contrast targets', () {
      for (final background in [c.background, c.surface, c.surfaceRaised]) {
        expect(_contrast(c.textPrimary, background), greaterThanOrEqualTo(7));
        expect(
          _contrast(c.textSecondary, background),
          greaterThanOrEqualTo(4.5),
        );
        expect(_contrast(c.brand, background), greaterThanOrEqualTo(4.5));
        // Accent is for icons and highlights, which need 3:1.
        expect(_contrast(c.accent, background), greaterThanOrEqualTo(3));
      }
      expect(
        _contrast(c.textTertiary, c.surfaceRaised),
        greaterThanOrEqualTo(3),
      );
      expect(_contrast(c.onBrand, c.brand), greaterThanOrEqualTo(4.5));
      expect(_contrast(c.onInverse, c.inverse), greaterThanOrEqualTo(7));
    });
  }

  test('both themes set every text style in Manrope', () {
    for (final theme in [AppTheme.light, AppTheme.dark]) {
      final styles = [
        theme.textTheme.displaySmall,
        theme.textTheme.headlineMedium,
        theme.textTheme.titleLarge,
        theme.textTheme.bodyMedium,
        theme.textTheme.bodySmall,
        theme.textTheme.labelLarge,
        theme.filledButtonTheme.style?.textStyle?.resolve({}),
        theme.textButtonTheme.style?.textStyle?.resolve({}),
      ];
      for (final style in styles) {
        expect(style?.fontFamily, AppTypography.fontFamily);
      }
      expect(theme.extension<TripCColors>(), isNotNull);
    }
  });

  test('the theme choice starts on System', () {
    expect(ThemeController().value, ThemeMode.system);
  });

  testWidgets('System follows the device brightness', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await pumpSignedInHome(tester);

    expect(_brightness(tester), Brightness.dark);
    expect(_backgroundColour(tester), TripCColors.dark.background);
  });

  testWidgets('the day and night switch in Settings changes the theme', (
    tester,
  ) async {
    final theme = await pumpSignedInHome(tester);
    expect(_brightness(tester), Brightness.light);

    await tester.tap(find.byTooltip('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('DAY MODE'), findsOneWidget);
    bool matchesPhone() => tester.widget<Switch>(find.byType(Switch)).value;
    expect(matchesPhone(), isTrue);

    await tester.tap(find.byType(DayNightSwitch));
    await tester.pumpAndSettle();
    expect(theme.value, ThemeMode.dark);
    expect(_brightness(tester), Brightness.dark);
    expect(_backgroundColour(tester), TripCColors.dark.background);
    expect(find.text('NIGHT MODE'), findsOneWidget);
    expect(matchesPhone(), isFalse);

    await tester.tap(find.byType(DayNightSwitch));
    await tester.pumpAndSettle();
    expect(theme.value, ThemeMode.light);
    expect(_brightness(tester), Brightness.light);
    expect(_backgroundColour(tester), TripCColors.light.background);

    // Matching the phone again follows the device, which is light here.
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(theme.value, ThemeMode.system);
    expect(find.text('DAY MODE'), findsOneWidget);
  });

  testWidgets('turning off Match my phone keeps the current look', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    final theme = await pumpSignedInHome(tester);
    await tester.tap(find.byTooltip('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('NIGHT MODE'), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(theme.value, ThemeMode.dark);
    expect(_brightness(tester), Brightness.dark);
  });

  testWidgets('Discover lays out and uses dark colours in dark mode', (
    tester,
  ) async {
    await pumpSignedInHome(tester, mode: ThemeMode.dark);

    final greeting = tester.widget<Text>(find.text('Hello, Nimal'));
    expect(greeting.style?.color, TripCColors.dark.textPrimary);

    await tester.scrollUntilVisible(
      find.text('Nine Arches Bridge'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('login works in dark mode', (tester) async {
    await tester.pumpWidget(
      testApp(
        auth: AuthService(),
        theme: ThemeController()..value = ThemeMode.dark,
        home: const AuthGate(),
      ),
    );

    final context = tester.element(find.text('Welcome back'));
    expect(Theme.of(context).brightness, Brightness.dark);
    expect(
      Theme.of(context).scaffoldBackgroundColor,
      TripCColors.dark.background,
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await tester.pumpAndSettle();
    expect(find.text('Enter your email.'), findsOneWidget);
  });
}
