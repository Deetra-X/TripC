import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

enum LocationStatus {
  /// Not asked for yet.
  idle,

  /// Waiting for permission or the first GPS fix.
  locating,

  ready,

  /// Location services are switched off on the device.
  serviceDisabled,

  /// Permission was refused, but can be asked for again.
  denied,

  /// Permission was refused permanently; only system settings can fix it.
  deniedForever,

  /// Something else went wrong, e.g. no GPS signal.
  unavailable,
}

@immutable
class LocationState {
  const LocationState(this.status, {this.position, this.accuracy = 0});

  final LocationStatus status;
  final LatLng? position;

  /// Horizontal accuracy in metres.
  final double accuracy;

  bool get hasPosition => position != null;
}

/// The device's live location for the map.
abstract class LocationService extends ValueNotifier<LocationState> {
  LocationService() : super(const LocationState(LocationStatus.idle));

  /// Asks for permission if needed, then follows the user's position.
  Future<void> start();

  /// Opens the system screen that fixes the current problem: location
  /// settings when the service is off, app settings when permission was
  /// refused permanently.
  Future<void> openSettings();
}

/// [LocationService] backed by the phone's GPS (or the browser on web).
class DeviceLocationService extends LocationService {
  StreamSubscription<Position>? _subscription;
  bool _disposed = false;

  void _set(LocationState state) {
    if (!_disposed) value = state;
  }

  @override
  Future<void> start() async {
    _set(LocationState(LocationStatus.locating, position: value.position));
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _set(const LocationState(LocationStatus.serviceDisabled));
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        _set(const LocationState(LocationStatus.denied));
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        _set(const LocationState(LocationStatus.deniedForever));
        return;
      }

      await _subscription?.cancel();
      _subscription =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 10,
            ),
          ).listen(
            (position) => _set(
              LocationState(
                LocationStatus.ready,
                position: LatLng(position.latitude, position.longitude),
                accuracy: position.accuracy,
              ),
            ),
            onError: (Object _) =>
                _set(const LocationState(LocationStatus.unavailable)),
          );
    } catch (_) {
      _set(const LocationState(LocationStatus.unavailable));
    }
  }

  @override
  Future<void> openSettings() async {
    switch (value.status) {
      case LocationStatus.serviceDisabled:
        await Geolocator.openLocationSettings();
      case LocationStatus.deniedForever:
        await Geolocator.openAppSettings();
      default:
        await start();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    super.dispose();
  }
}
