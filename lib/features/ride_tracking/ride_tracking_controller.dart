import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';

import '../../core/utils/distance_utils.dart';
import '../../data/local/local_ride_preferences.dart';
import '../../data/models/ride_model.dart';
import '../../data/models/route_point_model.dart';
import '../../services/location_service.dart';
import '../../services/mapbox_service.dart';
import '../../services/permission_service.dart';
import '../../services/text_to_speech_service.dart';

enum RideTrackingStatus { idle, armed, tracking, paused, finishing, finished }

enum RideStartMode { exitBubble, immediate }

class RideTrackingController extends ChangeNotifier {
  RideTrackingController({
    LocationService? locationService,
    TextToSpeechService? textToSpeechService,
    RouteVehicle? initialVehicle,
    double? initialGeofenceRadiusMeters,
  }) : _locationService = locationService ?? const LocationService(),
       _textToSpeechService = textToSpeechService ?? TextToSpeechService() {
    selectedVehicle = initialVehicle ?? RouteVehicle.car;
    geofenceRadiusMeters =
        initialGeofenceRadiusMeters?.clamp(10, 250).toDouble() ??
        LocalRidePreferences.defaultBubbleRadiusMeters;
  }

  final LocationService _locationService;
  final TextToSpeechService _textToSpeechService;
  final Stopwatch _stopwatch = Stopwatch();
  final List<RoutePointModel> _routePoints = [];

  StreamSubscription<Position>? _positionSubscription;
  Timer? _ticker;
  RoutePointModel? _lastDistancePoint;
  int _routeRequestId = 0;
  int _placeSearchRequestId = 0;
  RideTrackingStatus status = RideTrackingStatus.idle;
  String? errorMessage;
  String? routeMessage;
  String? placeSearchMessage;
  RoutePointModel? finishLine;
  RoutePointModel? startLine;
  PlannedRoute? plannedRoute;
  List<MapboxPlace> placeSuggestions = const [];
  RouteVehicle selectedVehicle = RouteVehicle.car;
  RoutePointModel? currentLocation;
  double geofenceRadiusMeters = 35;
  bool isOfflineMode = false;
  bool isPlanningRoute = false;
  bool isSearchingPlaces = false;
  bool isLocating = false;
  int locationFocusRequest = 0;
  bool _announcedFinishLine = false;
  double distanceMeters = 0;
  double currentSpeedMetersPerSecond = 0;
  double maxSpeedMetersPerSecond = 0;
  VoidCallback? onFinishBubbleEntered;

  List<RoutePointModel> get routePoints => List.unmodifiable(_routePoints);
  RoutePointModel? get navigationOrigin =>
      _routePoints.isNotEmpty ? _routePoints.last : currentLocation;
  int get durationSeconds => _stopwatch.elapsed.inSeconds;
  double get averageSpeedMetersPerSecond =>
      durationSeconds <= 0 ? 0 : distanceMeters / durationSeconds;

  Future<bool> start({RideStartMode mode = RideStartMode.exitBubble}) =>
      _start(offline: false, mode: mode);

  Future<bool> startOffline({RideStartMode mode = RideStartMode.exitBubble}) =>
      _start(offline: true, mode: mode);

  Future<bool> _start({
    required bool offline,
    required RideStartMode mode,
  }) async {
    errorMessage = await PermissionService.ensureLocationPermission();
    if (errorMessage != null) {
      notifyListeners();
      return false;
    }
    final notificationNotice = defaultTargetPlatform == TargetPlatform.android
        ? await PermissionService.ensureNotificationPermission()
        : null;

    isOfflineMode = offline;
    _resetRide();
    status = mode == RideStartMode.immediate
        ? RideTrackingStatus.tracking
        : RideTrackingStatus.armed;
    if (mode == RideStartMode.immediate) {
      _stopwatch.start();
    }
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => notifyListeners(),
    );
    _positionSubscription = _locationService
        .positionStream(background: true)
        .listen(
          _handlePosition,
          onError: (_) {
            errorMessage =
                'GPS signal is unavailable right now. Try again in an open area.';
            notifyListeners();
          },
        );
    final startMessage = mode == RideStartMode.immediate
        ? finishLine == null
              ? 'Ride started.'
              : 'Ride started. Head to the finish bubble.'
        : 'Start bubble armed. Leave ${geofenceRadiusMeters.round()} m to begin.';
    routeMessage = notificationNotice == null
        ? startMessage
        : '$startMessage $notificationNotice';
    notifyListeners();
    return true;
  }

  void pause() {
    if (status != RideTrackingStatus.tracking) {
      return;
    }
    status = RideTrackingStatus.paused;
    currentSpeedMetersPerSecond = 0;
    _lastDistancePoint = null;
    _stopwatch.stop();
    notifyListeners();
  }

  void resume() {
    if (status != RideTrackingStatus.paused) {
      return;
    }
    status = RideTrackingStatus.tracking;
    _lastDistancePoint = null;
    _stopwatch.start();
    notifyListeners();
  }

  void selectVehicle(RouteVehicle vehicle) {
    if (selectedVehicle == vehicle) {
      return;
    }
    selectedVehicle = vehicle;
    unawaited(LocalRidePreferences.instance.saveVehicleName(vehicle.name));
    plannedRoute = null;
    if (finishLine != null && navigationOrigin != null) {
      _planRoute();
    }
    notifyListeners();
  }

  void setFinishLine(RoutePointModel point) {
    finishLine = point;
    plannedRoute = null;
    _routeRequestId++;
    routeMessage = navigationOrigin == null
        ? 'Finish line saved. Focus your location to preview the route.'
        : null;
    if (navigationOrigin != null) {
      _planRoute();
    }
    notifyListeners();
  }

  void setGeofenceRadius(double radiusMeters) {
    final clamped = radiusMeters.clamp(10, 250).toDouble();
    if ((geofenceRadiusMeters - clamped).abs() < 0.1) {
      return;
    }
    geofenceRadiusMeters = clamped;
    unawaited(LocalRidePreferences.instance.saveBubbleRadiusMeters(clamped));
    if (status == RideTrackingStatus.armed) {
      routeMessage =
          'Start bubble armed. Leave ${geofenceRadiusMeters.round()} m to begin.';
    }
    notifyListeners();
  }

  Future<void> searchPlaces(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.length < 2) {
      placeSuggestions = const [];
      placeSearchMessage = 'Type at least 2 characters to search.';
      isSearchingPlaces = false;
      notifyListeners();
      return;
    }

    final requestId = ++_placeSearchRequestId;
    placeSearchMessage = null;
    placeSuggestions = const [];
    isSearchingPlaces = true;
    notifyListeners();

    try {
      final suggestions = await MapboxService.searchPlaces(
        query: trimmedQuery,
        proximity: navigationOrigin,
      );
      if (requestId != _placeSearchRequestId) {
        return;
      }
      placeSuggestions = suggestions;
      placeSearchMessage = suggestions.isEmpty ? 'No places found.' : null;
    } on MapboxDirectionsException catch (error) {
      if (requestId != _placeSearchRequestId) {
        return;
      }
      placeSuggestions = const [];
      placeSearchMessage = error.message;
    } catch (_) {
      if (requestId != _placeSearchRequestId) {
        return;
      }
      placeSuggestions = const [];
      placeSearchMessage = 'Could not search places right now.';
    } finally {
      if (requestId == _placeSearchRequestId) {
        isSearchingPlaces = false;
        notifyListeners();
      }
    }
  }

  void selectPlaceAsFinishLine(MapboxPlace place) {
    placeSuggestions = const [];
    placeSearchMessage = null;
    isSearchingPlaces = false;
    setFinishLine(
      RoutePointModel(
        latitude: place.latitude,
        longitude: place.longitude,
        timestamp: DateTime.now(),
        speedMetersPerSecond: 0,
        accuracyMeters: 0,
      ),
    );
    routeMessage = 'Finish line set: ${place.name}';
    notifyListeners();
  }

  Future<void> focusOnCurrentLocation() async {
    final latestPoint = _routePoints.isNotEmpty ? _routePoints.last : null;
    if (latestPoint != null) {
      currentLocation = latestPoint;
      locationFocusRequest++;
      if (finishLine != null && plannedRoute == null && !isPlanningRoute) {
        _planRoute();
      }
      notifyListeners();
      return;
    }

    errorMessage = await PermissionService.ensureLocationPermission();
    if (errorMessage != null) {
      notifyListeners();
      return;
    }

    isLocating = true;
    routeMessage = 'Finding your location...';
    notifyListeners();

    try {
      const settings = LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
      );
      final position = await Geolocator.getCurrentPosition(
        locationSettings: settings,
      );
      currentLocation = _positionToPoint(position);
      locationFocusRequest++;
      errorMessage = null;
      routeMessage = finishLine == null
          ? null
          : 'Planning route to finish line...';
      if (finishLine != null) {
        _planRoute();
      }
    } catch (_) {
      errorMessage =
          'Could not find your location right now. Try again in an open area.';
      routeMessage = null;
    } finally {
      isLocating = false;
      notifyListeners();
    }
  }

  void clearFinishLine() {
    finishLine = null;
    startLine = null;
    plannedRoute = null;
    routeMessage = null;
    placeSuggestions = const [];
    placeSearchMessage = null;
    isSearchingPlaces = false;
    isPlanningRoute = false;
    _announcedFinishLine = false;
    _routeRequestId++;
    notifyListeners();
  }

  Future<RideModel> finish() async {
    status = RideTrackingStatus.finishing;
    notifyListeners();
    await _positionSubscription?.cancel();
    _ticker?.cancel();
    _stopwatch.stop();
    await _textToSpeechService.speakFinishLine();
    status = RideTrackingStatus.finished;
    notifyListeners();
    return buildRideSnapshot();
  }

  RideModel buildRideSnapshot() {
    return RideModel(
      id: const Uuid().v4(),
      dateTime: DateTime.now(),
      distanceMeters: distanceMeters,
      durationSeconds: durationSeconds,
      averageSpeedMetersPerSecond: averageSpeedMetersPerSecond,
      maxSpeedMetersPerSecond: maxSpeedMetersPerSecond,
      routePoints: List.unmodifiable(_routePoints),
    );
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _ticker?.cancel();
    super.dispose();
  }

  void _resetRide() {
    _routePoints.clear();
    _lastDistancePoint = null;
    _stopwatch
      ..reset()
      ..stop();
    distanceMeters = 0;
    currentSpeedMetersPerSecond = 0;
    maxSpeedMetersPerSecond = 0;
    errorMessage = null;
    plannedRoute = null;
    currentLocation = null;
    startLine = null;
    isPlanningRoute = false;
    _announcedFinishLine = false;
    routeMessage = finishLine == null
        ? null
        : isOfflineMode
        ? 'Offline guide ready. Waiting for your first GPS point.'
        : 'Finish line saved. Waiting for your first GPS point.';
  }

  void _handlePosition(Position position) {
    if ((status != RideTrackingStatus.armed &&
            status != RideTrackingStatus.tracking) ||
        !_isUsable(position)) {
      return;
    }

    final point = _positionToPoint(position);
    currentLocation = point;

    if (status == RideTrackingStatus.armed) {
      _handleArmedPosition(point);
      return;
    }

    startLine ??= point;
    final previous = _lastDistancePoint;
    if (previous != null) {
      final segment = DistanceUtils.haversineMeters(
        fromLat: previous.latitude,
        fromLng: previous.longitude,
        toLat: point.latitude,
        toLng: point.longitude,
      );
      final elapsedSeconds =
          point.timestamp.difference(previous.timestamp).inMilliseconds / 1000;
      final calculatedSpeed = elapsedSeconds <= 0
          ? 0.0
          : segment / elapsedSeconds;

      if (_isReasonableSegment(segment, calculatedSpeed)) {
        distanceMeters += segment;
        currentSpeedMetersPerSecond = point.speedMetersPerSecond > 0
            ? point.speedMetersPerSecond
            : calculatedSpeed;
        maxSpeedMetersPerSecond =
            currentSpeedMetersPerSecond > maxSpeedMetersPerSecond
            ? currentSpeedMetersPerSecond
            : maxSpeedMetersPerSecond;
      }
    }

    _routePoints.add(point);
    _lastDistancePoint = point;
    if (finishLine != null) {
      _checkFinishLine(point);
      if (isOfflineMode) {
        _setOfflineRoute();
      } else if (plannedRoute == null &&
          !isPlanningRoute &&
          _routePoints.length == 1) {
        unawaited(_fetchPlannedRoute());
      }
    }
    notifyListeners();
  }

  void _handleArmedPosition(RoutePointModel point) {
    startLine ??= point;
    final start = startLine!;
    final distanceFromStart = DistanceUtils.haversineMeters(
      fromLat: start.latitude,
      fromLng: start.longitude,
      toLat: point.latitude,
      toLng: point.longitude,
    );

    if (distanceFromStart <= geofenceRadiusMeters) {
      if (finishLine != null) {
        if (isOfflineMode) {
          _setOfflineRoute();
        } else if (plannedRoute == null && !isPlanningRoute) {
          unawaited(_fetchPlannedRoute());
        }
      }
      routeMessage =
          'Waiting inside start bubble (${distanceFromStart.toStringAsFixed(0)} m).';
      notifyListeners();
      return;
    }

    status = RideTrackingStatus.tracking;
    _stopwatch.start();
    _routePoints.add(point);
    _lastDistancePoint = point;
    routeMessage = finishLine == null
        ? 'Ride started.'
        : 'Ride started. Head to the finish bubble.';
    if (finishLine != null) {
      if (isOfflineMode) {
        _setOfflineRoute();
      } else {
        unawaited(_fetchPlannedRoute());
      }
    }
    notifyListeners();
  }

  void _planRoute() {
    if (isOfflineMode) {
      _setOfflineRoute();
      return;
    }
    unawaited(_fetchPlannedRoute());
  }

  void _setOfflineRoute() {
    final destination = finishLine;
    final origin = navigationOrigin;
    if (destination == null || origin == null) {
      return;
    }
    final distance = DistanceUtils.haversineMeters(
      fromLat: origin.latitude,
      fromLng: origin.longitude,
      toLat: destination.latitude,
      toLng: destination.longitude,
    );
    plannedRoute = PlannedRoute(
      points: [origin, destination],
      distanceMeters: distance,
      durationSeconds: 0,
    );
    if (!_announcedFinishLine) {
      routeMessage = 'Offline guide active: straight line to finish.';
    }
    isPlanningRoute = false;
    _routeRequestId++;
  }

  void _checkFinishLine(RoutePointModel point) {
    final destination = finishLine;
    if (destination == null || _announcedFinishLine) {
      return;
    }
    final distance = DistanceUtils.haversineMeters(
      fromLat: point.latitude,
      fromLng: point.longitude,
      toLat: destination.latitude,
      toLng: destination.longitude,
    );
    if (distance > geofenceRadiusMeters) {
      return;
    }
    _announcedFinishLine = true;
    routeMessage = 'You reached the finish bubble.';
    onFinishBubbleEntered?.call();
  }

  Future<void> _fetchPlannedRoute() async {
    final destination = finishLine;
    final origin = navigationOrigin;
    if (destination == null || origin == null) {
      return;
    }

    final requestId = ++_routeRequestId;
    isPlanningRoute = true;
    routeMessage = 'Planning route to finish line...';
    notifyListeners();

    try {
      final route = await MapboxService.fetchDirections(
        from: origin,
        to: destination,
        vehicle: selectedVehicle,
      );
      if (requestId != _routeRequestId || finishLine != destination) {
        return;
      }
      plannedRoute = route;
      routeMessage = route.points.isEmpty
          ? 'No route found for that finish line.'
          : null;
    } on MapboxDirectionsException catch (error) {
      if (requestId != _routeRequestId || finishLine != destination) {
        return;
      }
      plannedRoute = null;
      routeMessage = error.message;
    } catch (_) {
      if (requestId != _routeRequestId || finishLine != destination) {
        return;
      }
      plannedRoute = null;
      routeMessage = 'Could not load a route right now.';
    } finally {
      if (requestId == _routeRequestId) {
        isPlanningRoute = false;
        notifyListeners();
      }
    }
  }

  bool _isUsable(Position position) {
    if (!position.latitude.isFinite || !position.longitude.isFinite) {
      return false;
    }
    return position.accuracy <= 50;
  }

  RoutePointModel _positionToPoint(Position position) {
    return RoutePointModel(
      latitude: position.latitude,
      longitude: position.longitude,
      timestamp: position.timestamp,
      speedMetersPerSecond: position.speed.isFinite && position.speed > 0
          ? position.speed
          : currentSpeedMetersPerSecond,
      accuracyMeters: position.accuracy,
    );
  }

  bool _isReasonableSegment(double segmentMeters, double calculatedSpeed) {
    if (segmentMeters < 1) {
      return false;
    }
    if (segmentMeters > 160) {
      return false;
    }
    if (calculatedSpeed > 28) {
      return false;
    }
    return true;
  }
}
