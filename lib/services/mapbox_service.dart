import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../core/constants/app_config.dart';
import '../data/models/route_point_model.dart';

enum RouteVehicle {
  car('Car', 'driving-traffic'),
  motorcycle('Motorcycle', 'driving'),
  bicycle('Bicycle', 'cycling'),
  walking('Walking', 'walking');

  const RouteVehicle(this.label, this.mapboxProfile);

  final String label;
  final String mapboxProfile;
}

class PlannedRoute {
  const PlannedRoute({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  final List<RoutePointModel> points;
  final double distanceMeters;
  final int durationSeconds;
}

class MapboxService {
  const MapboxService._();

  static void configureIfReady() {
    if (AppConfig.hasMapboxToken) {
      MapboxOptions.setAccessToken(AppConfig.mapboxAccessToken);
    }
  }

  static Future<PlannedRoute> fetchDirections({
    required RoutePointModel from,
    required RoutePointModel to,
    required RouteVehicle vehicle,
  }) async {
    if (!AppConfig.hasMapboxToken) {
      throw const MapboxDirectionsException(
        'Add your Mapbox access token to plan routes.',
      );
    }

    final url =
        'https://api.mapbox.com/directions/v5/mapbox/'
        '${vehicle.mapboxProfile}/'
        '${from.longitude},${from.latitude};${to.longitude},${to.latitude}';
    final uri = Uri.parse(url).replace(
      queryParameters: {
        'access_token': AppConfig.mapboxAccessToken,
        'alternatives': 'false',
        'geometries': 'geojson',
        'overview': 'full',
        'steps': 'false',
      },
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw const MapboxDirectionsException(
        'Could not load a route right now.',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final routes = body['routes'] as List<dynamic>?;
    if (routes == null || routes.isEmpty) {
      throw const MapboxDirectionsException(
        'No route found for that finish line.',
      );
    }

    final route = routes.first as Map<String, dynamic>;
    final geometry = route['geometry'] as Map<String, dynamic>;
    final coordinates = geometry['coordinates'] as List<dynamic>;
    final now = DateTime.now();
    return PlannedRoute(
      distanceMeters: (route['distance'] as num?)?.toDouble() ?? 0,
      durationSeconds: ((route['duration'] as num?)?.round()) ?? 0,
      points: coordinates.map((coordinate) {
        final pair = coordinate as List<dynamic>;
        return RoutePointModel(
          longitude: (pair[0] as num).toDouble(),
          latitude: (pair[1] as num).toDouble(),
          timestamp: now,
          speedMetersPerSecond: 0,
          accuracyMeters: 0,
        );
      }).toList(),
    );
  }
}

class MapboxDirectionsException implements Exception {
  const MapboxDirectionsException(this.message);

  final String message;
}
