import 'dart:convert';

import 'package:flutter/services.dart';

import 'attraction.dart';

/// Where the map gets its places. [AssetAttractionRepository] reads the
/// spreadsheet export; a Supabase-backed repository can replace it without
/// changing the map, since both read rows with [Attraction.fromMap].
abstract interface class AttractionRepository {
  Future<List<Attraction>> fetchAll();
}

/// Places exported from the spreadsheet by `tool/export_places.py`.
class AssetAttractionRepository implements AttractionRepository {
  const AssetAttractionRepository({
    this.path = 'assets/data/places.json',
    this.bundle,
  });

  final String path;
  final AssetBundle? bundle;

  @override
  Future<List<Attraction>> fetchAll() async {
    final json = await (bundle ?? rootBundle).loadString(path);
    final rows = (jsonDecode(json) as List).cast<Map<String, Object?>>();
    return parsePlaces(rows);
  }
}

/// Parses place rows, giving repeated IDs a suffix ("289-2") so every place
/// can still be selected on its own.
List<Attraction> parsePlaces(Iterable<Map<String, Object?>> rows) {
  final seen = <String, int>{};
  return [
    for (final row in rows)
      () {
        final place = Attraction.fromMap(row);
        final count = seen.update(place.id, (n) => n + 1, ifAbsent: () => 1);
        return count == 1
            ? place
            : Attraction.fromMap({...row, 'place_id': '${place.id}-$count'});
      }(),
  ];
}
