import 'package:flutter/material.dart';

import '../../core/auth/auth_service.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/theme_context.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/profile_button.dart';
import '../discover/widgets/section_header.dart';
import '../for_you/data/taste_profile.dart';
import '../map/data/attraction.dart';
import '../map/data/attraction_repository.dart';
import '../map/map_dependencies.dart';
import 'data/saved_places.dart';
import 'saved_list_screen.dart';
import 'widgets/list_card.dart';
import 'widgets/list_name_dialog.dart';
import 'widgets/saved_empty_state.dart';
import 'widgets/saved_place_row.dart';

/// The user's saved places: Recently viewed, Favourites and the lists they
/// make, or every saved place in one list.
class SavedScreen extends StatefulWidget {
  const SavedScreen({
    super.key,
    required this.onOpenPlace,
    required this.onExplore,
    required this.onOpenProfile,
  });

  /// Shows the place on the map, with its route.
  final ValueChanged<Attraction> onOpenPlace;

  /// Goes to the map to find places to save.
  final VoidCallback onExplore;
  final VoidCallback onOpenProfile;

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen>
    with SingleTickerProviderStateMixin {
  late final _tabs = TabController(length: 2, vsync: this)
    ..addListener(() => setState(() {}));

  late AttractionRepository _repository;
  bool _initialised = false;

  /// Every place, by id.
  Map<String, Attraction> _places = const {};
  bool _loading = true;
  bool _failed = false;

  ListSort _sort = ListSort.lastUpdated;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialised) return;
    _initialised = true;
    _repository =
        MapDependencies.maybeOf(context)?.attractions ??
        const AssetAttractionRepository();
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final places = await _repository.fetchAll();
      if (!mounted) return;
      setState(() {
        _places = {for (final place in places) place.id: place};
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  /// The places for [ids] that are still in the data, in the same order.
  List<Attraction> _resolve(Iterable<String> ids) => [
    for (final id in ids) ?_places[id],
  ];

  Future<void> _newList() async {
    final saved = SavedScope.read(context);
    final name = await showListNameDialog(context, saved: saved);
    if (name != null) saved.createList(name);
  }

  /// Opens a list, or Recently viewed when [listId] is null.
  void _openList(String? listId) {
    final saved = SavedScope.read(context);
    final taste = TasteScope.maybeOf(context)!;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        // The page sits above the tabs, so it gets the user's data again.
        builder: (_) => TasteScope(
          profile: taste,
          child: SavedScope(
            saved: saved,
            child: SavedListScreen(
              listId: listId,
              places: _places,
              onOpenPlace: widget.onOpenPlace,
              onExplore: widget.onExplore,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final saved = SavedScope.of(context);
    final taste = TasteScope.of(context);
    final user = AuthScope.of(context).currentUser!;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.only(top: AppSpace.lg, bottom: 120),
        children: [
          _Header(
            user: user,
            onNewList: _newList,
            onOpenProfile: widget.onOpenProfile,
          ),
          const SizedBox(height: AppSpace.md),
          _Tabs(controller: _tabs),
          const SizedBox(height: AppSpace.xl),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(AppSpace.huge),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_failed)
            _LoadError(onRetry: _load)
          else if (_tabs.index == 0)
            ..._lists(saved, taste)
          else
            ..._allPlaces(saved),
        ],
      ),
    );
  }

  List<Widget> _lists(SavedPlaces saved, TasteProfile taste) {
    final custom = saved.customLists(_sort);
    return [
      _Grid(
        children: [
          ListCard(
            key: const ValueKey('list-recent'),
            title: 'Recently viewed',
            places: _resolve(taste.recentlyViewed),
            emptyIcon: Icons.history_rounded,
            onTap: () => _openList(null),
          ),
          ListCard(
            key: const ValueKey('list-${SavedPlaces.favouritesId}'),
            title: saved.favourites.name,
            places: _resolve(saved.favourites.placeIds),
            emptyIcon: Icons.favorite_border_rounded,
            onTap: () => _openList(SavedPlaces.favouritesId),
          ),
        ],
      ),
      const SizedBox(height: AppSpace.xxxl),
      SectionHeader(
        title: 'Your lists',
        subtitle: 'Plan trips and group places your way',
        trailing: custom.length > 1
            ? _SortMenu(
                sort: _sort,
                onChanged: (sort) => setState(() => _sort = sort),
              )
            : null,
      ),
      const SizedBox(height: AppSpace.lg),
      if (custom.isEmpty)
        _ListsPrompt(onNewList: _newList)
      else
        _Grid(
          children: [
            for (final list in custom)
              ListCard(
                key: ValueKey('list-${list.id}'),
                title: list.name,
                places: _resolve(list.placeIds),
                emptyIcon: Icons.bookmarks_outlined,
                onTap: () => _openList(list.id),
              ),
            NewListCard(onTap: _newList),
          ],
        ),
    ];
  }

  List<Widget> _allPlaces(SavedPlaces saved) {
    final places = _resolve(saved.placeIds);
    if (places.isEmpty) {
      return [
        SavedEmptyState(
          icon: Icons.favorite_border_rounded,
          title: 'No saved places yet',
          message:
              'Tap the heart on any place on the map to keep it in '
              'Favourites or one of your lists.',
          actionLabel: 'Explore the map',
          onAction: widget.onExplore,
        ),
      ];
    }
    final colors = context.colors;
    return [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text(
          '${placeCount(places.length)} saved',
          style: context.text.labelMedium?.copyWith(
            color: colors.textSecondary,
          ),
        ),
      ),
      const SizedBox(height: AppSpace.xs),
      for (var i = 0; i < places.length; i++) ...[
        if (i > 0)
          Divider(height: 1, indent: 20, endIndent: 20, color: colors.hairline),
        SavedPlaceRow(
          key: ValueKey('saved-${places[i].id}'),
          place: places[i],
          note:
              'In ${saved.listsWith(places[i].id).map((l) => l.name).join(', ')}',
          onTap: () => widget.onOpenPlace(places[i]),
        ),
      ],
    ];
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.user,
    required this.onNewList,
    required this.onOpenProfile,
  });

  final AuthUser user;
  final VoidCallback onNewList;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(child: Text('Saved', style: context.text.displaySmall)),
          IconButton(
            tooltip: 'New list',
            onPressed: onNewList,
            style: IconButton.styleFrom(
              fixedSize: const Size.square(48),
              backgroundColor: colors.surfaceRaised,
              side: BorderSide(color: colors.hairline),
            ),
            icon: Icon(Icons.add_rounded, color: colors.textPrimary),
          ),
          const SizedBox(width: AppSpace.sm),
          ProfileButton(user: user, onTap: onOpenProfile),
        ],
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.controller});

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return TabBar(
      controller: controller,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      padding: const EdgeInsets.only(left: 20),
      labelPadding: const EdgeInsets.only(right: 28),
      labelColor: colors.textPrimary,
      unselectedLabelColor: colors.textSecondary,
      labelStyle: context.text.titleMedium,
      unselectedLabelStyle: context.text.titleMedium,
      indicatorColor: colors.brand,
      indicatorSize: TabBarIndicatorSize.label,
      indicatorWeight: 2.5,
      dividerColor: colors.hairline,
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      tabs: const [
        Tab(text: 'Lists'),
        Tab(text: 'Places'),
      ],
    );
  }
}

/// Two columns of list cards.
class _Grid extends StatelessWidget {
  const _Grid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    const gap = AppSpace.lg;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = (constraints.maxWidth - gap) / 2;
          return Wrap(
            spacing: gap,
            runSpacing: AppSpace.xl,
            children: [
              for (final child in children)
                SizedBox(width: width, child: child),
            ],
          );
        },
      ),
    );
  }
}

class _SortMenu extends StatelessWidget {
  const _SortMenu({required this.sort, required this.onChanged});

  final ListSort sort;
  final ValueChanged<ListSort> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return PopupMenuButton<ListSort>(
      tooltip: 'Sort lists',
      initialValue: sort,
      onSelected: onChanged,
      itemBuilder: (_) => [
        for (final option in ListSort.values)
          PopupMenuItem(value: option, child: Text(option.label)),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              sort.label,
              style: context.text.labelLarge?.copyWith(color: colors.brand),
            ),
            Icon(Icons.expand_more_rounded, size: 20, color: colors.brand),
          ],
        ),
      ),
    );
  }
}

/// Shown until the user makes a list of their own.
class _ListsPrompt extends StatelessWidget {
  const _ListsPrompt({required this.onNewList});

  final VoidCallback onNewList;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Glass(
        opacity: 0.7,
        borderRadius: BorderRadius.circular(AppRadius.md),
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colors.brandSoft,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(Icons.bookmarks_outlined, color: colors.brand),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Plan a trip', style: context.text.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    'Group places into lists, like a Kandy weekend or beach '
                    'days down south.',
                    style: TextStyle(color: colors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            TextButton(onPressed: onNewList, child: const Text('New list')),
          ],
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpace.xxl),
      child: Column(
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: 32,
            color: context.colors.textTertiary,
          ),
          const SizedBox(height: AppSpace.md),
          Text(
            "Couldn't load your places",
            style: TextStyle(color: context.colors.textSecondary),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
