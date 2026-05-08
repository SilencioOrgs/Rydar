import 'package:geolocator/geolocator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rydar_app/data/models/route_point_model.dart';
import 'package:rydar_app/features/ride_tracking/ride_tracking_controller.dart';
import 'package:rydar_app/services/mapbox_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RideTrackingController', () {
    test('uses initial ride planning preferences', () {
      final controller = RideTrackingController(
        initialVehicle: RouteVehicle.bicycle,
        initialGeofenceRadiusMeters: 80,
      );
      addTearDown(controller.dispose);

      expect(controller.selectedVehicle, RouteVehicle.bicycle);
      expect(controller.geofenceRadiusMeters, 80);
    });

    test('clamps geofence radius to supported range', () {
      final controller = RideTrackingController();
      addTearDown(controller.dispose);

      controller.setGeofenceRadius(4);
      expect(controller.geofenceRadiusMeters, 10);

      controller.setGeofenceRadius(400);
      expect(controller.geofenceRadiusMeters, 250);
    });

    test('stores finish line without planning until an origin exists', () {
      final controller = RideTrackingController();
      addTearDown(controller.dispose);
      final finishLine = RoutePointModel(
        latitude: 14.5995,
        longitude: 120.9842,
        timestamp: DateTime(2026),
        speedMetersPerSecond: 0,
        accuracyMeters: 0,
      );

      controller.setFinishLine(finishLine);

      expect(controller.finishLine, finishLine);
      expect(controller.plannedRoute, isNull);
      expect(
        controller.routeMessage,
        'Finish line saved. Focus your location to preview the route.',
      );
    });

    test(
      'short place queries show validation message without loading',
      () async {
        final controller = RideTrackingController();
        addTearDown(controller.dispose);

        await controller.searchPlaces('a');

        expect(controller.placeSuggestions, isEmpty);
        expect(controller.isSearchingPlaces, isFalse);
        expect(
          controller.placeSearchMessage,
          'Type at least 2 characters to search.',
        );
      },
    );

    test('builds an empty ride snapshot from idle state', () {
      final controller = RideTrackingController();
      addTearDown(controller.dispose);

      final ride = controller.buildRideSnapshot();

      expect(ride.id, isNotEmpty);
      expect(ride.distanceMeters, 0);
      expect(ride.durationSeconds, 0);
      expect(ride.routePoints, isEmpty);
      expect(ride.hasMeaningfulDistance, isFalse);
      expect(ride.recordForLeaderboard, isFalse);
    });

    test('leaderboard recording forces a motorcycle category', () {
      final controller = RideTrackingController(
        initialVehicle: RouteVehicle.car,
      );
      addTearDown(controller.dispose);

      controller.setRecordForLeaderboard(true);
      final ride = controller.buildRideSnapshot();

      expect(controller.selectedVehicle, RouteVehicle.motorcycle);
      expect(controller.selectedMotorModelId, isNotNull);
      expect(ride.vehicleName, RouteVehicle.motorcycle.name);
      expect(ride.motorModelId, controller.selectedMotorModelId);
      expect(ride.recordForLeaderboard, isTrue);
    });

    test('keeps start point when exit bubble begins tracking', () {
      final controller = RideTrackingController(
        initialGeofenceRadiusMeters: 20,
      );
      addTearDown(controller.dispose);
      controller.status = RideTrackingStatus.armed;

      controller.handlePositionForTest(
        _position(
          latitude: 14.6000,
          longitude: 121.0000,
          timestamp: DateTime(2026, 1, 1, 8),
          accuracy: 80,
        ),
      );
      controller.handlePositionForTest(
        _position(
          latitude: 14.6005,
          longitude: 121.0000,
          timestamp: DateTime(2026, 1, 1, 8, 0, 10),
          accuracy: 80,
        ),
      );

      expect(controller.status, RideTrackingStatus.tracking);
      expect(controller.routePoints, hasLength(2));
      expect(controller.distanceMeters, greaterThan(10));
      expect(controller.buildRideSnapshot().hasMeaningfulDistance, isTrue);
    });
  });
}

Position _position({
  required double latitude,
  required double longitude,
  required DateTime timestamp,
  double accuracy = 10,
}) {
  return Position(
    latitude: latitude,
    longitude: longitude,
    timestamp: timestamp,
    accuracy: accuracy,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );
}
