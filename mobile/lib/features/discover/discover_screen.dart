import 'package:flutter/material.dart';

import '../../core/auth/auth_service.dart';
import 'discover_data.dart';
import 'widgets/category_chips.dart';
import 'widgets/discover_header.dart';
import 'widgets/near_you_section.dart';
import 'widgets/popular_row.dart';
import 'widgets/recommendation_deck.dart';
import 'widgets/search_row.dart';
import 'widgets/section_header.dart';

/// The home screen: personalised picks, places nearby and popular spots.
class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key, this.onOpenMap});

  /// Opens the full map, e.g. by switching to the Map tab.
  final VoidCallback? onOpenMap;

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  PlaceCategory? _category;

  void _comingSoon() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Coming soon'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthScope.of(context).currentUser!;
    final picks = _category == null
        ? recommendations
        : recommendations.where((r) => r.category == _category).toList();

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.only(top: 12, bottom: 120),
        children: [
          DiscoverHeader(
            firstName: user.name.split(' ').first,
            onNotifications: _comingSoon,
          ),
          const SizedBox(height: 20),
          SearchRow(onVoice: _comingSoon, onFilters: _comingSoon),
          const SizedBox(height: 28),
          SectionHeader(title: 'Recommended for you', onSeeAll: _comingSoon),
          const SizedBox(height: 12),
          CategoryChips(
            selected: _category,
            onSelected: (category) => setState(() => _category = category),
          ),
          const SizedBox(height: 18),
          RecommendationDeck(
            key: ValueKey(_category),
            items: picks,
            onView: (_) => _comingSoon(),
          ),
          const SizedBox(height: 32),
          NearYouSection(
            places: nearbyPlaces,
            onOpenMap: widget.onOpenMap ?? _comingSoon,
            onOpenPlace: (_) => _comingSoon(),
          ),
          const SizedBox(height: 24),
          SectionHeader(title: 'Popular in Sri Lanka', onSeeAll: _comingSoon),
          const SizedBox(height: 14),
          PopularRow(places: popularPlaces, onOpen: (_) => _comingSoon()),
        ],
      ),
    );
  }
}
