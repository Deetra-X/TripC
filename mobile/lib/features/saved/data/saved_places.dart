import 'package:flutter/widgets.dart';

/// A named group of saved places: Favourites, or a list the user made, such
/// as "Kandy weekend".
@immutable
class SavedList {
  const SavedList({
    required this.id,
    required this.name,
    required this.updatedAt,
    this.placeIds = const [],
  });

  final String id;
  final String name;

  /// Most recently added first.
  final List<String> placeIds;
  final DateTime updatedAt;

  bool get isFavourites => id == SavedPlaces.favouritesId;
  int get count => placeIds.length;

  SavedList copyWith({
    String? name,
    List<String>? placeIds,
    required DateTime updatedAt,
  }) {
    return SavedList(
      id: id,
      name: name ?? this.name,
      placeIds: List.unmodifiable(placeIds ?? this.placeIds),
      updatedAt: updatedAt,
    );
  }
}

/// How the user's own lists are ordered.
enum ListSort {
  lastUpdated('Last updated'),
  name('Name'),
  mostPlaces('Most places');

  const ListSort(this.label);

  final String label;
}

/// The places the user saved, in Favourites and their own lists. Kept in
/// memory for now; it moves to Supabase with the rest of the user's data,
/// one row per list and one per saved place.
class SavedPlaces extends ChangeNotifier {
  SavedPlaces({DateTime Function()? clock}) : _clock = clock ?? DateTime.now {
    _lists[favouritesId] = SavedList(
      id: favouritesId,
      name: 'Favourites',
      updatedAt: _stamp(),
    );
  }

  static const favouritesId = 'favourites';
  static const maxNameLength = 40;

  final DateTime Function() _clock;
  DateTime _lastStamp = DateTime.fromMicrosecondsSinceEpoch(0);
  int _nextId = 1;

  /// In creation order, Favourites first.
  final _lists = <String, SavedList>{};

  /// When each saved place was last added to a list.
  final _savedAt = <String, DateTime>{};

  /// A time later than every earlier one, so changes made in the same
  /// instant still sort in order.
  DateTime _stamp() {
    var now = _clock();
    if (!now.isAfter(_lastStamp)) {
      now = _lastStamp.add(const Duration(microseconds: 1));
    }
    return _lastStamp = now;
  }

  SavedList get favourites => _lists[favouritesId]!;

  /// Favourites, then the user's lists in the order they were made.
  List<SavedList> get lists => List.unmodifiable(_lists.values);

  /// The user's own lists, without Favourites.
  List<SavedList> customLists([ListSort sort = ListSort.lastUpdated]) {
    final lists = _lists.values.where((list) => !list.isFavourites).toList();
    switch (sort) {
      case ListSort.lastUpdated:
        lists.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      case ListSort.name:
        lists.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
      case ListSort.mostPlaces:
        lists.sort((a, b) {
          final bySize = b.count.compareTo(a.count);
          return bySize != 0 ? bySize : b.updatedAt.compareTo(a.updatedAt);
        });
    }
    return lists;
  }

  SavedList? list(String id) => _lists[id];

  bool contains(String listId, String placeId) =>
      _lists[listId]?.placeIds.contains(placeId) ?? false;

  /// Whether the place is in any list.
  bool isSaved(String placeId) => _savedAt.containsKey(placeId);

  /// The lists the place is in, Favourites first.
  List<SavedList> listsWith(String placeId) => [
    for (final list in _lists.values)
      if (list.placeIds.contains(placeId)) list,
  ];

  /// Every saved place once, most recently saved first.
  List<String> get placeIds {
    final ids = _savedAt.keys.toList();
    ids.sort((a, b) => _savedAt[b]!.compareTo(_savedAt[a]!));
    return ids;
  }

  /// Adds the place to the list, at the top unless [index] says otherwise
  /// (e.g. to undo a removal).
  void add(String listId, String placeId, {int index = 0}) {
    final list = _lists[listId];
    if (list == null || list.placeIds.contains(placeId)) return;
    final now = _stamp();
    final ids = [...list.placeIds]
      ..insert(index.clamp(0, list.placeIds.length), placeId);
    _lists[listId] = list.copyWith(placeIds: ids, updatedAt: now);
    _savedAt[placeId] = now;
    notifyListeners();
  }

  void remove(String listId, String placeId) {
    final list = _lists[listId];
    if (list == null || !list.placeIds.contains(placeId)) return;
    _lists[listId] = list.copyWith(
      placeIds: [...list.placeIds]..remove(placeId),
      updatedAt: _stamp(),
    );
    _forgetIfUnsaved(placeId);
    notifyListeners();
  }

  void toggle(String listId, String placeId) => contains(listId, placeId)
      ? remove(listId, placeId)
      : add(listId, placeId);

  /// Whether another list already has this name, ignoring case and spaces
  /// at either end.
  bool nameTaken(String name, {String? exceptId}) {
    final wanted = name.trim().toLowerCase();
    return _lists.values.any(
      (list) => list.id != exceptId && list.name.toLowerCase() == wanted,
    );
  }

  /// Makes a new list, optionally starting with [placeId].
  SavedList createList(String name, {String? placeId}) {
    final trimmed = name.trim();
    assert(trimmed.isNotEmpty && !nameTaken(trimmed));
    final now = _stamp();
    final list = SavedList(
      id: 'list-${_nextId++}',
      name: trimmed,
      placeIds: List.unmodifiable([?placeId]),
      updatedAt: now,
    );
    _lists[list.id] = list;
    if (placeId != null) _savedAt[placeId] = now;
    notifyListeners();
    return list;
  }

  void renameList(String id, String name) {
    final list = _lists[id];
    if (list == null || list.isFavourites) return;
    _lists[id] = list.copyWith(name: name.trim(), updatedAt: _stamp());
    notifyListeners();
  }

  /// Deletes one of the user's lists. Favourites can't be deleted.
  void deleteList(String id) {
    final list = _lists[id];
    if (list == null || list.isFavourites) return;
    _lists.remove(id);
    list.placeIds.forEach(_forgetIfUnsaved);
    notifyListeners();
  }

  void _forgetIfUnsaved(String placeId) {
    if (!_lists.values.any((list) => list.placeIds.contains(placeId))) {
      _savedAt.remove(placeId);
    }
  }
}

class SavedScope extends InheritedNotifier<SavedPlaces> {
  const SavedScope({
    super.key,
    required SavedPlaces saved,
    required super.child,
  }) : super(notifier: saved);

  /// The saved places, rebuilding the caller when they change.
  static SavedPlaces of(BuildContext context) => maybeOf(context)!;

  /// Like [of], but null where there are no saved places, e.g. a map shown
  /// on its own.
  static SavedPlaces? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SavedScope>()?.notifier;

  /// The saved places without rebuilding the caller, e.g. in a tap handler.
  static SavedPlaces read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<SavedScope>()!.notifier!;
}
