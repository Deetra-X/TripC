import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tripc/core/auth/auth_service.dart';
import 'package:tripc/core/auth/profile_avatar.dart';
import 'package:tripc/core/theme/theme_controller.dart';
import 'package:tripc/core/widgets/user_avatar.dart';
import 'package:tripc/features/login/auth_gate.dart';
import 'package:tripc/features/login/login_screen.dart';
import 'package:tripc/features/profile/edit_profile_screen.dart';
import 'package:tripc/features/profile/profile_screen.dart';
import 'package:tripc/features/profile/settings_screen.dart';
import 'package:tripc/features/saved/data/saved_places.dart';
import 'package:tripc/features/saved/saved_screen.dart';

import 'test_app.dart';

/// Signs Nimal up (after [others]), opens the app at the login gate and
/// goes to the Profile tab.
Future<AuthService> _openProfile(
  WidgetTester tester, {
  ThemeMode mode = ThemeMode.light,
  List<String> others = const [],
}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

  final auth = AuthService(clock: () => DateTime(2026, 10, 8));
  await tester.runAsync(() async {
    for (final email in others) {
      await auth.signUp(name: 'Other', email: email, password: 'secret456');
    }
    await auth.signUp(
      name: 'Nimal Perera',
      email: 'nimal@example.com',
      password: 'secret123',
    );
  });
  await tester.pumpWidget(
    testApp(
      auth: auth,
      theme: ThemeController()..value = mode,
      home: const AuthGate(),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Profile'));
  await tester.pumpAndSettle();
  return auth;
}

Future<void> _openSettings(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Settings'));
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Scrolls Settings until [finder] is built and on screen, down unless
/// [up].
Future<void> _scrollSettingsTo(
  WidgetTester tester,
  Finder finder, {
  bool up = false,
}) async {
  await tester.scrollUntilVisible(
    finder,
    up ? -200 : 200,
    scrollable: find
        .descendant(
          of: find.byType(SettingsScreen),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.pumpAndSettle();
}

Finder _field(String label) => find.widgetWithText(TextFormField, label);

Finder _stat(String label) => find.byKey(ValueKey('stat-$label'));

Finder _in(Finder parent, Finder child) =>
    find.descendant(of: parent, matching: child);

void main() {
  testWidgets('shows who the user is and what they have saved', (tester) async {
    await _openProfile(tester);

    expect(find.text('Nimal Perera'), findsOneWidget);
    expect(find.text('Member since October 2026'), findsOneWidget);
    expect(find.text("+ Add where you're from"), findsOneWidget);
    expect(_in(_stat('Saved'), find.text('0')), findsOneWidget);

    tester.widget<SavedScope>(find.byType(SavedScope)).notifier!
      ..add(SavedPlaces.favouritesId, '1')
      ..createList('Kandy weekend', placeId: '3');
    await tester.pump();
    expect(_in(_stat('Saved'), find.text('2')), findsOneWidget);
    expect(_in(_stat('List'), find.text('1')), findsOneWidget);

    await tester.tap(_stat('Saved'));
    await tester.pumpAndSettle();
    expect(find.byType(SavedScreen), findsOneWidget);
    expect(find.byType(ProfileScreen), findsNothing);
  });

  testWidgets('interests are chosen and shown as the travel style', (
    tester,
  ) async {
    await _openProfile(tester);

    await _tap(tester, find.text('Choose interests'));
    await tester.tap(find.text('Beaches').last);
    await tester.tap(find.text('Nature').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show my picks'));
    await tester.pumpAndSettle();

    expect(find.text('Beaches'), findsOneWidget);
    expect(find.text('Nature'), findsOneWidget);
    expect(_in(_stat('Interests'), find.text('2')), findsOneWidget);
  });

  testWidgets('edits the picture, name, home and about', (tester) async {
    await _openProfile(tester);
    await _tap(tester, find.text('Edit profile'));
    expect(find.byType(EditProfileScreen), findsOneWidget);

    await tester.enterText(_field('Name'), '  ');
    await _tap(tester, find.text('Save changes'));
    expect(find.text('Enter your name.'), findsOneWidget);

    await tester.enterText(_field('Name'), 'Nimal Silva');
    await tester.enterText(_field("Where you're from"), 'Galle, Sri Lanka');
    await tester.enterText(_field('About you'), 'Always chasing waterfalls.');
    await _tap(tester, find.byTooltip('Hiker'));
    await _tap(tester, find.text('Save changes'));

    expect(find.byType(EditProfileScreen), findsNothing);
    expect(find.text('Profile updated'), findsOneWidget);
    expect(find.text('Nimal Silva'), findsOneWidget);
    expect(find.text('Galle, Sri Lanka'), findsOneWidget);
    expect(find.text('Always chasing waterfalls.'), findsOneWidget);
    final avatar = tester.widget<UserAvatar>(
      _in(find.byType(ProfileScreen), find.byType(UserAvatar)).first,
    );
    expect(avatar.avatar, ProfileAvatar.hiker);

    // The new picture shows on the other tabs too.
    await tester.tap(find.byTooltip('For you'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.hiking_rounded), findsWidgets);
  });

  testWidgets('Settings shows the account and opens Edit profile', (
    tester,
  ) async {
    await _openProfile(tester);
    await _openSettings(tester);

    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.text('nimal@example.com'), findsNWidgets(2));
    for (final title in ['Appearance', 'Profile', 'Account', 'About']) {
      await _scrollSettingsTo(tester, find.text(title));
      expect(find.text(title), findsOneWidget);
    }

    await _scrollSettingsTo(tester, find.text('Nimal Perera'), up: true);
    await _tap(tester, find.text('Nimal Perera'));
    expect(find.byType(EditProfileScreen), findsOneWidget);
  });

  testWidgets('changes the email after checking the password', (tester) async {
    final auth = await _openProfile(tester, others: ['kamala@example.com']);
    await _openSettings(tester);
    await _tap(tester, find.text('Email'));

    await tester.enterText(_field('New email'), 'kamala@example.com');
    await tester.enterText(_field('Password'), 'secret123');
    await _tap(tester, find.text('Save email'));
    expect(
      find.text('An account with this email already exists.'),
      findsOneWidget,
    );

    await tester.enterText(_field('New email'), 'nimal@new.lk');
    await tester.enterText(_field('Password'), 'wrong-password');
    await _tap(tester, find.text('Save email'));
    expect(find.text('Incorrect password.'), findsOneWidget);

    await tester.enterText(_field('Password'), 'secret123');
    await _tap(tester, find.text('Save email'));
    expect(find.text('Email updated'), findsOneWidget);
    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.text('nimal@new.lk'), findsWidgets);
    expect(auth.currentUser!.email, 'nimal@new.lk');
  });

  testWidgets('changes the password after checking the current one', (
    tester,
  ) async {
    await _openProfile(tester);
    await _openSettings(tester);
    await _tap(tester, find.text('Password'));

    await tester.enterText(_field('Current password'), 'secret123');
    await tester.enterText(_field('New password'), 'newsecret1');
    await tester.enterText(_field('Confirm new password'), 'newsecret2');
    await _tap(tester, find.text('Save password'));
    expect(find.text('Passwords do not match.'), findsOneWidget);

    await tester.enterText(_field('Current password'), 'not-it');
    await tester.enterText(_field('Confirm new password'), 'newsecret1');
    await _tap(tester, find.text('Save password'));
    expect(find.text('Incorrect password.'), findsOneWidget);

    await tester.enterText(_field('Current password'), 'secret123');
    await _tap(tester, find.text('Save password'));
    expect(find.text('Password changed'), findsOneWidget);
    expect(find.byType(SettingsScreen), findsOneWidget);
  });

  testWidgets('deletes the account once the password is confirmed', (
    tester,
  ) async {
    final auth = await _openProfile(tester);
    await _openSettings(tester);
    await _scrollSettingsTo(tester, find.text('Delete account'));
    await _tap(tester, find.text('Delete account'));
    expect(find.text('Delete your account?'), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Enter your password.'), findsOneWidget);

    final password = _in(find.byType(AlertDialog), find.byType(TextFormField));
    await tester.enterText(password, 'wrong-password');
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Incorrect password.'), findsOneWidget);
    expect(auth.isSignedIn, isTrue);

    await tester.enterText(password, 'secret123');
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(auth.isSignedIn, isFalse);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(SettingsScreen, skipOffstage: false), findsNothing);
  });

  testWidgets('cancelling the deletion keeps the account', (tester) async {
    final auth = await _openProfile(tester);
    await _openSettings(tester);
    await _scrollSettingsTo(tester, find.text('Delete account'));
    await _tap(tester, find.text('Delete account'));
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(auth.isSignedIn, isTrue);
    expect(find.byType(SettingsScreen), findsOneWidget);
  });

  testWidgets('Profile and Settings lay out in dark mode', (tester) async {
    await _openProfile(tester, mode: ThemeMode.dark);
    expect(tester.takeException(), isNull);

    await _openSettings(tester);
    expect(find.text('NIGHT MODE'), findsOneWidget);
    await _scrollSettingsTo(tester, find.text('Delete account'));
    expect(tester.takeException(), isNull);
  });
}
