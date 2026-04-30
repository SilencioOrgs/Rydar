import 'route_point_model.dart';

class RideModel {
  const RideModel({
    required this.id,
    required this.dateTime,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.averageSpeedMetersPerSecond,
    required this.maxSpeedMetersPerSecond,
    required this.routePoints,
    this.photoPath,
    this.rideCardImagePath,
  });

  final String id;
  final DateTime dateTime;
  final double distanceMeters;
  final int durationSeconds;
  final double averageSpeedMetersPerSecond;
  final double maxSpeedMetersPerSecond;
  final List<RoutePointModel> routePoints;
  final String? photoPath;
  final String? rideCardImagePath;

  bool get hasMeaningfulDistance =>
      distanceMeters >= 10 && routePoints.length >= 2;

  RideModel copyWith({String? photoPath, String? rideCardImagePath}) {
    return RideModel(
      id: id,
      dateTime: dateTime,
      distanceMeters: distanceMeters,
      durationSeconds: durationSeconds,
      averageSpeedMetersPerSecond: averageSpeedMetersPerSecond,
      maxSpeedMetersPerSecond: maxSpeedMetersPerSecond,
      routePoints: routePoints,
      photoPath: photoPath ?? this.photoPath,
      rideCardImagePath: rideCardImagePath ?? this.rideCardImagePath,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dateTime': dateTime.toIso8601String(),
      'distanceMeters': distanceMeters,
      'durationSeconds': durationSeconds,
      'averageSpeedMetersPerSecond': averageSpeedMetersPerSecond,
      'maxSpeedMetersPerSecond': maxSpeedMetersPerSecond,
      'routePoints': routePoints.map((point) => point.toMap()).toList(),
      'photoPath': photoPath,
      'rideCardImagePath': rideCardImagePath,
    };
  }

  factory RideModel.fromMap(Map<dynamic, dynamic> map) {
    final points = (map['routePoints'] as List? ?? const [])
        .map((point) => RoutePointModel.fromMap(point as Map<dynamic, dynamic>))
        .toList();

    return RideModel(
      id: map['id'] as String,
      dateTime: DateTime.parse(map['dateTime'] as String),
      distanceMeters: (map['distanceMeters'] as num).toDouble(),
      durationSeconds: (map['durationSeconds'] as num).toInt(),
      averageSpeedMetersPerSecond:
          (map['averageSpeedMetersPerSecond'] as num?)?.toDouble() ?? 0,
      maxSpeedMetersPerSecond:
          (map['maxSpeedMetersPerSecond'] as num?)?.toDouble() ?? 0,
      routePoints: points,
      photoPath: map['photoPath'] as String?,
      rideCardImagePath: map['rideCardImagePath'] as String?,
    );
  }
}
