import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_config.dart';
import '../../data/models/route_point_model.dart';
import '../../services/mapbox_service.dart';
import 'placeholder_map.dart';

class MapRouteView extends StatefulWidget {
  const MapRouteView({
    super.key,
    required this.points,
    this.plannedRoutePoints = const [],
    this.finishLine,
    this.onFinishLineSelected,
    this.height,
    this.followLatestPoint = false,
    this.borderRadius = 24,
  });

  final List<RoutePointModel> points;
  final List<RoutePointModel> plannedRoutePoints;
  final RoutePointModel? finishLine;
  final ValueChanged<RoutePointModel>? onFinishLineSelected;
  final double? height;
  final bool followLatestPoint;
  final double borderRadius;

  @override
  State<MapRouteView> createState() => _MapRouteViewState();
}

class _MapRouteViewState extends State<MapRouteView> {
  MapboxMap? _map;
  PolylineAnnotationManager? _lineManager;
  CircleAnnotationManager? _circleManager;
  PolylineAnnotation? _trackedLine;
  PolylineAnnotation? _plannedLine;

  @override
  void didUpdateWidget(covariant MapRouteView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.points.length != widget.points.length ||
        oldWidget.plannedRoutePoints.length !=
            widget.plannedRoutePoints.length ||
        oldWidget.finishLine != widget.finishLine) {
      _drawMapDetails();
      _moveCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.hasMapboxToken) {
      return PlaceholderMap(height: widget.height);
    }

    MapboxService.configureIfReady();
    final initialPoint = widget.points.isNotEmpty ? widget.points.last : null;

    final map = MapWidget(
      key: ValueKey(
        'map_${widget.followLatestPoint}_${widget.points.length}'
        '_${widget.plannedRoutePoints.length}_${widget.finishLine}',
      ),
      styleUri: MapboxStyles.DARK,
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
      },
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
        child: map,
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
        color: const Color(0xFF38C6FF),
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
        lineOpacity: 0.95,
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
    if (latestPoint != null) {
      await _createPin(
        manager: manager,
        point: latestPoint,
        color: AppColors.orange,
        radius: 8,
      );
    }

    final finishLine = widget.finishLine;
    if (finishLine != null) {
      await _createPin(
        manager: manager,
        point: finishLine,
        color: const Color(0xFF1FDD8B),
        radius: 10,
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
      ...widget.points,
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
}
