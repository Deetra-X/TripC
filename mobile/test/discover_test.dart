import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_app.dart';

Future<void> _pumpHome(WidgetTester tester) => pumpSignedInHome(tester);

Finder get _page => find.byType(Scrollable).first;

void main() {
  testWidgets('shows the greeting and steps through recommendations', (
    tester,
  ) async {
    await _pumpHome(tester);

    expect(find.text('Hello, Nimal'), findsOneWidget);
    expect(find.text('Where should we\ntake you today?'), findsOneWidget);
    expect(find.text('Sigiriya'), findsOneWidget);
    expect(find.textContaining('96% match'), findsOneWidget);

    await tester.ensureVisible(find.text('Next pick'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next pick'));
    await tester.pumpAndSettle();
    expect(find.text('Mirissa Beach'), findsOneWidget);
    expect(find.text('Sigiriya'), findsNothing);
  });

  testWidgets('category chips filter the recommendations', (tester) async {
    await _pumpHome(tester);

    await tester.ensureVisible(find.text('Nature'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nature'));
    await tester.pumpAndSettle();
    expect(find.text('Horton Plains'), findsOneWidget);
    expect(find.text('Next pick'), findsNothing);

    await tester.ensureVisible(find.text('All'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();
    expect(find.text('Sigiriya'), findsOneWidget);
  });

  testWidgets('walk and drive switch the nearby travel times', (tester) async {
    await _pumpHome(tester);

    await tester.scrollUntilVisible(
      find.text('Kandy Lake'),
      300,
      scrollable: _page,
    );
    expect(find.text('5 min'), findsOneWidget);

    await tester.ensureVisible(find.text('Drive'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Drive'));
    await tester.pumpAndSettle();
    expect(find.text('2 min'), findsOneWidget);
    expect(find.text('5 min'), findsNothing);
  });

  testWidgets('the whole page lays out at phone width', (tester) async {
    await _pumpHome(tester);

    await tester.scrollUntilVisible(
      find.text('Nine Arches Bridge'),
      300,
      scrollable: _page,
    );
    expect(find.text('Popular in Sri Lanka'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the nav bar switches tabs', (tester) async {
    await _pumpHome(tester);

    await tester.tap(find.byTooltip('Saved'));
    await tester.pumpAndSettle();
    expect(find.text('Saved places'), findsOneWidget);

    await tester.tap(find.byTooltip('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('nimal@example.com'), findsOneWidget);
    expect(find.text('Log out'), findsOneWidget);
  });
}
