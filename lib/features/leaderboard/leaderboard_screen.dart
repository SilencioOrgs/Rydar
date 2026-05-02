import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/distance_utils.dart';
import '../../core/utils/speed_utils.dart';
import '../../data/local/local_ride_storage.dart';
import '../../data/models/ride_model.dart';
import '../../shared/widgets/rydar_screen_chrome.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  static const routeName = '/leaderboard';

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  late List<RideModel> _rides;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _rides = LocalRideStorage.instance.getRides()
      ..sort((a, b) => b.distanceMeters.compareTo(a.distanceMeters));
  }

  @override
  Widget build(BuildContext context) {
    final topRides = _rides.take(3).toList();
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: Stack(
        children: [
          const Positioned.fill(child: _LeaderboardBackdrop()),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                RydarTaskHeader(
                  title: 'Leaderboard',
                  onBack: () => Navigator.of(context).maybePop(),
                  trailing: IconButton(
                    tooltip: 'Refresh',
                    onPressed: () => setState(_load),
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: AppColors.text,
                      size: 20,
                    ),
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.orange,
                    backgroundColor: AppColors.panel,
                    onRefresh: () async => setState(_load),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
                      children: [
                        _LeaderboardHero(totalRides: _rides.length),
                        const SizedBox(height: 18),
                        if (_rides.isEmpty)
                          const _EmptyLeaderboard()
                        else ...[
                          _Podium(rides: topRides),
                          const SizedBox(height: 18),
                          const _SectionTitle('Local rankings'),
                          const SizedBox(height: 10),
                          ..._rides.asMap().entries.map((entry) {
                            return _LeaderboardTile(
                              rank: entry.key + 1,
                              ride: entry.value,
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const RydarBottomNav(
        current: RydarNavItem.leaderboard,
      ),
    );
  }
}

class _LeaderboardBackdrop extends StatelessWidget {
  const _LeaderboardBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.72),
          radius: 1.2,
          colors: [
            AppColors.orange.withValues(alpha: 0.10),
            AppColors.background,
          ],
        ),
      ),
    );
  }
}

class _LeaderboardHero extends StatelessWidget {
  const _LeaderboardHero({required this.totalRides});

  final int totalRides;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.glassWhite(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.glassBorder(0.10)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: AppColors.orange,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Local leaderboard',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  totalRides == 0
                      ? 'Save rides to start ranking your best efforts.'
                      : '$totalRides saved rides ranked by distance.',
                  style: TextStyle(
                    color: AppColors.text.withValues(alpha: 0.58),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Podium extends StatelessWidget {
  const _Podium({required this.rides});

  final List<RideModel> rides;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: List.generate(rides.length, (index) {
            return SizedBox(
              width: compact
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 20) / 3,
              child: _PodiumCard(rank: index + 1, ride: rides[index]),
            );
          }),
        );
      },
    );
  }
}

class _PodiumCard extends StatelessWidget {
  const _PodiumCard({required this.rank, required this.ride});

  final int rank;
  final RideModel ride;

  @override
  Widget build(BuildContext context) {
    final accent = rank == 1
        ? AppColors.orange
        : AppColors.text.withValues(alpha: 0.72);
    return Container(
      height: 136,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.glassWhite(rank == 1 ? 0.08 : 0.045),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: rank == 1
              ? AppColors.orange.withValues(alpha: 0.48)
              : AppColors.glassBorder(0.10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.workspace_premium_rounded, color: accent, size: 20),
              const Spacer(),
              Text(
                '#$rank',
                style: TextStyle(
                  color: accent,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            DistanceUtils.formatMeters(ride.distanceMeters),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${SpeedUtils.formatKmh(ride.averageSpeedMetersPerSecond)} km/h avg',
            style: TextStyle(
              color: AppColors.text.withValues(alpha: 0.50),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  const _LeaderboardTile({required this.rank, required this.ride});

  final int rank;
  final RideModel ride;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.glassWhite(0.045),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder(0.08)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 38,
            child: Text(
              '#$rank',
              style: const TextStyle(
                color: AppColors.orange,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              DistanceUtils.formatMeters(ride.distanceMeters),
              style: const TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ),
          Text(
            '${SpeedUtils.formatKmh(ride.maxSpeedMetersPerSecond)} km/h',
            style: TextStyle(
              color: AppColors.text.withValues(alpha: 0.52),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyLeaderboard extends StatelessWidget {
  const _EmptyLeaderboard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.glassWhite(0.045),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.glassBorder(0.08)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.leaderboard_rounded,
            color: AppColors.orange.withValues(alpha: 0.76),
            size: 42,
          ),
          const SizedBox(height: 12),
          const Text(
            'No rankings yet',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Saved rides will appear here automatically.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.text.withValues(alpha: 0.54),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        color: AppColors.text.withValues(alpha: 0.48),
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.2,
      ),
    );
  }
}
