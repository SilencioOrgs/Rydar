import 'package:geolocator/geolocator.dart';

class LocationService {
  const LocationService();

  Stream<Position> positionStream() {
    const settings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 5,
    );
    return Geolocator.getPositionStream(locationSettings: settings);
  }
}
