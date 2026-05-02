import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_config.dart';
import '../../data/models/route_point_model.dart';
import '../../services/mapbox_service.dart';
import 'placeholder_map.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  Map style definitions
// ═══════════════════════════════════════════════════════════════════════════
enum RydarMapStyle {
  dark('Dark', MapboxStyles.DARK, Icons.dark_mode_rounded),
  light('Light', MapboxStyles.LIGHT, Icons.light_mode_rounded),
  satellite(
    'Satellite',
    MapboxStyles.SATELLITE_STREETS,
    Icons.satellite_alt_rounded,
  ),
  streets('Streets', MapboxStyles.STANDARD, Icons.map_rounded),
  outdoors('Outdoors', MapboxStyles.OUTDOORS, Icons.terrain_rounded);

  const RydarMapStyle(this.label, this.uri, this.icon);

  final String label;
  final String uri;
  final IconData icon;
}

class MapRouteController {
  _MapRouteViewState? _state;

  Future<RoutePointModel?> centerPoint() =>
      _state?._centerPoint() ?? Future.value();

  Future<void> focusOnPoint(RoutePointModel point, {double zoom = 16}) =>
      _state?._focusCameraOn(point, zoom: zoom) ?? Future.value();

  void _attach(_MapRouteViewState state) {
    _state = state;
  }

  void _detach(_MapRouteViewState state) {
    if (_state == state) {
      _state = null;
    }
  }
}

class MapRouteView extends StatefulWidget {
  const MapRouteView({
    super.key,
    this.controller,
    required this.points,
    this.plannedRoutePoints = const [],
    this.finishLine,
    this.startLine,
    this.bubbleRadiusMeters,
    this.currentLocation,
    this.locationFocusRequest = 0,
    this.onFinishLineSelected,
    this.height,
    this.followLatestPoint = false,
    this.borderRadius = 24,
    this.showStylePicker = false,
    this.onMapStyleChanged,
    this.mapStyle,
  });

  final MapRouteController? controller;
  final List<RoutePointModel> points;
  final List<RoutePointModel> plannedRoutePoints;
  final RoutePointModel? finishLine;
  final RoutePointModel? startLine;
  final double? bubbleRadiusMeters;
  final RoutePointModel? currentLocation;
  final int locationFocusRequest;
  final ValueChanged<RoutePointModel>? onFinishLineSelected;
  final double? height;
  final bool followLatestPoint;
  final double borderRadius;
  final bool showStylePicker;
  final ValueChanged<RydarMapStyle>? onMapStyleChanged;
  final RydarMapStyle? mapStyle;

  @override
  State<MapRouteView> createState() => _MapRouteViewState();
}

class _MapRouteViewState extends State<MapRouteView> {
  MapboxMap? _map;
  PolylineAnnotationManager? _lineManager;
  CircleAnnotationManager? _circleManager;
  PolylineAnnotation? _trackedLine;
  PolylineAnnotation? _plannedLine;
  PolylineAnnotation? _startBubbleLine;
  PolylineAnnotation? _finishBubbleLine;
  Offset? _finishPinOffset;
  int _finishPinRequestId = 0;

  RydarMapStyle get _effectiveStyle => widget.mapStyle ?? RydarMapStyle.dark;

  @override
  void initState() {
    super.initState();
    widget.controller?._attach(this);
  }

  @override
  void dispose() {
    widget.controller?._detach(this);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MapRouteView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach(this);
      widget.controller?._attach(this);
    }

    // Handle map style changes
    if (oldWidget.mapStyle != widget.mapStyle && widget.mapStyle != null) {
      _changeMapStyle(widget.mapStyle!);
    }

    if (oldWidget.points.length != widget.points.length ||
        oldWidget.plannedRoutePoints.length !=
            widget.plannedRoutePoints.length ||
        oldWidget.plannedRoutePoints != widget.plannedRoutePoints ||
        oldWidget.startLine != widget.startLine ||
        oldWidget.finishLine != widget.finishLine ||
        oldWidget.bubbleRadiusMeters != widget.bubbleRadiusMeters ||
        oldWidget.currentLocation != widget.currentLocation) {
      _drawMapDetails();
      _moveCamera();
      _updateFinishPinOffset();
    }
    if (oldWidget.locationFocusRequest != widget.locationFocusRequest) {
      _focusCurrentLocation();
    }
  }

  Future<void> _changeMapStyle(RydarMapStyle style) async {
    final map = _map;
    if (map == null) return;
    await map.style.setStyleURI(style.uri);
    // Re-create annotation managers after style change
    _lineManager = await map.annotations.createPolylineAnnotationManager();
    _circleManager = await map.annotations.createCircleAnnotationManager();
    _trackedLine = null;
    _plannedLine = null;
    _startBubbleLine = null;
    _finishBubbleLine = null;
    await _drawMapDetails();
  }

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.hasMapboxToken) {
      return PlaceholderMap(height: widget.height);
    }

    MapboxService.configureIfReady();
    final initialPoint = widget.points.isNotEmpty
        ? widget.points.last
        : widget.currentLocation;

    final map = MapWidget(
      key: ValueKey('map_${widget.followLatestPoint}'),
      styleUri: _effectiveStyle.uri,
      cameraOptions: CameraOptions(
        center: Point(
          coordinates: Position(
            initialPoint?.longitude ?? 121.0,
            initialPoint?.latitude ?? 14.6,
          ),
        ),
        zoom: initialPoint == null ? 11 : 15,
      ),
      onMapCreated: (mapboxMap) async {
        _map = mapboxMap;
        await _map?.location.updateSettings(
          LocationComponentSettings(
            enabled: true,
            pulsingEnabled: true,
            pulsingColor: AppColors.orange.toARGB32(),
            showAccuracyRing: true,
            accuracyRingColor: AppColors.orange
                .withValues(alpha: 0.16)
                .toARGB32(),
          ),
        );
        _lineManager = await _map?.annotations
            .createPolylineAnnotationManager();
        _circleManager = await _map?.annotations
            .createCircleAnnotationManager();
        await _drawMapDetails();
        await _moveCamera();
        await _updateFinishPinOffset();
      },
      onCameraChangeListener: (_) => _updateFinishPinOffset(),
      onTapListener: widget.onFinishLineSelected == null
          ? null
          : (context) {
              final coordinates = context.point.coordinates;
              widget.onFinishLineSelected!(
                RoutePointModel(
                  latitude: coordinates.lat.toDouble(),
                  longitude: coordinates.lng.toDouble(),
                  timestamp: DateTime.now(),
                  speedMetersPerSecond: 0,
                  accuracyMeters: 0,
                ),
              );
            },
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: Stack(
          children: [
            Positioned.fill(child: map),
            if (_finishPinOffset != null)
              _FinishLinePinOverlay(offset: _finishPinOffset!),
          ],
        ),
      ),
    );
  }

  Future<void> _drawMapDetails() async {
    final manager = _lineManager;
    if (manager == null) {
      return;
    }
    if (_trackedLine != null) {
      await manager.delete(_trackedLine!);
      _trackedLine = null;
    }
    if (_plannedLine != null) {
      await manager.delete(_plannedLine!);
      _plannedLine = null;
    }
    if (_startBubbleLine != null) {
      await manager.delete(_startBubbleLine!);
      _startBubbleLine = null;
    }
    if (_finishBubbleLine != null) {
      await manager.delete(_finishBubbleLine!);
      _finishBubbleLine = null;
    }

    final bubbleRadius = widget.bubbleRadiusMeters;
    if (bubbleRadius != null && bubbleRadius > 0) {
      final startLine = widget.startLine;
      if (startLine != null) {
        _startBubbleLine = await _createLine(
          manager: manager,
          points: _circlePoints(startLine, bubbleRadius),
          color: AppColors.text,
          width: 2.5,
          opacity: 0.65,
        );
      }
      final finishLine = widget.finishLine;
      if (finishLine != null) {
        _finishBubbleLine = await _createLine(
          manager: manager,
          points: _circlePoints(finishLine, bubbleRadius),
          color: AppColors.orange,
          width: 3,
          opacity: 0.72,
        );
      }
    }

    if (widget.points.length >= 2) {
      _trackedLine = await _createLine(
        manager: manager,
        points: widget.points,
        color: AppColors.orange,
        width: 5,
      );
    }

    if (widget.plannedRoutePoints.length >= 2) {
      _plannedLine = await _createLine(
        manager: manager,
        points: widget.plannedRoutePoints,
        color: AppColors.orange,
        width: 6,
      );
    }

    await _drawPins();
  }

  Future<PolylineAnnotation> _createLine({
    required PolylineAnnotationManager manager,
    required List<RoutePointModel> points,
    required Color color,
    required double width,
    double opacity = 0.95,
  }) {
    return manager.create(
      PolylineAnnotationOptions(
        geometry: LineString(
          coordinates: points
              .map((point) => Position(point.longitude, point.latitude))
              .toList(),
        ),
        lineColor: color.toARGB32(),
        lineWidth: width,
        lineOpacity: opacity,
      ),
    );
  }

  Future<void> _drawPins() async {
    final manager = _circleManager;
    if (manager == null) {
      return;
    }

    await manager.deleteAll();
    final latestPoint = widget.points.isNotEmpty ? widget.points.last : null;
    final currentPoint = latestPoint ?? widget.currentLocation;
    if (currentPoint != null) {
      await _createPin(
        manager: manager,
        point: currentPoint,
        color: AppColors.orange,
        radius: 8,
      );
    }

    final finishLine = widget.finishLine;
    if (finishLine != null) {
      await _createPin(
        manager: manager,
        point: finishLine,
        color: AppColors.orangeDeep,
        radius: 13,
      );
    }
  }

  Future<void> _createPin({
    required CircleAnnotationManager manager,
    required RoutePointModel point,
    required Color color,
    required double radius,
  }) {
    return manager.create(
      CircleAnnotationOptions(
        geometry: Point(coordinates: Position(point.longitude, point.latitude)),
        circleColor: color.toARGB32(),
        circleOpacity: 0.95,
        circleRadius: radius,
        circleStrokeColor: Colors.white.toARGB32(),
        circleStrokeOpacity: 0.95,
        circleStrokeWidth: 3,
      ),
    );
  }

  Future<void> _moveCamera() async {
    final map = _map;
    if (map == null) {
      return;
    }

    final focusPoints = [
      if (widget.points.isNotEmpty)
        ...widget.points
      else if (widget.currentLocation != null)
        widget.currentLocation!,
      ...widget.plannedRoutePoints,
      if (widget.finishLine != null) widget.finishLine!,
    ];
    if (focusPoints.isEmpty) {
      return;
    }
    if (focusPoints.length == 1) {
      final point = focusPoints.first;
      await map.easeTo(
        CameraOptions(
          center: Point(coordinates: Position(point.longitude, point.latitude)),
          zoom: 15,
        ),
        MapAnimationOptions(duration: 600),
      );
      return;
    }

    if (widget.followLatestPoint &&
        widget.finishLine == null &&
        widget.plannedRoutePoints.isEmpty) {
      final latest = widget.points.last;
      await map.easeTo(
        CameraOptions(
          center: Point(
            coordinates: Position(latest.longitude, latest.latitude),
          ),
          zoom: 16,
        ),
        MapAnimationOptions(duration: 600),
      );
      return;
    }

    final coordinates = focusPoints
        .map(
          (point) =>
              Point(coordinates: Position(point.longitude, point.latitude)),
        )
        .toList();
    final camera = await map.cameraForCoordinatesPadding(
      coordinates,
      CameraOptions(),
      MbxEdgeInsets(top: 40, left: 40, bottom: 40, right: 40),
      16,
      null,
    );
    await map.setCamera(camera);
  }

  Future<void> _focusCurrentLocation() async {
    final point = widget.points.isNotEmpty
        ? widget.points.last
        : widget.currentLocation;
    if (point == null) {
      return;
    }
    await _focusCameraOn(point, zoom: 16);
  }

  Future<void> _focusCameraOn(
    RoutePointModel point, {
    required double zoom,
  }) async {
    final map = _map;
    if (map == null) {
      return;
    }
    await map.easeTo(
      CameraOptions(
        center: Point(coordinates: Position(point.longitude, point.latitude)),
        zoom: zoom,
      ),
      MapAnimationOptions(duration: 600),
    );
  }

  Future<RoutePointModel?> _centerPoint() async {
    final map = _map;
    if (map == null || !mounted) {
      return null;
    }
    final size = context.size;
    if (size == null || size.isEmpty) {
      return null;
    }
    final point = await map.coordinateForPixel(
      ScreenCoordinate(x: size.width / 2, y: size.height / 2),
    );
    final coordinates = point.coordinates;
    return RoutePointModel(
      latitude: coordinates.lat.toDouble(),
      longitude: coordinates.lng.toDouble(),
      timestamp: DateTime.now(),
      speedMetersPerSecond: 0,
      accuracyMeters: 0,
    );
  }

  Future<void> _updateFinishPinOffset() async {
    final map = _map;
    final finishLine = widget.finishLine;
    final requestId = ++_finishPinRequestId;
    if (map == null || finishLine == null) {
      if (mounted && _finishPinOffset != null) {
        setState(() => _finishPinOffset = null);
      }
      return;
    }

    final screenCoordinate = await map.pixelForCoordinate(
      Point(coordinates: Position(finishLine.longitude, finishLine.latitude)),
    );
    if (!mounted ||
        requestId != _finishPinRequestId ||
        finishLine != widget.finishLine) {
      return;
    }
    setState(() {
      _finishPinOffset = Offset(screenCoordinate.x, screenCoordinate.y);
    });
  }
}

class _FinishLinePinOverlay extends StatelessWidget {
  const _FinishLinePinOverlay({required this.offset});

  final Offset offset;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: offset.dx - 21,
      top: offset.dy - 47,
      child: IgnorePointer(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.82),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.orange.withValues(alpha: 0.45),
                    blurRadius: 18,
                  ),
                ],
              ),
              child: const Icon(
                Icons.flag_rounded,
                color: AppColors.orange,
                size: 24,
              ),
            ),
            Container(width: 3, height: 14, color: Colors.white),
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: AppColors.orange,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

List<RoutePointModel> _circlePoints(
  RoutePointModel center,
  double radiusMeters,
) {
  const segments = 72;
  const earthRadiusMeters = 6371000.0;
  final centerLat = center.latitude * math.pi / 180;
  final centerLng = center.longitude * math.pi / 180;
  final angularDistance = radiusMeters / earthRadiusMeters;
  final points = <RoutePointModel>[];

  for (var i = 0; i <= segments; i++) {
    final bearing = 2 * math.pi * i / segments;
    final lat = math.asin(
      math.sin(centerLat) * math.cos(angularDistance) +
          math.cos(centerLat) * math.sin(angularDistance) * math.cos(bearing),
    );
    final lng =
        centerLng +
        math.atan2(
          math.sin(bearing) * math.sin(angularDistance) * math.cos(centerLat),
          math.cos(angularDistance) - math.sin(centerLat) * math.sin(lat),
        );

    points.add(
      RoutePointModel(
        latitude: lat * 180 / math.pi,
        longitude: lng * 180 / math.pi,
        timestamp: center.timestamp,
        speedMetersPerSecond: 0,
        accuracyMeters: center.accuracyMeters,
      ),
    );
  }
  return points;
}
