class RoutePointModel {
  const RoutePointModel({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.speedMetersPerSecond,
    required this.accuracyMeters,
  });

  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double speedMetersPerSecond;
  final double accuracyMeters;

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'speedMetersPerSecond': speedMetersPerSecond,
      'accuracyMeters': accuracyMeters,
    };
  }

  factory RoutePointModel.fromMap(Map<dynamic, dynamic> map) {
    return RoutePointModel(
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      timestamp: DateTime.parse(map['timestamp'] as String),
      speedMetersPerSecond:
          (map['speedMetersPerSecond'] as num?)?.toDouble() ?? 0,
      accuracyMeters: (map['accuracyMeters'] as num?)?.toDouble() ?? 0,
    );
  }
}
