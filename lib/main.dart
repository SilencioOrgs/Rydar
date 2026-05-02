import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'data/local/local_ride_preferences.dart';
import 'data/local/local_ride_storage.dart';
import 'services/mapbox_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Hive.initFlutter();
  await LocalRideStorage.instance.init();
  await LocalRidePreferences.instance.init();
  MapboxService.configureIfReady();
  runApp(const RydarApp());
}
