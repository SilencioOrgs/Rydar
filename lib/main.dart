import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'data/local/local_ride_preferences.dart';
import 'data/local/local_ride_storage.dart';
import 'firebase_options.dart';
import 'services/mapbox_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await GoogleSignIn.instance.initialize();
  await Hive.initFlutter();
  await LocalRideStorage.instance.init();
  await LocalRidePreferences.instance.init();
  MapboxService.configureIfReady();
  runApp(const RydarApp());
}
