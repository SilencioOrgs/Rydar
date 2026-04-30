import 'dart:math';

class DistanceUtils {
  const DistanceUtils._();

  static double haversineMeters({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) {
    const earthRadiusMeters = 6371000.0;
    final lat1 = _degreesToRadians(fromLat);
    final lat2 = _degreesToRadians(toLat);
    final dLat = _degreesToRadians(toLat - fromLat);
    final dLng = _degreesToRadians(toLng - fromLng);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  static String formatMeters(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    }
    return '${(meters / 1000).toStringAsFixed(2)} km';
  }

  static String formatKilometers(double meters) {
    return (meters / 1000).toStringAsFixed(2);
  }

  static double _degreesToRadians(double degrees) => degrees * pi / 180;
}
