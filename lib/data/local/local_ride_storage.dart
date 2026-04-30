import 'package:hive_flutter/hive_flutter.dart';

import '../models/ride_model.dart';

class LocalRideStorage {
  LocalRideStorage._();

  static final LocalRideStorage instance = LocalRideStorage._();

  static const String _boxName = 'rydar_rides';
  late final Box _box;

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  Future<void> saveRide(RideModel ride) async {
    await _box.put(ride.id, ride.toMap());
  }

  List<RideModel> getRides() {
    final rides =
        _box.values
            .whereType<Map>()
            .map((item) => RideModel.fromMap(item))
            .toList()
          ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return rides;
  }

  RideModel? getRide(String id) {
    final value = _box.get(id);
    if (value is Map) {
      return RideModel.fromMap(value);
    }
    return null;
  }

  Future<void> deleteRide(String id) => _box.delete(id);

  int get totalRides => _box.length;
}
