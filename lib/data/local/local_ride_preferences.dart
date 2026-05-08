import 'package:hive_flutter/hive_flutter.dart';

class LocalRidePreferences {
  LocalRidePreferences._();

  static final LocalRidePreferences instance = LocalRidePreferences._();

  static const String _boxName = 'rydar_ride_preferences';
  static const String _vehicleKey = 'vehicle';
  static const String _motorModelKey = 'motor_model';
  static const String _mapStyleKey = 'map_style';
  static const String _bubbleRadiusKey = 'bubble_radius';
  static const String defaultVehicleName = 'car';
  static const String defaultMapStyleName = 'dark';
  static const double defaultBubbleRadiusMeters = 35;

  Box? _box;

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  String get vehicleName => _stringValue(_vehicleKey, defaultVehicleName);

  String? get motorModelId => _nullableStringValue(_motorModelKey);

  String get mapStyleName => _stringValue(_mapStyleKey, defaultMapStyleName);

  double get bubbleRadiusMeters {
    final value = _box?.get(_bubbleRadiusKey);
    if (value is num) {
      return _clampBubbleRadius(value.toDouble());
    }
    return defaultBubbleRadiusMeters;
  }

  Future<void> saveVehicleName(String vehicleName) async {
    await _box?.put(_vehicleKey, vehicleName);
  }

  Future<void> saveMotorModelId(String motorModelId) async {
    await _box?.put(_motorModelKey, motorModelId);
  }

  Future<void> saveMapStyleName(String mapStyleName) async {
    await _box?.put(_mapStyleKey, mapStyleName);
  }

  Future<void> saveBubbleRadiusMeters(double radiusMeters) async {
    await _box?.put(_bubbleRadiusKey, _clampBubbleRadius(radiusMeters));
  }

  String _stringValue(String key, String fallback) {
    final value = _box?.get(key);
    return value is String && value.trim().isNotEmpty ? value : fallback;
  }

  String? _nullableStringValue(String key) {
    final value = _box?.get(key);
    return value is String && value.trim().isNotEmpty ? value : null;
  }

  double _clampBubbleRadius(double radiusMeters) {
    return radiusMeters.clamp(10, 250).toDouble();
  }
}
