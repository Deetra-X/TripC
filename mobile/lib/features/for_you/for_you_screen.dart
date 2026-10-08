import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../core/auth/auth_service.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/theme_context.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/profile_button.dart';
import '../discover/widgets/section_header.dart';
import '../map/data/attraction.dart';
import '../map/data/attraction_repository.dart';
import '../map/data/trip_estimate.dart';
import '../map/location/location_service.dart';
import '../map/map_dependencies.dart';
import '../map/routing/route_service.dart';
import 'context/weather_service.dart';
import 'data/taste_profile.dart';
import 'recommendation/recommender.dart';
import 'widgets/how_picks_work.dart';
import 'widgets/interest_picker.dart';
import 'widgets/pick_widgets.dart';
import 'widgets/why_this_pick.dart';

/// Personal recommendations: places ranked for the user's interests, where
/// they are, the weather and the time of day.
class ForYouScreen extends StatefulWidget {
  const ForYouScreen({
    super.key,
    required this.onOpenPlace,
    required this.onOpenProfile,
  });

  /// Shows the place on the map, with its route.
  final ValueChanged<Attraction> onOpenPlace;
  final VoidCallback onOpenProfile;

  @override
  State<ForYouScreen> createState() => _ForYouScreenState();
}

class _ForYouScreenState extends State<ForYouScreen> {
  static const _recommender = Recommender();

  late AttractionRepository _repository;
  late LocationService _location;
  late RouteService _routes;
  late WeatherService _weatherService;
  bool _initialised = false;

  List<Attraction> _places = const [];
  bool _loading = true;
  bool _failed = false;

  Map<String, double> _roadMeters = const {};
  LatLng? _distancesFrom;
  DateTime? _distancesFailedAt;

  Weather? _weather;
  LatLng? _weatherFrom;
  DateTime? _weatherFailedAt;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialised) return;
    _initialised = true;
    final dependencies = MapDependencies.maybeOf(context);
    _repository =
        dependencies?.attractions ?? const AssetAttractionRepository();
    _location = (dependencies?.createLocation ?? DeviceLocationService.new)()
      ..addListener(_onLocationChanged);
    _routes = dependencies?.routes ?? OsrmRouteService.shared;
    _weatherService = dependencies?.weather ?? OpenMeteoWeatherService.shared;
    _load();
    _location.start();
  }

  @override
  void dispose() {
    _location
      ..removeListener(_onLocationChanged)
      ..dispose();
    super.dispose();
  }

  List<Attraction> get _mapped => [
    for (final place in _places)
      if (place.location != null) place,
  ];

  void _onLocationChanged() {
    setState(() {});
    final user = _location.value.position;
    if (user == null) return;
    if (_distancesFrom == null ||
        _metersBetween(_distancesFrom!, user) > 1000) {
      _updateDistances();
    }
    if (_weatherFrom == null || _metersBetween(_weatherFrom!, user) > 5000) {
      _updateWeather();
    }
  }

  static double _metersBetween(LatLng a, LatLng b) =>
      TripEstimate.between(a, b).meters;

  static bool _recentlyFailed(DateTime? at) =>
      at != null && DateTime.now().difference(at) < const Duration(minutes: 1);

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final places = await _repository.fetchAll();
      if (!mounted) return;
      setState(() {
        _places = places;
        _loading = false;
      });
      _updateDistances();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  Future<void> _updateDistances() async {
    final user = _location.value.position;
    final places = _mapped;
    if (user == null || places.isEmpty) return;
    if (_recentlyFailed(_distancesFailedAt)) return;
    _distancesFrom = user;
    try {
      final distances = await _routes.distances(user, [
        for (final place in places) place.location!,
      ], TravelMode.drive);
      if (!mounted) return;
      setState(() {
        _roadMeters = {
          for (var i = 0; i < places.length; i++)
            if (distances[i] case final road?) places[i].id: road.meters,
        };
      });
    } catch (_) {
      _distancesFrom = null;
      _distancesFailedAt = DateTime.now();
    }
  }

  Future<void> _updateWeather() async {
    final user = _location.value.position;
    if (user == null || _recentlyFailed(_weatherFailedAt)) return;
    _weatherFrom = user;
    try {
      final weather = await _weatherService.current(user);
      if (mounted) setState(() => _weather = weather);
    } catch (_) {
      // Recommendations still work without weather.
      _weatherFrom = null;
      _weatherFailedAt = DateTime.now();
    }
  }

  Future<void> _chooseInterests(TasteProfile taste) async {
    final chosen = await showInterestPicker(context, taste.interests);
    if (chosen != null) taste.setInterests(chosen);
  }

  /// The district of the nearest place, as a name for where the user is.
  String? _area(LatLng? user) {
    if (user == null) return null;
    Attraction? nearest;
    var best = double.infinity;
    for (final place in _mapped) {
      final meters = _metersBetween(user, place.location!);
      if (meters < best && place.district.isNotEmpty) {
        best = meters;
        nearest = place;
      }
    }
    return nearest?.district;
  }

  @override
  Widget build(BuildContext context) {
    final taste = TasteScope.of(context);
    final user = AuthScope.of(context).currentUser!;
    final position = _location.value.position;
    final now = DateTime.now();

    final ranked = _recommender.rank(
      _mapped,
      taste.interests,
      RecommendationContext(
        now: now,
        position: position,
        roadMeters: _roadMeters,
        weather: _weather,
      ),
    );
    final top = Recommender.diversify(ranked);
    final byId = {for (final pick in ranked) pick.place.id: pick};
    final recent = [for (final id in taste.recentlyViewed) ?byId[id]]
        .take(4)
        .toList();
    final shown = {for (final pick in top) pick.place.id};
    final gems = ranked
        .where((pick) => pick.place.hiddenGem && !shown.contains(pick.place.id))
        .take(4)
        .toList();
    shown.addAll(gems.map((pick) => pick.place.id));
    final more = ranked
        .where((pick) => !shown.contains(pick.place.id))
        .take(10)
        .toList();

    void open(Recommendation pick) => widget.onOpenPlace(pick.place);
    void explain(Recommendation pick) => showWhyThisPick(
      context,
      pick: pick,
      hasInterests: taste.hasInterests,
      hasLocation: position != null,
      onShowOnMap: () => open(pick),
    );

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.only(top: AppSpace.lg, bottom: 120),
        children: [
          _Header(name: user.name, onOpenProfile: widget.onOpenProfile),
          const SizedBox(height: AppSpace.lg),
          _ContextStrip(
            area: _area(position),
            weather: _weather,
            dayPart: DayPart.at(now),
            locationStatus: _location.value.status,
            onFixLocation: _location.start,
          ),
          const SizedBox(height: AppSpace.xl),
          _InterestsCard(
            interests: taste.interests,
            onEdit: () => _chooseInterests(taste),
          ),
          const SizedBox(height: AppSpace.xxl),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(AppSpace.huge),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_failed)
            _LoadError(onRetry: _load)
          else ...[
            SectionHeader(
              title: taste.hasInterests
                  ? 'Top picks for you'
                  : 'Popular right now',
              subtitle: taste.hasInterests
                  ? 'For your interests, location and the weather'
                  : 'Choose interests to make these yours',
            ),
            const SizedBox(height: AppSpace.md),
            SizedBox(
              height: 330,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: top.length,
                separatorBuilder: (_, _) => const SizedBox(width: AppSpace.md),
                itemBuilder: (context, i) => TopPickCard(
                  key: ValueKey('top-${top[i].place.id}'),
                  pick: top[i],
                  onTap: () => open(top[i]),
                  onExplain: () => explain(top[i]),
                ),
              ),
            ),
            if (recent.isNotEmpty) ...[
              const SizedBox(height: AppSpace.xxxl),
              const SectionHeader(
                title: 'Keep exploring',
                subtitle: 'Recently viewed',
              ),
              _Rows(
                picks: recent,
                onOpen: open,
                onExplain: explain,
                keyPrefix: 'recent',
              ),
            ],
            if (gems.isNotEmpty) ...[
              const SizedBox(height: AppSpace.xxxl),
              const SectionHeader(
                title: 'Hidden gems',
                subtitle: 'Fewer reviews, worth the trip',
              ),
              _Rows(
                picks: gems,
                onOpen: open,
                onExplain: explain,
                keyPrefix: 'gem',
              ),
            ],
            if (more.isNotEmpty) ...[
              const SizedBox(height: AppSpace.xxxl),
              const SectionHeader(title: 'More for you'),
              _Rows(
                picks: more,
                onOpen: open,
                onExplain: explain,
                keyPrefix: 'more',
              ),
            ],
            const SizedBox(height: AppSpace.xxl),
            const HowPicksWork(),
          ],
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.name, required this.onOpenProfile});

  final String name;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(child: Text('For you', style: context.text.displaySmall)),
          ProfileButton(name: name, onTap: onOpenProfile),
        ],
      ),
    );
  }
}

/// Where, what weather and what time of day the picks are for.
class _ContextStrip extends StatelessWidget {
  const _ContextStrip({
    required this.area,
    required this.weather,
    required this.dayPart,
    required this.locationStatus,
    required this.onFixLocation,
  });

  final String? area;
  final Weather? weather;
  final DayPart dayPart;
  final LocationStatus locationStatus;
  final VoidCallback onFixLocation;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final weather = this.weather;
    final locating =
        locationStatus == LocationStatus.idle ||
        locationStatus == LocationStatus.locating;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              if (area != null)
                GlassChip(
                  icon: Icons.location_on_outlined,
                  iconColor: colors.brand,
                  label: 'Around $area',
                )
              else if (!locating)
                GestureDetector(
                  onTap: onFixLocation,
                  child: GlassChip(
                    icon: Icons.location_off_outlined,
                    iconColor: colors.danger,
                    label: 'Location off · tap to allow',
                  ),
                ),
              if (weather != null)
                GlassChip(
                  icon: weather.icon,
                  iconColor: colors.accent,
                  label: '${weather.temperature.round()}° · ${weather.label}',
                ),
              GlassChip(
                icon: Icons.schedule_rounded,
                iconColor: colors.brand,
                label: dayPart.label,
              ),
            ],
          ),
          if (weather != null) ...[
            const SizedBox(height: 6),
            Text(
              OpenMeteoWeatherService.attribution,
              style: TextStyle(color: colors.textTertiary, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}

class _InterestsCard extends StatelessWidget {
  const _InterestsCard({required this.interests, required this.onEdit});

  final Set<InterestTag> interests;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasInterests = interests.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Glass(
        opacity: 0.7,
        borderRadius: BorderRadius.circular(AppRadius.md),
        padding: const EdgeInsets.all(AppSpace.lg),
        child: hasInterests
            ? Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your interests',
                          style: context.text.labelMedium?.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          InterestTag.values
                              .where(interests.contains)
                              .map((tag) => tag.label)
                              .join(' · '),
                          style: context.text.titleSmall,
                        ),
                      ],
                    ),
                  ),
                  TextButton(onPressed: onEdit, child: const Text('Edit')),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome, color: colors.accent),
                      const SizedBox(width: AppSpace.sm),
                      Expanded(
                        child: Text(
                          'Tell us what you love',
                          style: context.text.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.sm),
                  Text(
                    "Pick your interests and we'll rank places around Sri "
                    'Lanka for you.',
                    style: TextStyle(color: colors.textSecondary),
                  ),
                  const SizedBox(height: AppSpace.lg),
                  FilledButton(
                    onPressed: onEdit,
                    child: const Text('Choose interests'),
                  ),
                ],
              ),
      ),
    );
  }
}

class _Rows extends StatelessWidget {
  const _Rows({
    required this.picks,
    required this.onOpen,
    required this.onExplain,
    required this.keyPrefix,
  });

  final List<Recommendation> picks;
  final ValueChanged<Recommendation> onOpen;
  final ValueChanged<Recommendation> onExplain;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < picks.length; i++) ...[
          if (i > 0)
            Divider(
              height: 1,
              indent: 20,
              endIndent: 20,
              color: context.colors.hairline,
            ),
          PickRow(
            key: ValueKey('$keyPrefix-${picks[i].place.id}'),
            pick: picks[i],
            onTap: () => onOpen(picks[i]),
            onExplain: () => onExplain(picks[i]),
          ),
        ],
      ],
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
            "Couldn't load places",
            style: TextStyle(color: context.colors.textSecondary),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
