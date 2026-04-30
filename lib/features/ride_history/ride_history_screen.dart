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
      appBar: AppBar(title: const Text('Ride History')),
      body: SafeArea(
        child: _rides.isEmpty
            ? _EmptyHistory(onStartRide: _startRide)
            : _RideList(rides: _rides, onChanged: _load),
      ),
    );
  }

  Future<void> _startRide() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const RideTrackingScreen()));
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
      padding: const EdgeInsets.all(18),
      itemCount: rides.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final ride = rides[index];
        return Dismissible(
          key: ValueKey(ride.id),
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 22),
            decoration: BoxDecoration(
              color: AppColors.orange,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.delete_rounded, color: Colors.black),
          ),
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction) => _confirmDelete(context, ride),
          onDismissed: (_) async {
            await LocalRideStorage.instance.deleteRide(ride.id);
            onChanged();
          },
          child: ListTile(
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => RideDetailScreen(rideId: ride.id),
                ),
              );
              onChanged();
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: AppColors.divider),
            ),
            tileColor: AppColors.panel,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 12,
            ),
            title: Text(
              DateFormat('MMM d, yyyy  h:mm a').format(ride.dateTime),
              style: const TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.w900,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                '${DistanceUtils.formatMeters(ride.distanceMeters)}  |  '
                '${DurationUtils.formatSeconds(ride.durationSeconds)}  |  '
                '${SpeedUtils.formatKmh(ride.averageSpeedMetersPerSecond)} km/h avg',
                style: const TextStyle(
                  color: AppColors.mutedText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.orange,
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
        backgroundColor: AppColors.panel,
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
      padding: const EdgeInsets.all(22),
      children: [
        Container(
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: AppColors.panel,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.divider),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.route_rounded, color: AppColors.orange, size: 44),
              SizedBox(height: 18),
              Text(
                'No rides yet',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Your guest rides will appear here after they are saved locally.',
                style: TextStyle(
                  color: AppColors.mutedText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        RydarButton(
          label: 'Start Ride',
          icon: Icons.play_arrow_rounded,
          onPressed: onStartRide,
        ),
      ],
    );
  }
}
