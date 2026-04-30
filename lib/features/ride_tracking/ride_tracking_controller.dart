import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';

import '../../core/utils/distance_utils.dart';
import '../../data/models/ride_model.dart';
import '../../data/models/route_point_model.dart';
import '../../services/location_service.dart';
import '../../services/mapbox_service.dart';
import '../../services/permission_service.dart';
import '../../services/text_to_speech_service.dart';

enum RideTrackingStatus { idle, tracking, paused, finishing, finished }

class RideTrackingController extends ChangeNotifier {
  RideTrackingController({
    LocationService? locationService,
    TextToSpeechService? textToSpeechService,
  }) : _locationService = locationService ?? const LocationService(),
       _textToSpeechService = textToSpeechService ?? TextToSpeechService();

  final LocationService _locationService;
  final TextToSpeechService _textToSpeechService;
  final Stopwatch _stopwatch = Stopwatch();
  final List<RoutePointModel> _routePoints = [];

  StreamSubscription<Position>? _positionSubscription;
  Timer? _ticker;
  RoutePointModel? _lastDistancePoint;
  int _routeRequestId = 0;
  RideTrackingStatus status = RideTrackingStatus.idle;
  String? errorMessage;
  String? routeMessage;
  RoutePointModel? finishLine;
  PlannedRoute? plannedRoute;
  RouteVehicle selectedVehicle = RouteVehicle.car;
  bool isPlanningRoute = false;
  double distanceMeters = 0;
  double currentSpeedMetersPerSecond = 0;
  double maxSpeedMetersPerSecond = 0;

  List<RoutePointModel> get routePoints => List.unmodifiable(_routePoints);
  int get durationSeconds => _stopwatch.elapsed.inSeconds;
  double get averageSpeedMetersPerSecond =>
      durationSeconds <= 0 ? 0 : distanceMeters / durationSeconds;

  Future<bool> start() async {
    errorMessage = await PermissionService.ensureLocationPermission();
    if (errorMessage != null) {
      notifyListeners();
      return false;
    }

    _resetRide();
    status = RideTrackingStatus.tracking;
    _stopwatch.start();
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => notifyListeners(),
    );
    _positionSubscription = _locationService.positionStream().listen(
      _handlePosition,
      onError: (_) {
        errorMessage =
            'GPS signal is unavailable right now. Try again in an open area.';
        notifyListeners();
      },
    );
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
    plannedRoute = null;
    if (finishLine != null && _routePoints.isNotEmpty) {
      unawaited(_fetchPlannedRoute());
    }
    notifyListeners();
  }

  void setFinishLine(RoutePointModel point) {
    finishLine = point;
    plannedRoute = null;
    _routeRequestId++;
    routeMessage = _routePoints.isEmpty
        ? 'Finish line saved. Start riding or wait for GPS to show the route.'
        : null;
    if (_routePoints.isNotEmpty) {
      unawaited(_fetchPlannedRoute());
    }
    notifyListeners();
  }

  void clearFinishLine() {
    finishLine = null;
    plannedRoute = null;
    routeMessage = null;
    isPlanningRoute = false;
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
    routeMessage = finishLine == null
        ? null
        : 'Finish line saved. Waiting for your first GPS point.';
  }

  void _handlePosition(Position position) {
    if (status != RideTrackingStatus.tracking || !_isUsable(position)) {
      return;
    }

    final point = RoutePointModel(
      latitude: position.latitude,
      longitude: position.longitude,
      timestamp: position.timestamp,
      speedMetersPerSecond: position.speed.isFinite && position.speed > 0
          ? position.speed
          : currentSpeedMetersPerSecond,
      accuracyMeters: position.accuracy,
    );

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
    if (finishLine != null &&
        plannedRoute == null &&
        !isPlanningRoute &&
        _routePoints.length == 1) {
      unawaited(_fetchPlannedRoute());
    }
    notifyListeners();
  }

  Future<void> _fetchPlannedRoute() async {
    final destination = finishLine;
    if (destination == null || _routePoints.isEmpty) {
      return;
    }

    final requestId = ++_routeRequestId;
    isPlanningRoute = true;
    routeMessage = 'Planning route to finish line...';
    notifyListeners();

    try {
      final route = await MapboxService.fetchDirections(
        from: _routePoints.last,
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
