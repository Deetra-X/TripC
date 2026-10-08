import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tripc/features/for_you/data/taste_profile.dart';
import 'package:tripc/features/map/map_screen.dart';
import 'package:tripc/features/saved/data/saved_places.dart';
import 'package:tripc/features/saved/saved_list_screen.dart';
import 'package:tripc/features/saved/saved_screen.dart';
import 'package:tripc/features/saved/widgets/list_card.dart';
import 'package:tripc/features/saved/widgets/save_button.dart';

import 'test_app.dart';

SavedPlaces _saved(WidgetTester tester) =>
    tester.widget<SavedScope>(find.byType(SavedScope).first).notifier!;

TasteProfile _taste(WidgetTester tester) =>
    tester.widget<TasteScope>(find.byType(TasteScope).first).notifier!;

Future<void> _openSaved(
  WidgetTester tester, {
  ThemeMode mode = ThemeMode.light,
}) async {
  await pumpSignedInHome(tester, mode: mode);
  await tester.tap(find.byTooltip('Saved'));
  await tester.pumpAndSettle();
}

Finder _card(String id) => find.byKey(ValueKey('list-$id'));

Finder _in(Finder parent, Finder child) =>
    find.descendant(of: parent, matching: child);

Finder get _page =>
    _in(find.byType(SavedScreen), find.byType(Scrollable)).first;

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  group('saved places', () {
    test('start with an empty Favourites list that always stays', () {
      final saved = SavedPlaces();
      expect(saved.lists.single.name, 'Favourites');
      expect(saved.favourites.placeIds, isEmpty);

      saved
        ..deleteList(SavedPlaces.favouritesId)
        ..renameList(SavedPlaces.favouritesId, 'Likes');
      expect(saved.favourites.name, 'Favourites');
    });

    test('add, remove and toggle places, newest first', () {
      final saved = SavedPlaces();
      var changes = 0;
      saved.addListener(() => changes++);

      saved
        ..add(SavedPlaces.favouritesId, '1')
        ..add(SavedPlaces.favouritesId, '2')
        ..add(SavedPlaces.favouritesId, '2');
      expect(saved.favourites.placeIds, ['2', '1']);
      expect(saved.isSaved('1'), isTrue);
      expect(changes, 2);

      saved.toggle(SavedPlaces.favouritesId, '1');
      expect(saved.isSaved('1'), isFalse);
      saved.toggle(SavedPlaces.favouritesId, '1');
      expect(saved.favourites.placeIds, ['1', '2']);

      // Undoing a removal puts the place back where it was.
      saved
        ..remove(SavedPlaces.favouritesId, '2')
        ..add(SavedPlaces.favouritesId, '2', index: 1);
      expect(saved.favourites.placeIds, ['1', '2']);
    });

    test('a place stays saved while any list has it', () {
      final saved = SavedPlaces();
      final trip = saved.createList('Kandy weekend', placeId: '1');
      saved.add(SavedPlaces.favouritesId, '1');

      expect(saved.listsWith('1').map((l) => l.name), [
        'Favourites',
        'Kandy weekend',
      ]);
      saved.remove(SavedPlaces.favouritesId, '1');
      expect(saved.isSaved('1'), isTrue);
      saved.deleteList(trip.id);
      expect(saved.isSaved('1'), isFalse);
      expect(saved.placeIds, isEmpty);
    });

    test('every saved place is listed once, most recently saved first', () {
      final saved = SavedPlaces();
      final trip = saved.createList('Trip', placeId: '1');
      saved
        ..add(SavedPlaces.favouritesId, '2')
        ..add(trip.id, '2')
        ..add(SavedPlaces.favouritesId, '3');
      expect(saved.placeIds, ['3', '2', '1']);
    });

    test('list names must be new, ignoring case and spaces', () {
      final saved = SavedPlaces();
      final trip = saved.createList('  Beach days ');
      expect(trip.name, 'Beach days');
      expect(saved.nameTaken('beach DAYS '), isTrue);
      expect(saved.nameTaken('favourites'), isTrue);
      expect(saved.nameTaken('Beach days', exceptId: trip.id), isFalse);
      expect(saved.nameTaken('Hill country'), isFalse);

      saved.renameList(trip.id, ' South coast ');
      expect(saved.list(trip.id)!.name, 'South coast');
    });

    test("the user's lists sort by last change, name or size", () {
      // A clock that never moves: changes still sort in the order made.
      final saved = SavedPlaces(clock: () => DateTime(2026, 10, 8));
      final ancient = saved.createList('Ancient cities', placeId: '1');
      saved.add(ancient.id, '3');
      final zoo = saved.createList('Zoo trips', placeId: '5');
      final hills = saved.createList('hill country');

      List<String> names(ListSort sort) => [
        for (final list in saved.customLists(sort)) list.name,
      ];
      expect(names(ListSort.lastUpdated), [
        'hill country',
        'Zoo trips',
        'Ancient cities',
      ]);
      expect(names(ListSort.name), [
        'Ancient cities',
        'hill country',
        'Zoo trips',
      ]);
      expect(names(ListSort.mostPlaces), [
        'Ancient cities',
        'Zoo trips',
        'hill country',
      ]);

      saved.add(zoo.id, '4');
      expect(names(ListSort.lastUpdated).first, 'Zoo trips');
      saved.renameList(hills.id, 'Hill country');
      expect(names(ListSort.lastUpdated).first, 'Hill country');
    });
  });

  testWidgets('shows Recently viewed, Favourites and how to make lists', (
    tester,
  ) async {
    await _openSaved(tester);

    expect(find.text('Saved'), findsWidgets);
    expect(_in(_card('recent'), find.text('Recently viewed')), findsOneWidget);
    expect(_in(_card('favourites'), find.text('Favourites')), findsOneWidget);
    expect(find.text('Nothing yet'), findsNWidgets(2));
    expect(find.text('Plan a trip'), findsOneWidget);
  });

  testWidgets('saves a place from the map to Favourites and a new list', (
    tester,
  ) async {
    await pumpSignedInHome(tester, mode: ThemeMode.light);
    await tester.tap(find.byTooltip('Map'));
    await tester.pumpAndSettle();
    await tester.tap(_in(find.byType(MapScreen), find.byType(TextField)));
    await tester.pumpAndSettle();
    await _tap(tester, find.byKey(const ValueKey('place-5')));

    await tester.tap(find.byTooltip('Save'));
    await tester.pumpAndSettle();
    final sheet = find.byType(BottomSheet);
    expect(_in(sheet, find.text('Save to a list')), findsOneWidget);
    expect(_in(sheet, find.text('Arugam Bay')), findsOneWidget);

    final favourites = find.byKey(const ValueKey('option-favourites'));
    await tester.tap(favourites);
    await tester.pumpAndSettle();
    expect(
      _in(favourites, find.byIcon(Icons.check_circle_rounded)),
      findsOneWidget,
    );

    await tester.tap(_in(sheet, find.text('New list')));
    await tester.pumpAndSettle();
    await tester.enterText(
      _in(find.byType(AlertDialog), find.byType(TextFormField)),
      'Beach days',
    );
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();
    expect(
      _in(
        find.byKey(const ValueKey('option-list-1')),
        find.byIcon(Icons.check_circle_rounded),
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    final heart = tester.widget<IconButton>(
      _in(find.byType(SaveButton), find.byType(IconButton)),
    );
    expect(heart.isSelected, isTrue);

    await tester.tap(find.byTooltip('Saved'));
    await tester.pumpAndSettle();
    expect(_in(_card('favourites'), find.text('1 place')), findsOneWidget);
    // Opening it on the map counts as a view.
    expect(_in(_card('recent'), find.text('1 place')), findsOneWidget);
    await tester.scrollUntilVisible(_card('list-1'), 200, scrollable: _page);
    expect(_in(_card('list-1'), find.text('Beach days')), findsOneWidget);
    expect(_in(_card('list-1'), find.text('1 place')), findsOneWidget);
  });

  testWidgets('a saved place opens on the map', (tester) async {
    await _openSaved(tester);
    _saved(tester).add(SavedPlaces.favouritesId, '5');
    await tester.pump();

    await _tap(tester, _card('favourites'));
    expect(find.byType(SavedListScreen), findsOneWidget);
    expect(find.text('1 place'), findsOneWidget);

    await tester.tap(
      _in(find.byKey(const ValueKey('row-5')), find.text('Arugam Bay')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(SavedListScreen), findsNothing);
    expect(find.byType(MapScreen), findsOneWidget);
    expect(find.text('By road'), findsOneWidget);
  });

  testWidgets('makes, renames and deletes a list', (tester) async {
    await _openSaved(tester);

    await tester.tap(find.byTooltip('New list'));
    await tester.pumpAndSettle();
    final field = _in(find.byType(AlertDialog), find.byType(TextFormField));
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();
    expect(find.text('Give your list a name'), findsOneWidget);
    await tester.enterText(field, ' favourites ');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();
    expect(
      find.text('You already have a list called "favourites"'),
      findsOneWidget,
    );
    await tester.enterText(field, 'Beach days');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Plan a trip'), findsNothing);
    await _tap(tester, _card('list-1'));
    expect(find.text('Beach days'), findsOneWidget);
    expect(find.text('Nothing here yet'), findsOneWidget);

    await tester.tap(find.byTooltip('List options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();
    await tester.enterText(
      _in(find.byType(AlertDialog), find.byType(TextFormField)),
      'South coast',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('South coast'), findsOneWidget);

    await tester.tap(find.byTooltip('List options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete list'));
    await tester.pumpAndSettle();
    expect(find.text('Delete "South coast"?'), findsOneWidget);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.byType(SavedListScreen), findsNothing);
    expect(find.text('South coast'), findsNothing);
    expect(find.text('Plan a trip'), findsOneWidget);
    expect(_saved(tester).customLists(), isEmpty);
  });

  testWidgets('swiping a place out of a list can be undone', (tester) async {
    await _openSaved(tester);
    _saved(tester)
      ..add(SavedPlaces.favouritesId, '1')
      ..add(SavedPlaces.favouritesId, '3');
    await tester.pump();
    await _tap(tester, _card('favourites'));

    await tester.drag(
      find.byKey(const ValueKey('row-3')),
      const Offset(-500, 0),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('row-3')), findsNothing);
    expect(find.text('Removed from Favourites'), findsOneWidget);
    expect(find.text('1 place'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(_saved(tester).favourites.placeIds, ['3', '1']);
    expect(find.byKey(const ValueKey('row-3')), findsOneWidget);
  });

  testWidgets('Recently viewed lists views and can be cleared', (tester) async {
    await _openSaved(tester);
    _taste(tester)
      ..viewed('3')
      ..viewed('6');
    await tester.pump();
    expect(_in(_card('recent'), find.text('2 places')), findsOneWidget);

    await _tap(tester, _card('recent'));
    final first = tester.getTopLeft(find.byKey(const ValueKey('row-6')));
    final second = tester.getTopLeft(find.byKey(const ValueKey('row-3')));
    expect(first.dy, lessThan(second.dy));
    // Views can't be swiped away, only cleared.
    expect(find.byType(Dismissible), findsNothing);

    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();
    expect(find.text('Nothing here yet'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(_taste(tester).recentlyViewed, ['6', '3']);
  });

  testWidgets('Places shows every saved place and its lists', (tester) async {
    await _openSaved(tester);
    final tabs = find.byType(TabBar);

    await tester.tap(_in(tabs, find.text('Places')));
    await tester.pumpAndSettle();
    expect(find.text('No saved places yet'), findsOneWidget);

    final saved = _saved(tester);
    saved
      ..add(SavedPlaces.favouritesId, '1')
      ..createList('Kandy weekend', placeId: '1')
      ..add('list-1', '3');
    await tester.pump();

    expect(find.text('2 places saved'), findsOneWidget);
    expect(
      _in(
        find.byKey(const ValueKey('saved-1')),
        find.text('In Favourites, Kandy weekend'),
      ),
      findsOneWidget,
    );
    expect(
      _in(find.byKey(const ValueKey('saved-3')), find.text('In Kandy weekend')),
      findsOneWidget,
    );
    // Most recently saved first.
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('saved-3'))).dy,
      lessThan(tester.getTopLeft(find.byKey(const ValueKey('saved-1'))).dy),
    );
  });

  testWidgets('with nothing saved, Explore the map goes to the map', (
    tester,
  ) async {
    await _openSaved(tester);
    await tester.tap(_in(find.byType(TabBar), find.text('Places')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Explore the map'));
    await tester.pumpAndSettle();
    expect(find.byType(MapScreen), findsOneWidget);
    expect(find.byType(SavedScreen), findsNothing);
  });

  testWidgets('the sort menu reorders your lists', (tester) async {
    await _openSaved(tester);
    _saved(tester)
      ..createList('Ancient cities', placeId: '1')
      ..createList('Zoo trips', placeId: '5')
      ..add('list-2', '4');
    await tester.pump();

    // The two lists share a row, so the first is on the left.
    double x(String id) => tester.getTopLeft(_card(id)).dx;
    await tester.scrollUntilVisible(_card('list-1'), 200, scrollable: _page);
    expect(x('list-2'), lessThan(x('list-1')));

    await _tap(tester, find.byTooltip('Sort lists'));
    await tester.tap(find.text('Name').last);
    await tester.pumpAndSettle();
    expect(x('list-1'), lessThan(x('list-2')));

    await _tap(tester, find.byTooltip('Sort lists'));
    await tester.tap(find.text('Most places').last);
    await tester.pumpAndSettle();
    expect(x('list-2'), lessThan(x('list-1')));
  });

  testWidgets('lays out in dark mode', (tester) async {
    await _openSaved(tester, mode: ThemeMode.dark);
    _saved(tester)
      ..add(SavedPlaces.favouritesId, '1')
      ..add(SavedPlaces.favouritesId, '3')
      ..add(SavedPlaces.favouritesId, '4')
      ..add(SavedPlaces.favouritesId, '6')
      ..createList('Kandy weekend', placeId: '1');
    _taste(tester).viewed('5');
    await tester.pump();

    await tester.scrollUntilVisible(
      find.byType(NewListCard),
      200,
      scrollable: _page,
    );
    expect(tester.takeException(), isNull);
    await _tap(tester, _card('favourites'));
    expect(find.text('4 places'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
