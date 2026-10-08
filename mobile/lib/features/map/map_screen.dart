import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/theme/theme_context.dart';
import '../for_you/data/taste_profile.dart';
import 'data/attraction.dart';
import 'data/attraction_repository.dart';
import 'data/trip_estimate.dart';
import 'location/location_service.dart';
import 'map_dependencies.dart';
import 'map_tiles.dart';
import 'routing/route_service.dart';
import 'widgets/destination_panel.dart';
import 'widgets/explore_sheet.dart';
import 'widgets/map_controls.dart';
import 'widgets/map_markers.dart';

/// A real map of attractions with the user's live GPS position. Tap a marker
/// or a row in the list to pick an attraction, or tap anywhere on the map to
/// drop a pin; the map then draws the road route there, and the sheet shows
/// its distance and travel time.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key, this.focus});

  /// When set to a place, the map selects it and shows its route, then
  /// clears it. Used to open places picked elsewhere, e.g. on For You.
  final ValueNotifier<Attraction?>? focus;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _Destination {
  /// Only places with coordinates can be chosen on the map.
  _Destination.attraction(Attraction this.attraction)
    : point = attraction.location!;

  _Destination.pin(this.point) : attraction = null;

  final Attraction? attraction;
  final LatLng point;
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  static final _sriLanka = LatLngBounds(
    const LatLng(5.85, 79.55),
    const LatLng(9.85, 81.95),
  );

  // Heights of the sheet's content when collapsed and when showing a
  // destination, not counting the space under the navigation bar.
  static const _collapsedContent = 216.0;
  static const _destinationContent = 460.0;
  static const _maxSheet = 0.88;

  final _map = MapController();
  final _sheet = DraggableScrollableController();
  AnimationController? _cameraAnimation;
  bool _mapReady = false;

  late AttractionRepository _repository;
  late LocationService _location;
  late RouteService _routes;
  TileProvider? _tileProvider;
  bool _initialised = false;

  // The road route to the destination.
  RoadRoute? _route;
  String? _routeError;
  bool _routing = false;
  int _routeRequest = 0;
  LatLng? _routedFrom;

  // Road distances from the user to every place, by place id.
  Map<String, RoadDistance?> _roadDistances = const {};
  LatLng? _distancesFrom;
  bool _fetchingDistances = false;
  DateTime? _distancesFailedAt;

  List<Attraction> _attractions = const [];
  bool _loading = true;
  bool _failed = false;

  AttractionCategory? _category;
  String _query = '';
  PlaceSort _sort = PlaceSort.nearest;
  TravelMode _mode = TravelMode.drive;
  _Destination? _destination;

  // Layout, refreshed on every build.
  double _height = 1;
  double _topInset = 0;
  double _minSheet = 0.25;
  double _destinationSheet = 0.5;
  double? _extent;

  @override
  void initState() {
    super.initState();
    widget.focus?.addListener(_applyFocus);
  }

  @override
  void didUpdateWidget(MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focus != widget.focus) {
      oldWidget.focus?.removeListener(_applyFocus);
      widget.focus?.addListener(_applyFocus);
    }
  }

  /// Selects the place in [MapScreen.focus] once the places and the map are
  /// ready; called again from both until then.
  void _applyFocus() {
    final focus = widget.focus;
    final place = focus?.value;
    if (place == null || !_mapReady || _loading || !mounted) return;
    focus!.value = null;
    final match = _attractions.where((p) => p.id == place.id).firstOrNull;
    final target = match ?? place;
    if (target.location == null) return;
    _select(_Destination.attraction(target));
  }

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
    _tileProvider = dependencies?.tileProvider;
    _load();
    _location.start();
  }

  @override
  void dispose() {
    widget.focus?.removeListener(_applyFocus);
    _location
      ..removeListener(_onLocationChanged)
      ..dispose();
    _cameraAnimation?.dispose();
    _sheet.dispose();
    _map.dispose();
    super.dispose();
  }

  void _onLocationChanged() {
    setState(() {});
    final user = _location.value.position;
    if (user == null) return;
    // Re-route only after a real move, not on every small GPS update.
    if (_destination != null &&
        (_routedFrom == null || _metersBetween(_routedFrom!, user) > 500)) {
      _updateRoute();
    }
    if (_distancesFrom == null ||
        _metersBetween(_distancesFrom!, user) > 1000) {
      _updateDistances();
    }
  }

  static double _metersBetween(LatLng a, LatLng b) =>
      TripEstimate.between(a, b).meters;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final attractions = await _repository.fetchAll();
      if (!mounted) return;
      setState(() {
        _attractions = attractions;
        _loading = false;
      });
      _updateDistances();
      _applyFocus();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
      // Raise the sheet so the error and its Retry button are in view.
      _resizeSheet(_destinationSheet);
    }
  }

  bool _matches(Attraction place) {
    final query = _query.trim().toLowerCase();
    return (_category == null || place.category == _category) &&
        (query.isEmpty ||
            place.name.toLowerCase().contains(query) ||
            place.district.toLowerCase().contains(query) ||
            place.province.toLowerCase().contains(query));
  }

  /// Matching places that have coordinates, nearest by road or best rated
  /// first.
  List<Attraction> get _visible {
    final places = [
      for (final place in _attractions)
        if (place.location != null && _matches(place)) place,
    ];
    final user = _location.value.position;
    if (_sort == PlaceSort.nearest && user != null) {
      final meters = {
        for (final place in places)
          place.id: _roadDistances.containsKey(place.id)
              ? _roadDistances[place.id]?.meters ?? double.infinity
              : _metersBetween(user, place.location!),
      };
      places.sort((a, b) => meters[a.id]!.compareTo(meters[b.id]!));
    } else {
      places.sort(
        (a, b) => (b.rankingScore ?? 0).compareTo(a.rankingScore ?? 0),
      );
    }
    return places;
  }

  /// Matching places still waiting for coordinates.
  int get _unmapped => _attractions
      .where((place) => place.location == null && _matches(place))
      .length;

  /// Road distance to [place] for the list. Until road distances arrive (or
  /// if they can't be fetched), a straight-line figure marked "≈".
  String? _distanceLabel(Attraction place) {
    final user = _location.value.position;
    if (user == null) return null;
    if (_roadDistances.containsKey(place.id)) {
      final road = _roadDistances[place.id];
      return road == null ? 'No road' : formatDistance(road.meters);
    }
    return '≈ ${formatDistance(_metersBetween(user, place.location!))}';
  }

  // Routes ------------------------------------------------------------------

  /// Fetches the road route from the user to the destination.
  Future<void> _updateRoute() async {
    final user = _location.value.position;
    final destination = _destination;
    final request = ++_routeRequest;
    if (user == null || destination == null) {
      setState(() {
        _route = null;
        _routeError = null;
        _routing = false;
      });
      return;
    }
    _routedFrom = user;
    setState(() {
      _route = null;
      _routeError = null;
      _routing = true;
    });
    try {
      final route = await _routes.route(user, destination.point, _mode);
      if (!mounted || request != _routeRequest) return;
      setState(() {
        _route = route;
        _routing = false;
      });
      _frame(route.path, maxZoom: 15, sheet: _destinationSheet);
    } catch (error) {
      if (!mounted || request != _routeRequest) return;
      setState(() {
        _routing = false;
        _routeError = error is RouteException
            ? error.message
            : "Couldn't reach the route service. Check your connection.";
      });
    }
  }

  /// Fetches road distances to every place, for the list and its sorting.
  Future<void> _updateDistances() async {
    final user = _location.value.position;
    final failedAt = _distancesFailedAt;
    if (user == null || _fetchingDistances) return;
    if (failedAt != null &&
        DateTime.now().difference(failedAt) < const Duration(minutes: 1)) {
      return;
    }
    final places = [
      for (final place in _attractions)
        if (place.location != null) place,
    ];
    if (places.isEmpty) return;

    _fetchingDistances = true;
    _distancesFrom = user;
    try {
      final distances = await _routes.distances(user, [
        for (final place in places) place.location!,
      ], TravelMode.drive);
      if (!mounted) return;
      _distancesFailedAt = null;
      setState(() {
        _roadDistances = {
          for (var i = 0; i < places.length; i++) places[i].id: distances[i],
        };
      });
    } catch (_) {
      // Keep the straight-line figures; try again on a later update.
      _distancesFrom = null;
      _distancesFailedAt = DateTime.now();
    } finally {
      _fetchingDistances = false;
    }
  }

  // Sheet -------------------------------------------------------------------

  /// Records the sheet's size. Notifications can arrive mid-layout, when
  /// rebuilding is not allowed, so those are applied after the frame.
  bool _onSheetChanged(DraggableScrollableNotification notification) {
    void apply() {
      if (mounted && _extent != notification.extent) {
        setState(() => _extent = notification.extent);
      }
    }

    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) => apply());
    } else {
      apply();
    }
    return false;
  }

  void _resizeSheet(double size) {
    if (!_sheet.isAttached) return;
    _sheet.animateTo(size, duration: AppMotion.slow, curve: AppMotion.standard);
  }

  // Camera ------------------------------------------------------------------

  /// Keeps framed points clear of the banner at the top, and of the sheet
  /// and the round buttons above it at the bottom, while always leaving some
  /// map to fit them into.
  EdgeInsets _cameraPadding(double sheet) {
    final top = _topInset + 88;
    final bottom = math.min(sheet * _height + 96, _height - top - 160);
    return EdgeInsets.fromLTRB(48, top, 48, math.max(bottom, 32));
  }

  void _frame(List<LatLng> points, {required double maxZoom, double? sheet}) {
    if (!_mapReady) return;
    final fit = CameraFit.coordinates(
      coordinates: points,
      padding: _cameraPadding(sheet ?? _extent ?? _minSheet),
      maxZoom: maxZoom,
    );
    _animateCamera(fit.fit(_map.camera));
  }

  void _animateCamera(MapCamera target) {
    final from = _map.camera;
    _cameraAnimation?.dispose();
    _cameraAnimation = null;
    if (MediaQuery.disableAnimationsOf(context)) {
      _map.move(target.center, target.zoom);
      return;
    }
    final controller = _cameraAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    final t = CurvedAnimation(parent: controller, curve: AppMotion.emphasized);
    final lat = Tween(begin: from.center.latitude, end: target.center.latitude);
    final lng = Tween(
      begin: from.center.longitude,
      end: target.center.longitude,
    );
    final zoom = Tween(begin: from.zoom, end: target.zoom);
    controller
      ..addListener(
        () => _map.move(
          LatLng(lat.evaluate(t), lng.evaluate(t)),
          zoom.evaluate(t),
        ),
      )
      ..forward();
  }

  // Actions -----------------------------------------------------------------

  /// Resizes the sheet once the next frame is built. Swapping the sheet's
  /// content replaces its scroll position, which cancels a resize started
  /// in the same frame.
  void _resizeSheetAfterSwap(double Function() size) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _resizeSheet(size());
    });
  }

  void _select(_Destination destination) {
    FocusManager.instance.primaryFocus?.unfocus();
    if (destination.attraction case final place?) {
      TasteScope.maybeOf(context)?.viewed(place.id);
    }
    final swapping = _destination == null;
    setState(() => _destination = destination);
    if (swapping) {
      _resizeSheetAfterSwap(() => _destinationSheet);
    } else {
      _resizeSheet(_destinationSheet);
    }
    final user = _location.value.position;
    _frame(
      [destination.point, ?user],
      maxZoom: user != null
          ? 15
          : destination.attraction != null
          ? 12
          : _map.camera.zoom,
      sheet: _destinationSheet,
    );
    _updateRoute();
  }

  void _closeDestination() {
    _routeRequest++; // Ignore any route still on its way.
    setState(() {
      _destination = null;
      _route = null;
      _routeError = null;
      _routing = false;
    });
    _resizeSheetAfterSwap(() => _minSheet);
  }

  void _changeMode(TravelMode mode) {
    if (mode == _mode) return;
    setState(() => _mode = mode);
    _updateRoute();
  }

  /// Fits the whole road route on screen, or the two end points if there
  /// is no route.
  void _showRoute() {
    final user = _location.value.position;
    final destination = _destination;
    if (user == null || destination == null) return;
    _frame(_route?.path ?? [user, destination.point], maxZoom: 15);
  }

  void _fixLocation() {
    switch (_location.value.status) {
      case LocationStatus.serviceDisabled || LocationStatus.deniedForever:
        _location.openSettings();
      default:
        _location.start();
    }
  }

  void _goToUser() {
    final user = _location.value.position;
    if (user == null) {
      _fixLocation();
    } else {
      _frame([user], maxZoom: 14);
    }
  }

  void _fitAll() {
    if (!_mapReady) return;
    final fit = CameraFit.bounds(
      bounds: _sriLanka,
      padding: _cameraPadding(_extent ?? _minSheet),
    );
    _animateCamera(fit.fit(_map.camera));
  }

  // Build -------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final style = MapTileStyle.of(dark: context.isDark);
    final insets = MediaQuery.paddingOf(context);
    final location = _location.value;
    final user = location.position;
    final destination = _destination;
    final selected = destination?.attraction;
    final visible = _visible;
    final route = _route;
    final straightLine = user != null && destination != null
        ? TripEstimate.between(user, destination.point)
        : null;
    // A straight line is only drawn, clearly marked, when no road route
    // could be found.
    final showStraightLine =
        straightLine != null && route == null && _routeError != null;

    return LayoutBuilder(
      builder: (context, constraints) {
        _height = constraints.maxHeight;
        _topInset = insets.top;
        // The navigation bar floats over the bottom of the screen; its height
        // is included in the bottom padding.
        _minSheet = ((_collapsedContent + insets.bottom) / _height).clamp(
          0.12,
          0.5,
        );
        _destinationSheet = ((_destinationContent + insets.bottom) / _height)
            // Leave enough map above the panel to see the route.
            .clamp(_minSheet + 0.05, 0.58);
        final sheetPixels = (_extent ?? _minSheet) * _height;
        final controlsVisible = (_extent ?? _minSheet) < 0.62;

        return Stack(
          children: [
            FlutterMap(
              mapController: _map,
              options: MapOptions(
                // Also set a start over Sri Lanka: the first frame can be
                // drawn before the fit applies, and would otherwise fetch
                // tiles for flutter_map's default location.
                initialCenter: _sriLanka.center,
                initialZoom: 7,
                initialCameraFit: CameraFit.bounds(
                  bounds: _sriLanka,
                  padding: _cameraPadding(_minSheet),
                ),
                minZoom: 5,
                maxZoom: 18,
                backgroundColor: colors.background,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
                onMapReady: () {
                  _mapReady = true;
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => _applyFocus(),
                  );
                },
                onTap: (_, point) => _select(_Destination.pin(point)),
              ),
              children: [
                TileLayer(
                  urlTemplate: style.urlTemplate,
                  subdomains: style.subdomains,
                  retinaMode: style.retina && RetinaMode.isHighDensity(context),
                  tileBuilder: style.tileBuilder,
                  tileProvider: _tileProvider,
                  maxNativeZoom: 19,
                  userAgentPackageName: 'com.deetrax.tripc',
                ),
                if (user != null && location.accuracy > 20)
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: user,
                        radius: location.accuracy,
                        useRadiusInMeter: true,
                        color: UserLocationDot.blue.withValues(alpha: 0.12),
                        borderColor: UserLocationDot.blue.withValues(
                          alpha: 0.35,
                        ),
                        borderStrokeWidth: 1,
                      ),
                    ],
                  ),
                if (route != null && route.path.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: route.path,
                        strokeWidth: 5,
                        color: colors.brand,
                        borderStrokeWidth: 2,
                        borderColor: colors.background.withValues(alpha: 0.85),
                      ),
                      // Short walks between the road and the exact start or
                      // end point.
                      for (final leg in [
                        [user!, route.path.first],
                        [route.path.last, destination!.point],
                      ])
                        if (_metersBetween(leg.first, leg.last) > 30)
                          Polyline(
                            points: leg,
                            strokeWidth: 3,
                            color: colors.brand.withValues(alpha: 0.7),
                            pattern: const StrokePattern.dotted(),
                          ),
                    ],
                  ),
                if (showStraightLine)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: [user!, destination!.point],
                        strokeWidth: 3,
                        color: colors.textSecondary.withValues(alpha: 0.8),
                        pattern: StrokePattern.dashed(segments: const [10, 8]),
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    for (final place in [
                      ...visible.where((p) => p.id != selected?.id),
                      ?selected,
                    ])
                      Marker(
                        point: place.location!,
                        width: AttractionMarker.extent,
                        height: AttractionMarker.extent,
                        child: AttractionMarker(
                          key: ValueKey('marker-${place.id}'),
                          attraction: place,
                          selected: place.id == selected?.id,
                          onTap: () => _select(_Destination.attraction(place)),
                        ),
                      ),
                    if (destination != null && selected == null)
                      Marker(
                        point: destination.point,
                        width: DroppedPinMarker.size.width,
                        height: DroppedPinMarker.size.height,
                        alignment: Alignment.topCenter,
                        child: const DroppedPinMarker(),
                      ),
                    if (user != null)
                      Marker(
                        point: user,
                        width: UserLocationDot.extent,
                        height: UserLocationDot.extent,
                        child: const UserLocationDot(),
                      ),
                    if (route != null && route.path.isNotEmpty)
                      Marker(
                        point: route.path[route.path.length ~/ 2],
                        width: 160,
                        height: 40,
                        child: Center(
                          child: DistancePill(
                            label: formatDistance(route.meters),
                          ),
                        ),
                      )
                    else if (showStraightLine)
                      Marker(
                        point: LatLng(
                          (user!.latitude + destination!.point.latitude) / 2,
                          (user.longitude + destination.point.longitude) / 2,
                        ),
                        width: 160,
                        height: 40,
                        child: Center(
                          child: DistancePill(
                            label: '≈ ${straightLine.distanceLabel}',
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            Positioned(
              top: insets.top + 12,
              left: 16,
              right: 16,
              child: LocationBanner(state: location, onAction: _fixLocation),
            ),
            Positioned(
              left: 16,
              bottom: sheetPixels + 12,
              child: _Fade(
                visible: controlsVisible,
                child: MapRoundButton(
                  icon: Icons.near_me_rounded,
                  tooltip: 'My location',
                  onPressed: _goToUser,
                ),
              ),
            ),
            Positioned(
              right: 16,
              bottom: sheetPixels + 36,
              child: _Fade(
                visible: controlsVisible,
                child: MapRoundButton(
                  icon: Icons.zoom_out_map_rounded,
                  tooltip: 'Show all of Sri Lanka',
                  onPressed: _fitAll,
                ),
              ),
            ),
            Positioned(
              right: 16,
              bottom: sheetPixels + 8,
              child: MapAttribution(
                text: route != null
                    ? '${style.attribution} · Routes: OSRM'
                    : style.attribution,
              ),
            ),
            Positioned.fill(
              child: NotificationListener<DraggableScrollableNotification>(
                onNotification: _onSheetChanged,
                child: DraggableScrollableSheet(
                  controller: _sheet,
                  initialChildSize: _minSheet,
                  minChildSize: _minSheet,
                  maxChildSize: _maxSheet,
                  snap: true,
                  snapSizes: [_destinationSheet],
                  builder: (context, scrollController) => MapSheetSurface(
                    child: destination == null
                        ? ExploreSheet(
                            scrollController: scrollController,
                            bottomPadding: insets.bottom,
                            places: visible,
                            unmappedCount: _unmapped,
                            loading: _loading,
                            failed: _failed,
                            onRetry: _load,
                            category: _category,
                            onCategoryChanged: (category) =>
                                setState(() => _category = category),
                            sort: _sort,
                            onSortChanged: (sort) =>
                                setState(() => _sort = sort),
                            canSortByDistance: user != null,
                            onQueryChanged: (query) =>
                                setState(() => _query = query),
                            onSearchFocused: () => _resizeSheet(_maxSheet),
                            distanceOf: _distanceLabel,
                            onSelect: (place) =>
                                _select(_Destination.attraction(place)),
                          )
                        : DestinationPanel(
                            scrollController: scrollController,
                            bottomPadding: insets.bottom,
                            attraction: selected,
                            point: destination.point,
                            hasLocation: user != null,
                            route: route,
                            routing: _routing,
                            routeError: _routeError,
                            straightLine: straightLine,
                            onRetryRoute: _updateRoute,
                            mode: _mode,
                            onModeChanged: _changeMode,
                            onShowRoute: _showRoute,
                            onEnableLocation: _fixLocation,
                            onClose: _closeDestination,
                          ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Fade extends StatelessWidget {
  const _Fade({required this.visible, required this.child});

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: AppMotion.base,
        child: child,
      ),
    );
  }
}
