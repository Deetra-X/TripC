import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tripc/app.dart';
import 'package:tripc/core/auth/auth_service.dart';
import 'package:tripc/core/theme/theme_controller.dart';
import 'package:tripc/features/home/home_screen.dart';
import 'package:tripc/features/login/auth_gate.dart';
import 'package:tripc/features/login/login_screen.dart';
import 'package:tripc/features/login/signup_screen.dart';
import 'package:tripc/features/profile/settings_screen.dart';

import 'test_app.dart';

Finder _field(String label) => find.widgetWithText(TextFormField, label);

void main() {
  testWidgets('finishing onboarding opens the login page', (tester) async {
    await tester.pumpWidget(
      TripCApp(auth: AuthService(), themeMode: ThemeController()),
    );

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Get started'));
      await tester.pumpAndSettle();
    }

    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('home is only reachable after logging in', (tester) async {
    // The map's pulsing location dot would otherwise keep pumpAndSettle busy.
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    await tester.pumpWidget(
      testApp(
        auth: AuthService(),
        theme: ThemeController(),
        home: const AuthGate(),
      ),
    );
    final logIn = find.widgetWithText(FilledButton, 'Log in');

    // No account yet.
    await tester.enterText(_field('Email'), 'nimal@example.com');
    await tester.enterText(_field('Password'), 'secret123');
    await tester.tap(logIn);
    await tester.pumpAndSettle();
    expect(find.text('Incorrect email or password.'), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);

    // Sign up, which signs the user in.
    await tester.tap(find.text('Sign up'));
    await tester.pumpAndSettle();
    expect(find.byType(SignupScreen), findsOneWidget);
    await tester.enterText(_field('Full name'), 'Nimal Perera');
    await tester.enterText(_field('Email'), 'nimal@example.com');
    await tester.enterText(_field('Password'), 'secret123');
    await tester.enterText(_field('Confirm password'), 'secret123');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign up'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Hello, Nimal'), findsOneWidget);

    // Logging out from Settings returns to the login page.
    await tester.tap(find.byTooltip('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Log out'),
      200,
      scrollable: find
          .descendant(
            of: find.byType(SettingsScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(HomeScreen, skipOffstage: false), findsNothing);
    expect(find.byType(SettingsScreen, skipOffstage: false), findsNothing);

    // Wrong password is rejected, the right one gets in.
    await tester.enterText(_field('Email'), 'nimal@example.com');
    await tester.enterText(_field('Password'), 'wrongpass');
    await tester.tap(logIn);
    await tester.pumpAndSettle();
    expect(find.text('Incorrect email or password.'), findsOneWidget);

    await tester.enterText(_field('Password'), 'secret123');
    await tester.tap(logIn);
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('signup checks the form before creating an account', (
    tester,
  ) async {
    await tester.pumpWidget(
      AuthScope(
        auth: AuthService(),
        child: const MaterialApp(home: SignupScreen()),
      ),
    );

    await tester.enterText(_field('Full name'), 'Nimal');
    await tester.enterText(_field('Email'), 'not-an-email');
    await tester.enterText(_field('Password'), 'short');
    await tester.enterText(_field('Confirm password'), 'different');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign up'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(find.text('Use at least 8 characters.'), findsOneWidget);
    expect(find.text('Passwords do not match.'), findsOneWidget);
  });
}
