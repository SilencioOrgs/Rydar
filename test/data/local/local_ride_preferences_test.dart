import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:rydar_app/data/local/local_ride_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDirectory;

  setUpAll(() async {
    tempDirectory = await Directory.systemTemp.createTemp('rydar_prefs_test');
    Hive.init(tempDirectory.path);
    await LocalRidePreferences.instance.init();
  });

  setUp(() async {
    await Hive.box('rydar_ride_preferences').clear();
  });

  tearDownAll(() async {
    await Hive.close();
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  group('LocalRidePreferences', () {
    test('returns defaults before values are saved', () {
      final preferences = LocalRidePreferences.instance;

      expect(preferences.vehicleName, LocalRidePreferences.defaultVehicleName);
      expect(
        preferences.mapStyleName,
        LocalRidePreferences.defaultMapStyleName,
      );
      expect(
        preferences.bubbleRadiusMeters,
        LocalRidePreferences.defaultBubbleRadiusMeters,
      );
    });

    test('saves vehicle and map style names', () async {
      final preferences = LocalRidePreferences.instance;

      await preferences.saveVehicleName('bicycle');
      await preferences.saveMapStyleName('satellite');

      expect(preferences.vehicleName, 'bicycle');
      expect(preferences.mapStyleName, 'satellite');
    });

    test('clamps saved bubble radius', () async {
      final preferences = LocalRidePreferences.instance;

      await preferences.saveBubbleRadiusMeters(4);
      expect(preferences.bubbleRadiusMeters, 10);

      await preferences.saveBubbleRadiusMeters(400);
      expect(preferences.bubbleRadiusMeters, 250);
    });
  });
}
