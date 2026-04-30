import 'dart:io';

import 'package:flutter/material.dart';
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
import '../home/home_screen.dart';
import '../ride_card/ride_card_screen.dart';

class RideSummaryScreen extends StatefulWidget {
  const RideSummaryScreen({super.key, required this.ride});

  final RideModel ride;

  @override
  State<RideSummaryScreen> createState() => _RideSummaryScreenState();
}

class _RideSummaryScreenState extends State<RideSummaryScreen> {
  late RideModel _ride;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _ride = widget.ride;
  }

  @override
  Widget build(BuildContext context) {
    final cardPath = _ride.rideCardImagePath;

    return Scaffold(
      appBar: AppBar(title: const Text('Ride Summary')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            MapRouteView(points: _ride.routePoints, height: 240),
            const SizedBox(height: 16),
            if (!_ride.hasMeaningfulDistance)
              const _SummaryNotice(
                message:
                    'This ride is too short to save. Track at least 10 meters.',
              ),
            if (!_ride.hasMeaningfulDistance) const SizedBox(height: 14),
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
                  value: DistanceUtils.formatMeters(_ride.distanceMeters),
                ),
                StatCard(
                  label: 'Duration',
                  value: DurationUtils.formatSeconds(_ride.durationSeconds),
                ),
                StatCard(
                  label: 'Avg speed',
                  value:
                      '${SpeedUtils.formatKmh(_ride.averageSpeedMetersPerSecond)} km/h',
                ),
                StatCard(
                  label: 'Max speed',
                  value:
                      '${SpeedUtils.formatKmh(_ride.maxSpeedMetersPerSecond)} km/h',
                ),
              ],
            ),
            if (cardPath != null && File(cardPath).existsSync()) ...[
              const SizedBox(height: 18),
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Image.file(File(cardPath), fit: BoxFit.cover),
              ),
            ],
            const SizedBox(height: 22),
            RydarButton(
              label: 'Add Photo',
              icon: Icons.add_a_photo_rounded,
              secondary: true,
              onPressed: _openRideCard,
            ),
            const SizedBox(height: 12),
            RydarButton(
              label: _saved ? 'Ride Saved' : 'Save Ride',
              icon: Icons.save_rounded,
              onPressed: _ride.hasMeaningfulDistance ? _saveRide : null,
            ),
            const SizedBox(height: 12),
            RydarButton(
              label: 'Share Ride Card',
              icon: Icons.ios_share_rounded,
              secondary: true,
              onPressed: _shareRideCard,
            ),
            const SizedBox(height: 12),
            RydarButton(
              label: 'Back Home',
              icon: Icons.home_rounded,
              secondary: true,
              onPressed: () => Navigator.of(
                context,
              ).popUntil(ModalRoute.withName(HomeScreen.routeName)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveRide() async {
    if (!_ride.hasMeaningfulDistance) {
      _showMessage('Ride is too short to save.');
      return;
    }
    await LocalRideStorage.instance.saveRide(_ride);
    setState(() => _saved = true);
    _showMessage('Ride saved locally.');
  }

  Future<void> _openRideCard() async {
    final updatedRide = await Navigator.of(context).push<RideModel>(
      MaterialPageRoute(builder: (_) => RideCardScreen(ride: _ride)),
    );
    if (updatedRide != null && mounted) {
      setState(() {
        _ride = updatedRide;
        _saved = _ride.hasMeaningfulDistance;
      });
    }
  }

  Future<void> _shareRideCard() async {
    final path = _ride.rideCardImagePath;
    if (path == null || !File(path).existsSync()) {
      await _openRideCard();
      return;
    }
    await SharePlus.instance.share(
      ShareParams(text: 'Rydar ride card', files: [XFile(path)]),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SummaryNotice extends StatelessWidget {
  const _SummaryNotice({required this.message});

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
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
