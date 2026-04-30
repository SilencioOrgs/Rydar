import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/distance_utils.dart';
import '../../data/local/local_ride_storage.dart';
import '../../data/models/ride_model.dart';
import '../../shared/widgets/rydar_button.dart';
import '../../shared/widgets/rydar_logo.dart';
import '../../shared/widgets/stat_card.dart';
import '../ride_history/ride_history_screen.dart';
import '../ride_tracking/ride_tracking_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const routeName = '/home';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<RideModel> _rides = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadStats();
  }

  void _loadStats() {
    setState(() {
      _rides = LocalRideStorage.instance.getRides();
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalDistance = _rides.fold<double>(
      0,
      (sum, ride) => sum + ride.distanceMeters,
    );
    final lastDistance = _rides.isEmpty ? 0.0 : _rides.first.distanceMeters;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.orange,
          backgroundColor: AppColors.panel,
          onRefresh: () async => _loadStats(),
          child: ListView(
            padding: const EdgeInsets.all(22),
            children: [
              Row(
                children: [
                  const RydarLogo(size: 58),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rydar',
                          style: TextStyle(
                            color: AppColors.text,
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'Guest Mode',
                          style: TextStyle(
                            color: AppColors.orange,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      await Navigator.of(
                        context,
                      ).pushNamed(SettingsScreen.routeName);
                      _loadStats();
                    },
                    icon: const Icon(
                      Icons.tune_rounded,
                      color: AppColors.orange,
                    ),
                    tooltip: 'Settings',
                  ),
                ],
              ),
              const SizedBox(height: 38),
              const Text(
                'Night miles. Clean stats. Local only.',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 24),
              GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 1.25,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  StatCard(label: 'Total rides', value: '${_rides.length}'),
                  StatCard(
                    label: 'Total distance',
                    value: DistanceUtils.formatMeters(totalDistance),
                  ),
                  StatCard(
                    label: 'Last ride',
                    value: DistanceUtils.formatMeters(lastDistance),
                  ),
                  const StatCard(label: 'Mode', value: 'Guest'),
                ],
              ),
              const SizedBox(height: 28),
              RydarButton(
                label: 'Start Ride',
                icon: Icons.play_arrow_rounded,
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const RideTrackingScreen(),
                    ),
                  );
                  _loadStats();
                },
              ),
              const SizedBox(height: 12),
              RydarButton(
                label: 'Ride History',
                icon: Icons.history_rounded,
                secondary: true,
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const RideHistoryScreen(),
                    ),
                  );
                  _loadStats();
                },
              ),
              const SizedBox(height: 12),
              RydarButton(
                label: 'Settings',
                icon: Icons.settings_rounded,
                secondary: true,
                onPressed: () =>
                    Navigator.of(context).pushNamed(SettingsScreen.routeName),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
