import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/distance_utils.dart';
import '../../core/utils/duration_utils.dart';
import '../../core/utils/speed_utils.dart';
import '../../data/local/local_ride_preferences.dart';
import '../../data/models/scooter_model.dart';
import '../../services/mapbox_service.dart';
import '../../shared/widgets/map_route_view.dart';
import '../../shared/widgets/motorcycle_category_picker.dart';
import '../ride_summary/ride_summary_screen.dart';
import 'ride_tracking_controller.dart';

part 'ride_tracking_widgets.dart';

RouteVehicle _vehicleFromName(String name) {
  return RouteVehicle.values.firstWhere(
    (vehicle) => vehicle.name == name,
    orElse: () => RouteVehicle.car,
  );
}

RydarMapStyle _mapStyleFromName(String name) {
  return RydarMapStyle.values.firstWhere(
    (style) => style.name == name,
    orElse: () => RydarMapStyle.dark,
  );
}

class RideTrackingScreen extends StatefulWidget {
  const RideTrackingScreen({super.key});

  @override
  State<RideTrackingScreen> createState() => _RideTrackingScreenState();
}

class _RideTrackingScreenState extends State<RideTrackingScreen> {
  late final RideTrackingController _controller;
  final MapRouteController _mapController = MapRouteController();
  RydarMapStyle _mapStyle = RydarMapStyle.dark;
  bool _isPickingFinishLine = false;

  @override
  void initState() {
    super.initState();
    final preferences = LocalRidePreferences.instance;
    _mapStyle = _mapStyleFromName(preferences.mapStyleName);
    _controller =
        RideTrackingController(
            initialVehicle: _vehicleFromName(preferences.vehicleName),
            initialGeofenceRadiusMeters: preferences.bubbleRadiusMeters,
          )
          ..onFinishBubbleEntered = _finishRide
          ..addListener(_rebuild);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_rebuild)
      ..dispose();
    super.dispose();
  }

  void _rebuild() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final isIdle = _controller.status == RideTrackingStatus.idle;
    final isArmed = _controller.status == RideTrackingStatus.armed;
    final isTracking = _controller.status == RideTrackingStatus.tracking;
    final isPaused = _controller.status == RideTrackingStatus.paused;
    final isFinishing = _controller.status == RideTrackingStatus.finishing;
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Full-screen map ──────────────────────────────────────────
          Positioned.fill(
            child: MapRouteView(
              controller: _mapController,
              points: _controller.routePoints,
              plannedRoutePoints: _controller.plannedRoute?.points ?? const [],
              finishLine: _controller.finishLine,
              startLine: _controller.startLine,
              bubbleRadiusMeters: _controller.geofenceRadiusMeters,
              currentLocation: _controller.currentLocation,
              locationFocusRequest: _controller.locationFocusRequest,
              followLatestPoint: true,
              borderRadius: 0,
              mapStyle: _mapStyle,
            ),
          ),
          const Positioned.fill(child: _MapShade()),
          if (_isPickingFinishLine) const Positioned.fill(child: _CenterPin()),

          // ── Top bar ─────────────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _GlassCircle(
                      tooltip: 'Back',
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                    const Spacer(),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _GlassCircle(
                          tooltip: 'Expand map',
                          icon: Icons.open_in_full_rounded,
                          onTap: _openExpandedMap,
                        ),
                        const SizedBox(height: 10),
                        _GlassCircle(
                          tooltip: 'Pin finish line',
                          icon: Icons.add_location_alt_rounded,
                          onTap: _startFinishLinePicker,
                        ),
                        const SizedBox(height: 10),
                        _GlassCircle(
                          tooltip: 'Map style',
                          icon: Icons.layers_rounded,
                          onTap: _showMapStylePicker,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Bottom controls ─────────────────────────────────────────
          Positioned(
            left: 16,
            right: 16,
            bottom: bottomPad + 16,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.62,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_controller.errorMessage != null) ...[
                      _GlassCard(
                        child: Text(
                          _controller.errorMessage!,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (_controller.routeMessage != null) ...[
                      _GlassCard(
                        child: Text(
                          _controller.routeMessage!,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    _RoutePlannerBar(
                      controller: _controller,
                      onOpen: _showRouteSheet,
                    ),
                    if (_isPickingFinishLine) ...[
                      const SizedBox(height: 8),
                      _PinPickerActions(
                        onCancel: _cancelFinishLinePicker,
                        onPin: _pinFinishLineAtCenter,
                      ),
                    ],
                    const SizedBox(height: 8),
                    _RideControls(
                      isIdle: isIdle,
                      isArmed: isArmed,
                      isTracking: isTracking,
                      isPaused: isPaused,
                      isFinishing: isFinishing,
                      isLocating: _controller.isLocating,
                      selectedVehicle: _controller.selectedVehicle,
                      onShowStartOptions: _showStartOptions,
                      onPause: _controller.pause,
                      onResume: _controller.resume,
                      onFinish: _finishRide,
                      onFocusLocation: _focusOnMyLocation,
                    ),
                    const SizedBox(height: 10),
                    _StatsBar(controller: _controller),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Actions ────────────────────────────────────────────────────────
  Future<void> _finishRide() async {
    if (_controller.status == RideTrackingStatus.finishing ||
        _controller.status == RideTrackingStatus.finished) {
      return;
    }
    final ride = await _controller.finish();
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => RideSummaryScreen(ride: ride)),
    );
  }

  Future<void> _focusOnMyLocation() async {
    await _controller.focusOnCurrentLocation();
  }

  Future<void> _openExpandedMap() {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _ExpandedMapScreen(
          controller: _controller,
          mapStyle: _mapStyle,
          onStyleChanged: _setMapStyle,
        ),
      ),
    );
  }

  void _showMapStylePicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _MapStyleSheet(
        current: _mapStyle,
        onSelected: (style) {
          _setMapStyle(style);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showRouteSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ListenableBuilder(
        listenable: _controller,
        builder: (ctx, _) => DraggableScrollableSheet(
          initialChildSize: 0.64,
          minChildSize: 0.36,
          maxChildSize: 0.92,
          expand: false,
          builder: (context, scrollController) {
            final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + keyboardInset),
                child: _RouteToolsCard(
                  controller: _controller,
                  scrollController: scrollController,
                  onPinOnMap: _startFinishLinePicker,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showStartOptions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, setSheetState) => _StartOptionsSheet(
          selectedVehicle: _controller.selectedVehicle,
          recordForLeaderboard: _controller.recordForLeaderboard,
          selectedMotorModel: _controller.selectedMotorModel,
          selectedMotorModelId: _controller.selectedMotorModelId,
          onRecordForLeaderboardChanged: (value) {
            _controller.setRecordForLeaderboard(value);
            setSheetState(() {});
          },
          onMotorModelChanged: (model) {
            _controller.selectMotorModel(model);
            setSheetState(() {});
          },
          onStartExitBubble: () =>
              _startFromSheet(offline: false, mode: RideStartMode.exitBubble),
          onStartImmediate: () =>
              _startFromSheet(offline: false, mode: RideStartMode.immediate),
          onStartOfflineExitBubble: () =>
              _startFromSheet(offline: true, mode: RideStartMode.exitBubble),
          onStartOfflineImmediate: () =>
              _startFromSheet(offline: true, mode: RideStartMode.immediate),
        ),
      ),
    );
  }

  Future<void> _startFromSheet({
    required bool offline,
    required RideStartMode mode,
  }) async {
    Navigator.of(context).pop();
    if (offline) {
      await _controller.startOffline(mode: mode);
    } else {
      await _controller.start(mode: mode);
    }
  }

  void _setMapStyle(RydarMapStyle style) {
    setState(() => _mapStyle = style);
    unawaited(LocalRidePreferences.instance.saveMapStyleName(style.name));
  }

  Future<void> _startFinishLinePicker() async {
    final currentFinishLine = _controller.finishLine;
    setState(() => _isPickingFinishLine = true);
    if (currentFinishLine != null) {
      await _mapController.focusOnPoint(currentFinishLine, zoom: 17);
    }
  }

  void _cancelFinishLinePicker() {
    setState(() => _isPickingFinishLine = false);
  }

  Future<void> _pinFinishLineAtCenter() async {
    final point = await _mapController.centerPoint();
    if (!mounted) {
      return;
    }
    if (point == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Map is still loading. Try again.')),
      );
      return;
    }
    _controller.setFinishLine(point);
    setState(() => _isPickingFinishLine = false);
    if (_controller.navigationOrigin == null) {
      await _controller.focusOnCurrentLocation();
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Expanded map
// ═══════════════════════════════════════════════════════════════════════════
class _ExpandedMapScreen extends StatefulWidget {
  const _ExpandedMapScreen({
    required this.controller,
    required this.mapStyle,
    required this.onStyleChanged,
  });
  final RideTrackingController controller;
  final RydarMapStyle mapStyle;
  final ValueChanged<RydarMapStyle> onStyleChanged;

  @override
  State<_ExpandedMapScreen> createState() => _ExpandedMapScreenState();
}

class _ExpandedMapScreenState extends State<_ExpandedMapScreen> {
  final MapRouteController _mapController = MapRouteController();
  late RydarMapStyle _style;
  bool _isPickingFinishLine = false;

  @override
  void initState() {
    super.initState();
    _style = widget.mapStyle;
    widget.controller.addListener(_rebuild);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: MapRouteView(
              controller: _mapController,
              points: widget.controller.routePoints,
              plannedRoutePoints:
                  widget.controller.plannedRoute?.points ?? const [],
              finishLine: widget.controller.finishLine,
              startLine: widget.controller.startLine,
              bubbleRadiusMeters: widget.controller.geofenceRadiusMeters,
              currentLocation: widget.controller.currentLocation,
              locationFocusRequest: widget.controller.locationFocusRequest,
              followLatestPoint: true,
              borderRadius: 0,
              mapStyle: _style,
            ),
          ),
          const Positioned.fill(child: _MapShade()),
          if (_isPickingFinishLine) const Positioned.fill(child: _CenterPin()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _GlassCircle(
                    tooltip: 'Back',
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  _GlassCircle(
                    tooltip: 'Pin finish line',
                    icon: Icons.add_location_alt_rounded,
                    onTap: _startFinishLinePicker,
                  ),
                  const SizedBox(width: 10),
                  _GlassCircle(
                    tooltip: 'Map style',
                    icon: Icons.layers_rounded,
                    onTap: () {
                      showModalBottomSheet<void>(
                        context: context,
                        backgroundColor: Colors.transparent,
                        builder: (_) => _MapStyleSheet(
                          current: _style,
                          onSelected: (s) {
                            setState(() => _style = s);
                            widget.onStyleChanged(s);
                            Navigator.pop(context);
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          if (!_isPickingFinishLine)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: SafeArea(
                top: false,
                child: _RoutePlannerBar(
                  controller: widget.controller,
                  onOpen: _showRouteSheet,
                ),
              ),
            ),
          if (_isPickingFinishLine)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: SafeArea(
                top: false,
                child: _PinPickerActions(
                  onCancel: _cancelFinishLinePicker,
                  onPin: _pinFinishLineAtCenter,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _startFinishLinePicker() async {
    final currentFinishLine = widget.controller.finishLine;
    setState(() => _isPickingFinishLine = true);
    if (currentFinishLine != null) {
      await _mapController.focusOnPoint(currentFinishLine, zoom: 17);
    }
  }

  void _cancelFinishLinePicker() {
    setState(() => _isPickingFinishLine = false);
  }

  void _showRouteSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ListenableBuilder(
        listenable: widget.controller,
        builder: (ctx, _) => DraggableScrollableSheet(
          initialChildSize: 0.58,
          minChildSize: 0.32,
          maxChildSize: 0.90,
          expand: false,
          builder: (context, scrollController) {
            final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + keyboardInset),
                child: _RouteToolsCard(
                  controller: widget.controller,
                  scrollController: scrollController,
                  onPinOnMap: _startFinishLinePicker,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _pinFinishLineAtCenter() async {
    final point = await _mapController.centerPoint();
    if (!mounted) {
      return;
    }
    if (point == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Map is still loading. Try again.')),
      );
      return;
    }
    widget.controller.setFinishLine(point);
    setState(() => _isPickingFinishLine = false);
    if (widget.controller.navigationOrigin == null) {
      await widget.controller.focusOnCurrentLocation();
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Map style picker sheet
// ═══════════════════════════════════════════════════════════════════════════
class _MapStyleSheet extends StatelessWidget {
  const _MapStyleSheet({required this.current, required this.onSelected});
  final RydarMapStyle current;
  final ValueChanged<RydarMapStyle> onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xF0101010),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.glassBorder(0.12)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Map Style',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: RydarMapStyle.values.map((style) {
                final selected = style == current;
                return GestureDetector(
                  onTap: () => onSelected(style),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 90,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.orange.withValues(alpha: 0.15)
                          : AppColors.glassWhite(0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected
                            ? AppColors.orange
                            : AppColors.glassBorder(0.10),
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          style.icon,
                          size: 26,
                          color: selected ? AppColors.orange : AppColors.text,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          style.label,
                          style: TextStyle(
                            color: selected ? AppColors.orange : AppColors.text,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Ride controls row
// ═══════════════════════════════════════════════════════════════════════════
