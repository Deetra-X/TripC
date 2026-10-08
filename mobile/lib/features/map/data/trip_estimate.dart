import 'package:latlong2/latlong.dart';

enum TravelMode { walk, drive }

/// Straight-line ("as the crow flies") distance between two points. Only a
/// fallback for when road routes can't be fetched, and always labelled as
/// such; road distances come from a [RouteService].
class TripEstimate {
  const TripEstimate(this.meters);

  TripEstimate.between(LatLng from, LatLng to)
    : meters = _distance.distance(from, to);

  static const _distance = Distance();

  final double meters;

  String get distanceLabel => formatDistance(meters);
}

String formatDistance(double meters) {
  if (meters < 1000) return '${(meters / 10).round() * 10} m';
  final km = meters / 1000;
  return km < 10 ? '${km.toStringAsFixed(1)} km' : '${km.round()} km';
}

String formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes % 60;
  if (hours == 0) return '${duration.inMinutes < 1 ? 1 : minutes} min';
  if (minutes == 0) return '$hours h';
  return '$hours h $minutes min';
}
