import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as permissions;

class PermissionService {
  const PermissionService._();

  static Future<String?> ensureLocationPermission() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      return 'Location services are off. Turn them on to start tracking.';
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      return 'Location permission was denied. Rydar needs GPS to track a ride.';
    }

    if (permission == LocationPermission.deniedForever) {
      return 'Location permission is blocked. Enable it in system settings to track rides.';
    }

    return null;
  }

  static Future<String?> ensureNotificationPermission() async {
    final status = await permissions.Permission.notification.status;
    if (status.isGranted || status.isLimited) {
      return null;
    }

    final requested = await permissions.Permission.notification.request();
    if (requested.isGranted || requested.isLimited) {
      return null;
    }

    return 'Background tracking is on, but notifications are disabled.';
  }
}
