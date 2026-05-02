import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/distance_utils.dart';
import '../../core/utils/duration_utils.dart';
import '../../core/utils/speed_utils.dart';
import '../../data/local/local_ride_storage.dart';
import '../../data/models/ride_model.dart';
import '../../shared/widgets/map_route_view.dart';
import '../../shared/widgets/rydar_button.dart';
import '../../shared/widgets/stat_card.dart';
import '../ride_card/ride_card_screen.dart';

class RideDetailScreen extends StatefulWidget {
  const RideDetailScreen({super.key, required this.rideId});

  final String rideId;

  @override
  State<RideDetailScreen> createState() => _RideDetailScreenState();
}

class _RideDetailScreenState extends State<RideDetailScreen> {
  RideModel? _ride;

  @override
  void initState() {
    super.initState();
    _ride = LocalRideStorage.instance.getRide(widget.rideId);
  }

  @override
  Widget build(BuildContext context) {
    final ride = _ride;
    if (ride == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Ride Detail')),
        body: Center(
          child: Text(
            'Ride not found.',
            style: TextStyle(color: AppColors.text.withValues(alpha: 0.5)),
          ),
        ),
      );
    }

    final cardPath = ride.rideCardImagePath;
    final photoPath = ride.photoPath;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Ride Detail'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              DateFormat('EEEE, MMM d, yyyy  h:mm a').format(ride.dateTime),
              style: TextStyle(
                color: AppColors.orange.withValues(alpha: 0.8),
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: MapRouteView(points: ride.routePoints, height: 220),
            ),
            const SizedBox(height: 14),
            GridView.count(
              crossAxisCount: 2,
              childAspectRatio: 1.4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                StatCard(
                  label: 'Distance',
                  value: DistanceUtils.formatMeters(ride.distanceMeters),
                ),
                StatCard(
                  label: 'Duration',
                  value: DurationUtils.formatSeconds(ride.durationSeconds),
                ),
                StatCard(
                  label: 'Avg speed',
                  value:
                      '${SpeedUtils.formatKmh(ride.averageSpeedMetersPerSecond)} km/h',
                ),
                StatCard(
                  label: 'Max speed',
                  value:
                      '${SpeedUtils.formatKmh(ride.maxSpeedMetersPerSecond)} km/h',
                ),
              ],
            ),
            if (cardPath != null && File(cardPath).existsSync()) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(File(cardPath), fit: BoxFit.cover),
              ),
            ] else if (photoPath != null && File(photoPath).existsSync()) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(File(photoPath), fit: BoxFit.cover),
              ),
            ],
            const SizedBox(height: 20),
            RydarButton(
              label: 'Share Ride Card',
              icon: Icons.ios_share_rounded,
              onPressed: _shareRideCard,
            ),
            const SizedBox(height: 10),
            RydarButton(
              label: 'Delete Ride',
              icon: Icons.delete_rounded,
              secondary: true,
              onPressed: _deleteRide,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareRideCard() async {
    var ride = _ride;
    if (ride == null) {
      return;
    }

    var path = ride.rideCardImagePath;
    if (path == null || !File(path).existsSync()) {
      final rideForCard = ride;
      final updatedRide = await Navigator.of(context).push<RideModel>(
        MaterialPageRoute(builder: (_) => RideCardScreen(ride: rideForCard)),
      );
      if (updatedRide == null) {
        return;
      }
      setState(() => _ride = updatedRide);
      ride = updatedRide;
      path = ride.rideCardImagePath;
    }

    if (path == null || !File(path).existsSync()) {
      return;
    }

    await SharePlus.instance.share(
      ShareParams(text: 'Rydar ride card', files: [XFile(path)]),
    );
  }

  Future<void> _deleteRide() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Delete ride?',
          style: TextStyle(color: AppColors.text),
        ),
        content: const Text(
          'This removes the saved local ride from this device.',
          style: TextStyle(color: AppColors.mutedText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.mutedText),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.orange),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await LocalRideStorage.instance.deleteRide(widget.rideId);
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }
}
