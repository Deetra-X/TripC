import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

/// CARTO basemaps key, passed with `--dart-define=CARTO_KEY=...`. With a key
/// the map uses CARTO's Positron and Dark Matter styles; without one it uses
/// OpenStreetMap's standard tiles, recoloured to suit each theme.
const _cartoKey = String.fromEnvironment('CARTO_KEY');

class MapTileStyle {
  const MapTileStyle({
    required this.urlTemplate,
    required this.attribution,
    this.subdomains = const [],
    this.retina = false,
    this.tileBuilder,
  });

  final String urlTemplate;
  final String attribution;
  final List<String> subdomains;
  final bool retina;
  final TileBuilder? tileBuilder;

  static MapTileStyle of({required bool dark}) {
    if (_cartoKey.isNotEmpty) {
      final style = dark ? 'dark_all' : 'light_all';
      return MapTileStyle(
        urlTemplate:
            'https://{s}.basemaps.cartocdn.com/$style/{z}/{x}/{y}{r}.png'
            '?key=$_cartoKey',
        attribution: '© OpenStreetMap contributors © CARTO',
        subdomains: const ['a', 'b', 'c', 'd'],
        retina: true,
      );
    }
    return MapTileStyle(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      attribution: '© OpenStreetMap contributors',
      tileBuilder: dark ? _charcoalTiles : _ivoryTiles,
    );
  }
}

/// Softens OpenStreetMap's colours and warms them towards ivory.
Widget _ivoryTiles(BuildContext context, Widget tile, TileImage image) {
  return ColorFiltered(
    colorFilter: const ColorFilter.matrix([
      0.685, 0.2861, 0.0289, 0, 2, //
      0.0842, 0.8772, 0.0286, 0, 1, //
      0.0821, 0.2761, 0.6069, 0, -1, //
      0, 0, 0, 1, 0, //
    ]),
    child: tile,
  );
}

/// Inverts OpenStreetMap's colours (keeping water blue), then mutes and
/// darkens them to charcoal.
Widget _charcoalTiles(BuildContext context, Widget tile, TileImage image) {
  return ColorFiltered(
    colorFilter: const ColorFilter.matrix([
      0.0485, -0.7528, -0.0757, 0, 208.9, //
      -0.2302, -0.4921, -0.0777, 0, 216.0, //
      -0.236, -0.7914, 0.2074, 0, 222.1, //
      0, 0, 0, 1, 0, //
    ]),
    child: tile,
  );
}
