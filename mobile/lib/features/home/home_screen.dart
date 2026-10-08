import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/theme_context.dart';
import '../../core/widgets/ambient_background.dart';
import '../discover/discover_screen.dart';
import '../for_you/data/taste_profile.dart';
import '../for_you/for_you_screen.dart';
import '../map/data/attraction.dart';
import '../map/map_screen.dart';
import '../profile/profile_screen.dart';
import '../saved/data/saved_places.dart';
import '../saved/saved_screen.dart';
import 'widgets/glass_nav_bar.dart';

/// The signed-in app: tabs behind a floating glass navigation bar.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _tabs = [
    GlassNavItem(icon: Icons.explore_outlined, label: 'Discover'),
    GlassNavItem(icon: Icons.auto_awesome_outlined, label: 'For you'),
    GlassNavItem(icon: Icons.map_outlined, label: 'Map'),
    GlassNavItem(icon: Icons.favorite_border_rounded, label: 'Saved'),
    GlassNavItem(icon: Icons.person_outline_rounded, label: 'Profile'),
  ];

  static const _mapTab = 2;
  static const _savedTab = 3;
  static const _profileTab = 4;

  int _tab = 0;

  /// Tabs are built the first time they are opened, so the map only asks
  /// for location once the user goes to it.
  final _opened = <int>{0};

  /// The user's interests and recent views, shared by For You, the map and
  /// Saved.
  final _taste = TasteProfile();

  /// Favourites and the user's lists.
  final _saved = SavedPlaces();

  /// A place to show on the map, e.g. one picked on For You.
  final _mapFocus = ValueNotifier<Attraction?>(null);

  @override
  void dispose() {
    _taste.dispose();
    _saved.dispose();
    _mapFocus.dispose();
    super.dispose();
  }

  void _openTab(int tab) => setState(() {
    _tab = tab;
    _opened.add(tab);
  });

  void _openOnMap(Attraction place) {
    _mapFocus.value = place;
    _openTab(_mapTab);
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      DiscoverScreen(onOpenMap: () => _openTab(_mapTab)),
      ForYouScreen(
        onOpenPlace: _openOnMap,
        onOpenProfile: () => _openTab(_profileTab),
      ),
      MapScreen(focus: _mapFocus),
      SavedScreen(
        onOpenPlace: _openOnMap,
        onExplore: () => _openTab(_mapTab),
        onOpenProfile: () => _openTab(_profileTab),
      ),
      ProfileScreen(onOpenSaved: () => _openTab(_savedTab)),
    ];

    return TasteScope(
      profile: _taste,
      child: SavedScope(
        saved: _saved,
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: context.overlayStyle,
          child: Scaffold(
            extendBody: true,
            body: Stack(
              fit: StackFit.expand,
              children: [
                const AmbientBackground(),
                IndexedStack(
                  index: _tab,
                  children: [
                    for (var i = 0; i < tabs.length; i++)
                      _opened.contains(i) ? tabs[i] : const SizedBox.shrink(),
                  ],
                ),
              ],
            ),
            bottomNavigationBar: GlassNavBar(
              items: _tabs,
              index: _tab,
              onSelected: _openTab,
            ),
          ),
        ),
      ),
    );
  }
}
