import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  const AppConfig._();

  static String get mapboxAccessToken =>
      dotenv.env['MAPBOX_ACCESS_TOKEN']?.trim() ?? '';

  static bool get hasMapboxToken {
    final token = mapboxAccessToken.trim();
    return token.isNotEmpty && token != 'PASTE_MAPBOX_TOKEN_HERE';
  }
}
