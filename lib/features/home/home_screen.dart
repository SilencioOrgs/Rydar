import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../data/local/local_ride_storage.dart';
import '../../data/models/ride_model.dart';
import '../../shared/widgets/rydar_screen_chrome.dart';
import '../../shared/widgets/rydar_stitch_widgets.dart';
import '../leaderboard/leaderboard_screen.dart';
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
    final thisMonthRides = _rides.where((ride) {
      final now = DateTime.now();
      return ride.dateTime.year == now.year && ride.dateTime.month == now.month;
    }).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: Stack(
        children: [
          // ── Subtle gradient background ──────────────────────────────
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.6),
                  radius: 1.2,
                  colors: [
                    AppColors.orange.withValues(alpha: 0.06),
                    AppColors.background,
                  ],
                ),
              ),
            ),
          ),

          // ── Scrollable content ──────────────────────────────────────
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                RydarBrandHeader(
                  trailing: IconButton(
                    tooltip: 'Settings',
                    onPressed: () async {
                      await Navigator.of(
                        context,
                      ).pushNamed(SettingsScreen.routeName);
                      _loadStats();
                    },
                    icon: Icon(
                      Icons.tune_rounded,
                      color: AppColors.text.withValues(alpha: 0.7),
                      size: 22,
                    ),
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.orange,
                    backgroundColor: AppColors.panel,
                    onRefresh: () async => _loadStats(),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                      children: [
                        // ── Greeting ──────────────────────────────────
                        _DashboardHero(
                          greeting: _greeting(),
                          totalRides: _rides.length,
                          totalDistance: totalDistance,
                          onStartRide: _startRide,
                        ),
                        const SizedBox(height: 20),
                        const _SectionLabel('Ride stats'),
                        const SizedBox(height: 10),

                        // ── Stats grid ───────────────────────────────
                        _DashboardStats(
                          totalRides: _rides.length,
                          thisMonthRides: thisMonthRides,
                          totalDistance: totalDistance,
                          lastDistance: lastDistance,
                        ),
                        const SizedBox(height: 22),
                        const _SectionLabel('Explore'),
                        const SizedBox(height: 10),

                        // ── Quick actions ────────────────────────────
                        _QuickAction(
                          label: 'Ride History',
                          subtitle: '${_rides.length} rides recorded',
                          icon: Icons.timeline_rounded,
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const RideHistoryScreen(),
                              ),
                            );
                            _loadStats();
                          },
                        ),
                        const SizedBox(height: 10),
                        _QuickAction(
                          label: 'Leaderboard',
                          subtitle: 'Local rankings from saved rides',
                          icon: Icons.leaderboard_rounded,
                          onTap: () async {
                            await Navigator.of(
                              context,
                            ).pushNamed(LeaderboardScreen.routeName);
                            _loadStats();
                          },
                        ),
                        const SizedBox(height: 10),
                        _QuickAction(
                          label: 'Settings',
                          subtitle: 'Customize your experience',
                          icon: Icons.settings_rounded,
                          onTap: () async {
                            await Navigator.of(
                              context,
                            ).pushNamed(SettingsScreen.routeName);
                            _loadStats();
                          },
                        ),
                        const SizedBox(height: 32),

                        // ── Tagline ──────────────────────────────────
                        Text(
                          'TRACK. RIDE. SHARE.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.orange.withValues(alpha: 0.35),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3.0,
                          ),
                        ),
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
        current: RydarNavItem.dashboard,
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Future<void> _startRide() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const RideTrackingScreen()));
    _loadStats();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Dashboard stat cards — responsive grid with glass treatment
// ═══════════════════════════════════════════════════════════════════════════
class _DashboardHero extends StatelessWidget {
  const _DashboardHero({
    required this.greeting,
    required this.totalRides,
    required this.totalDistance,
    required this.onStartRide,
  });

  final String greeting;
  final int totalRides;
  final double totalDistance;
  final VoidCallback onStartRide;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.glassWhite(0.06),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.glassBorder(0.10)),
        boxShadow: [
          BoxShadow(
            color: AppColors.orange.withValues(alpha: 0.08),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  greeting,
                  style: TextStyle(
                    color: AppColors.text.withValues(alpha: 0.58),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'LOCAL',
                  style: TextStyle(
                    color: AppColors.orange,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Your ride hub',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 30,
              height: 1.06,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            totalRides == 0
                ? 'Start tracking and your saved rides will build a local profile.'
                : '$totalRides rides saved, ${_km(totalDistance)} km tracked.',
            style: TextStyle(
              color: AppColors.text.withValues(alpha: 0.56),
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed: onStartRide,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('START RIDE'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _km(double meters) =>
      (meters / 1000).toStringAsFixed(meters >= 10000 ? 0 : 1);
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

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

class _DashboardStats extends StatelessWidget {
  const _DashboardStats({
    required this.totalRides,
    required this.thisMonthRides,
    required this.totalDistance,
    required this.lastDistance,
  });

  final int totalRides;
  final int thisMonthRides;
  final double totalDistance;
  final double lastDistance;

  @override
  Widget build(BuildContext context) {
    final cards = [
      RydarMetricCard(
        label: 'Total rides',
        value: '$totalRides',
        unit: 'rides',
        icon: Icons.route_rounded,
      ),
      RydarMetricCard(
        label: 'This month',
        value: '$thisMonthRides',
        unit: 'rides',
        icon: Icons.calendar_month_rounded,
      ),
      RydarMetricCard(
        label: 'Total dist',
        value: _km(totalDistance),
        unit: 'km',
        icon: Icons.straighten_rounded,
      ),
      RydarMetricCard(
        label: 'Last ride',
        value: _km(lastDistance),
        unit: 'km',
        icon: Icons.flag_rounded,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 620 ? 4 : 2;
        final spacing = 12.0;
        final width =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards
              .map((card) => SizedBox(width: width, height: 112, child: card))
              .toList(),
        );
      },
    );
  }

  String _km(double meters) =>
      (meters / 1000).toStringAsFixed(meters >= 10000 ? 0 : 1);
}

// ═══════════════════════════════════════════════════════════════════════════
//  Start ride CTA with pulsing glow
// ═══════════════════════════════════════════════════════════════════════════
// ═══════════════════════════════════════════════════════════════════════════
//  Quick action row with glass card
// ═══════════════════════════════════════════════════════════════════════════
class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.glassWhite(0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.glassBorder(0.08)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.orange, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppColors.text.withValues(alpha: 0.45),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.text.withValues(alpha: 0.3),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
