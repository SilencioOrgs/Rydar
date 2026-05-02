import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/distance_utils.dart';
import '../../core/utils/duration_utils.dart';
import '../../core/utils/speed_utils.dart';
import '../../data/local/local_ride_storage.dart';
import '../../data/models/ride_model.dart';
import '../../shared/widgets/rydar_button.dart';
import '../ride_tracking/ride_tracking_screen.dart';
import 'ride_detail_screen.dart';

class RideHistoryScreen extends StatefulWidget {
  const RideHistoryScreen({super.key});

  @override
  State<RideHistoryScreen> createState() => _RideHistoryScreenState();
}

class _RideHistoryScreenState extends State<RideHistoryScreen> {
  List<RideModel> _rides = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _rides = LocalRideStorage.instance.getRides();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Ride History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: _rides.isEmpty
            ? _EmptyHistory(onStartRide: _startRide)
            : _RideList(rides: _rides, onChanged: _load),
      ),
    );
  }

  Future<void> _startRide() async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const RideTrackingScreen()));
    _load();
  }
}

class _RideList extends StatelessWidget {
  const _RideList({required this.rides, required this.onChanged});

  final List<RideModel> rides;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: rides.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final ride = rides[index];
        return Dismissible(
          key: ValueKey(ride.id),
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 22),
            decoration: BoxDecoration(
              color: AppColors.orange,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.delete_rounded, color: Colors.white),
          ),
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction) => _confirmDelete(context, ride),
          onDismissed: (_) async {
            await LocalRideStorage.instance.deleteRide(ride.id);
            onChanged();
          },
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => RideDetailScreen(rideId: ride.id),
                  ),
                );
                onChanged();
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.glassWhite(0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.glassBorder(0.08)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.orange.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.directions_bike_rounded,
                            color: AppColors.orange,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            DateFormat('MMM d, yyyy  h:mm a')
                                .format(ride.dateTime),
                            style: const TextStyle(
                              color: AppColors.text,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.text.withValues(alpha: 0.3),
                          size: 22,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${DistanceUtils.formatMeters(ride.distanceMeters)}  ·  '
                      '${DurationUtils.formatSeconds(ride.durationSeconds)}  ·  '
                      '${SpeedUtils.formatKmh(ride.averageSpeedMetersPerSecond)} km/h',
                      style: TextStyle(
                        color: AppColors.text.withValues(alpha: 0.45),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, RideModel ride) {
    return showDialog<bool>(
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
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({required this.onStartRide});

  final VoidCallback onStartRide;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.glassWhite(0.04),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.glassBorder(0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.route_rounded,
                  color: AppColors.orange,
                  size: 24,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'No rides yet',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Your guest rides will appear here after they are saved locally.',
                style: TextStyle(
                  color: AppColors.text.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        RydarButton(
          label: 'Start Ride',
          icon: Icons.play_arrow_rounded,
          onPressed: onStartRide,
        ),
      ],
    );
  }
}
