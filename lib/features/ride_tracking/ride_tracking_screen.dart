import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/distance_utils.dart';
import '../../core/utils/duration_utils.dart';
import '../../core/utils/speed_utils.dart';
import '../../services/mapbox_service.dart';
import '../../shared/widgets/map_route_view.dart';
import '../../shared/widgets/rydar_button.dart';
import '../../shared/widgets/stat_card.dart';
import '../ride_summary/ride_summary_screen.dart';
import 'ride_tracking_controller.dart';

class RideTrackingScreen extends StatefulWidget {
  const RideTrackingScreen({super.key});

  @override
  State<RideTrackingScreen> createState() => _RideTrackingScreenState();
}

class _RideTrackingScreenState extends State<RideTrackingScreen> {
  late final RideTrackingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = RideTrackingController()..addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onControllerChanged)
      ..dispose();
    super.dispose();
  }

  void _onControllerChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final isIdle = _controller.status == RideTrackingStatus.idle;
    final isTracking = _controller.status == RideTrackingStatus.tracking;
    final isPaused = _controller.status == RideTrackingStatus.paused;
    final isFinishing = _controller.status == RideTrackingStatus.finishing;

    return Scaffold(
      appBar: AppBar(title: const Text('Track Ride')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            MapRouteView(
              points: _controller.routePoints,
              plannedRoutePoints: _controller.plannedRoute?.points ?? const [],
              finishLine: _controller.finishLine,
              onFinishLineSelected: _controller.setFinishLine,
              height: 300,
              followLatestPoint: true,
            ),
            const SizedBox(height: 12),
            _MapToolsCard(
              controller: _controller,
              onExpandMap: _openExpandedMap,
            ),
            const SizedBox(height: 18),
            if (_controller.errorMessage != null) ...[
              _StatusMessage(message: _controller.errorMessage!),
              const SizedBox(height: 14),
            ],
            if (_controller.routeMessage != null) ...[
              _StatusMessage(message: _controller.routeMessage!),
              const SizedBox(height: 14),
            ],
            GridView.count(
              crossAxisCount: 2,
              childAspectRatio: 1.35,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                StatCard(
                  label: 'Distance',
                  value: DistanceUtils.formatMeters(_controller.distanceMeters),
                ),
                StatCard(
                  label: 'Duration',
                  value: DurationUtils.formatSeconds(
                    _controller.durationSeconds,
                  ),
                ),
                StatCard(
                  label: 'Speed',
                  value:
                      '${SpeedUtils.formatKmh(_controller.currentSpeedMetersPerSecond)} km/h',
                ),
                StatCard(
                  label: 'Avg speed',
                  value:
                      '${SpeedUtils.formatKmh(_controller.averageSpeedMetersPerSecond)} km/h',
                ),
                StatCard(
                  label: 'Max speed',
                  value:
                      '${SpeedUtils.formatKmh(_controller.maxSpeedMetersPerSecond)} km/h',
                ),
                StatCard(
                  label: 'GPS points',
                  value: '${_controller.routePoints.length}',
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (isIdle)
              RydarButton(
                label: 'Start',
                icon: Icons.play_arrow_rounded,
                onPressed: () => _controller.start(),
              ),
            if (isTracking) ...[
              RydarButton(
                label: 'Pause',
                icon: Icons.pause_rounded,
                secondary: true,
                onPressed: _controller.pause,
              ),
              const SizedBox(height: 12),
              RydarButton(
                label: 'Finish',
                icon: Icons.flag_rounded,
                onPressed: _finishRide,
              ),
            ],
            if (isPaused) ...[
              RydarButton(
                label: 'Resume',
                icon: Icons.play_arrow_rounded,
                onPressed: _controller.resume,
              ),
              const SizedBox(height: 12),
              RydarButton(
                label: 'Finish',
                icon: Icons.flag_rounded,
                secondary: true,
                onPressed: _finishRide,
              ),
            ],
            if (isFinishing)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: CircularProgressIndicator(color: AppColors.orange),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _finishRide() async {
    final ride = await _controller.finish();
    if (!mounted) {
      return;
    }
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => RideSummaryScreen(ride: ride)),
    );
  }

  Future<void> _openExpandedMap() {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _ExpandedMapScreen(controller: _controller),
      ),
    );
  }
}

class _ExpandedMapScreen extends StatefulWidget {
  const _ExpandedMapScreen({required this.controller});

  final RideTrackingController controller;

  @override
  State<_ExpandedMapScreen> createState() => _ExpandedMapScreenState();
}

class _ExpandedMapScreenState extends State<_ExpandedMapScreen> {
  RideTrackingController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Route Map')),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: MapRouteView(
                points: _controller.routePoints,
                plannedRoutePoints:
                    _controller.plannedRoute?.points ?? const [],
                finishLine: _controller.finishLine,
                onFinishLineSelected: _controller.setFinishLine,
                followLatestPoint: true,
                borderRadius: 0,
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: _MapToolsCard(controller: _controller),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapToolsCard extends StatelessWidget {
  const _MapToolsCard({required this.controller, this.onExpandMap});

  final RideTrackingController controller;
  final VoidCallback? onExpandMap;

  @override
  Widget build(BuildContext context) {
    final plannedRoute = controller.plannedRoute;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flag_rounded, color: Color(0xFF1FDD8B)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  controller.finishLine == null
                      ? 'Tap the map to pin your finish line'
                      : 'Finish line pinned',
                  style: const TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (controller.isPlanningRoute)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: AppColors.orange,
                    strokeWidth: 2,
                  ),
                ),
              if (controller.finishLine != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Clear finish line',
                  onPressed: controller.clearFinishLine,
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
              if (onExpandMap != null) ...[
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: 'Expand map',
                  onPressed: onExpandMap,
                  icon: const Icon(Icons.open_in_full_rounded),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: RouteVehicle.values.map((vehicle) {
              final isSelected = vehicle == controller.selectedVehicle;
              return ChoiceChip(
                selected: isSelected,
                avatar: Icon(
                  _vehicleIcon(vehicle),
                  size: 18,
                  color: isSelected ? AppColors.background : AppColors.text,
                ),
                label: Text(vehicle.label),
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.background : AppColors.text,
                  fontWeight: FontWeight.w800,
                ),
                selectedColor: AppColors.orange,
                backgroundColor: AppColors.panelSoft,
                side: BorderSide(
                  color: isSelected ? AppColors.orange : AppColors.divider,
                ),
                onSelected: (_) => controller.selectVehicle(vehicle),
              );
            }).toList(),
          ),
          if (plannedRoute != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                _RouteStat(
                  icon: Icons.route_rounded,
                  value: DistanceUtils.formatMeters(
                    plannedRoute.distanceMeters,
                  ),
                ),
                const SizedBox(width: 12),
                _RouteStat(
                  icon: Icons.schedule_rounded,
                  value: DurationUtils.formatSeconds(
                    plannedRoute.durationSeconds,
                  ),
                ),
                const Spacer(),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _RouteStat extends StatelessWidget {
  const _RouteStat({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFF38C6FF), size: 18),
        const SizedBox(width: 6),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

IconData _vehicleIcon(RouteVehicle vehicle) {
  return switch (vehicle) {
    RouteVehicle.car => Icons.directions_car_rounded,
    RouteVehicle.motorcycle => Icons.two_wheeler_rounded,
    RouteVehicle.bicycle => Icons.directions_bike_rounded,
    RouteVehicle.walking => Icons.directions_walk_rounded,
  };
}

class _StatusMessage extends StatelessWidget {
  const _StatusMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.orange),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: AppColors.text,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
