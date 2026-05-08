import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/distance_utils.dart';
import '../../core/utils/speed_utils.dart';
import '../../data/local/local_ride_storage.dart';
import '../../data/models/ride_model.dart';
import '../../services/auth_service.dart';
import '../../shared/widgets/rydar_logo.dart';
import '../../shared/widgets/rydar_screen_chrome.dart';
import '../../shared/widgets/rydar_stitch_widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  static const routeName = '/profile';

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<RideModel> _rides = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _rides = LocalRideStorage.instance.getRides();
  }

  @override
  Widget build(BuildContext context) {
    final totalDistance = _rides.fold<double>(
      0,
      (sum, ride) => sum + ride.distanceMeters,
    );
    final totalDuration = _rides.fold<int>(
      0,
      (sum, ride) => sum + ride.durationSeconds,
    );
    final averageSpeed = totalDuration == 0
        ? 0.0
        : totalDistance / totalDuration;
    final user = AuthService.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: Stack(
        children: [
          // ── Gradient accent ─────────────────────────────────────────
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.8),
                  radius: 0.9,
                  colors: [
                    AppColors.orange.withValues(alpha: 0.08),
                    AppColors.background,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Column(
              children: [
                const RydarBrandHeader(),
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.orange,
                    backgroundColor: AppColors.panel,
                    onRefresh: () async {
                      setState(() {
                        _rides = LocalRideStorage.instance.getRides();
                      });
                    },
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                      children: [
                        _ProfileHero(user: user),
                        const SizedBox(height: 24),
                        RydarMetricCard(
                          label: 'Total distance',
                          value: _distanceNumber(totalDistance),
                          unit: _distanceUnit(totalDistance),
                          large: true,
                          center: true,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: RydarMetricCard(
                                label: 'Rides completed',
                                value: '${_rides.length}',
                                center: true,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: RydarMetricCard(
                                label: 'Average speed',
                                value: SpeedUtils.formatKmh(averageSpeed),
                                unit: 'km/h',
                                center: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        RydarGlowButton(
                          label: 'Share My Profile',
                          icon: Icons.share_rounded,
                          onPressed: _shareProfile,
                        ),
                        const SizedBox(height: 10),
                        const RydarGlowButton(
                          label: 'Edit Profile',
                          filled: false,
                          enabled: false,
                          onPressed: null,
                        ),
                        const SizedBox(height: 24),
                        Center(
                          child: TextButton(
                            onPressed: user == null ? _goToLogin : _logout,
                            child: Text(
                              user == null ? 'SIGN IN WITH GOOGLE' : 'LOG OUT',
                              style: TextStyle(
                                color: AppColors.orange.withValues(alpha: 0.8),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
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
      bottomNavigationBar: const RydarBottomNav(current: RydarNavItem.profile),
    );
  }

  Future<void> _shareProfile() async {
    final totalDistance = _rides.fold<double>(
      0,
      (sum, ride) => sum + ride.distanceMeters,
    );
    await SharePlus.instance.share(
      ShareParams(
        text:
            '${AuthService.instance.currentUser?.displayName ?? 'Rydar Rider'}\n'
            'Rides completed: ${_rides.length}\n'
            'Total distance: ${DistanceUtils.formatMeters(totalDistance)}',
      ),
    );
  }

  Future<void> _logout() async {
    await AuthService.instance.signOut();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  void _goToLogin() {
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  String _distanceNumber(double meters) {
    final km = meters / 1000;
    if (km >= 10) {
      return km.toStringAsFixed(0);
    }
    return km.toStringAsFixed(1);
  }

  String _distanceUnit(double meters) {
    return meters >= 1000 ? 'KM' : 'KM';
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Profile hero — avatar + name
// ═══════════════════════════════════════════════════════════════════════════
class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.user});

  final User? user;

  @override
  Widget build(BuildContext context) {
    final photoUrl = user?.photoURL;
    final displayName = user?.displayName ?? 'Guest Rider';
    return Column(
      children: [
        // Avatar with glow ring
        Container(
          width: 120,
          height: 120,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.orange,
                AppColors.orangeDeep,
                AppColors.orange.withValues(alpha: 0.6),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.orange.withValues(alpha: 0.25),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.background,
            ),
            child: ClipOval(
              child: photoUrl == null
                  ? const ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        Colors.grey,
                        BlendMode.saturation,
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: RydarLogo(size: 72),
                      ),
                    )
                  : Image.network(photoUrl, fit: BoxFit.cover),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          displayName,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 32,
            height: 1.1,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          user == null ? 'Local tracking mode' : 'Google account connected',
          style: TextStyle(
            color: AppColors.text.withValues(alpha: 0.4),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
