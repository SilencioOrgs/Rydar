import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/distance_utils.dart';
import '../../core/utils/duration_utils.dart';
import '../../core/utils/speed_utils.dart';
import '../../data/local/local_ride_preferences.dart';
import '../../data/local/local_ride_storage.dart';
import '../../data/models/ride_model.dart';
import '../../data/models/scooter_model.dart';
import '../../services/auth_service.dart';
import '../../services/cloud_ride_service.dart';
import '../../shared/widgets/rydar_screen_chrome.dart';
import '../../shared/widgets/motorcycle_category_picker.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  static const routeName = '/leaderboard';

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<RideModel> _rides = const [];
  LeaderboardScope? _scope;
  late ScooterModel _selectedMotorModel;
  String? _selectedMotorModelId;
  bool _loading = true;
  bool _online = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _selectedMotorModelId =
        LocalRidePreferences.instance.motorModelId ??
        ScooterCatalog.defaultModel.id;
    _selectedMotorModel =
        ScooterCatalog.findById(_selectedMotorModelId) ??
        ScooterCatalog.defaultModel;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _message = null;
    });

    final rides = LocalRideStorage.instance.getRides();
    final online = await CloudRideService.instance.isOnline;
    LeaderboardScope? scope;
    String? message;

    if (!online) {
      message = 'Leaderboards are available online only.';
    } else if (AuthService.instance.currentUser == null) {
      message = 'Sign in with Google to view online leaderboards.';
    } else if (rides.isEmpty) {
      message =
          'Save a ${_selectedMotorModel.label} ride to join its weekly location leaderboard.';
    } else {
      try {
        scope = await CloudRideService.instance.fallbackScopeForLatestRide(
          ride: rides.first,
          motorModel: _selectedMotorModel,
        );
      } catch (_) {
        message = 'Could not detect your latest ride location.';
      }
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _rides = rides;
      _online = online;
      _scope = scope;
      _message = message;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scope = _scope;
    final motorSelector = _MotorCategorySelector(
      selected: _selectedMotorModel,
      selectedId: _selectedMotorModelId,
      onSelected: _setMotorModel,
    );
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
                    onPressed: _load,
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
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
                      children: [
                        motorSelector,
                        const SizedBox(height: 16),
                        if (_loading)
                          const _LoadingLeaderboard()
                        else if (!_online || _message != null || scope == null)
                          _OnlineOnlyNotice(message: _message)
                        else
                          _OnlineLeaderboard(scope: scope, localRides: _rides),
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

  Future<void> _setMotorModel(ScooterModel model) async {
    setState(() {
      _selectedMotorModel = model;
      _selectedMotorModelId = model.id;
    });
    await LocalRidePreferences.instance.saveMotorModelId(model.id);
    await _load();
  }
}

class _OnlineLeaderboard extends StatelessWidget {
  const _OnlineLeaderboard({required this.scope, required this.localRides});

  final LeaderboardScope scope;
  final List<RideModel> localRides;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<LeaderboardEntry>>(
      stream: CloudRideService.instance.topEntriesForScope(scope),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _OnlineOnlyNotice(
            message: 'Could not load the online leaderboard right now.',
          );
        }
        final entries = snapshot.data ?? const <LeaderboardEntry>[];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _LeaderboardHero(scope: scope, totalRides: localRides.length),
            const SizedBox(height: 18),
            if (snapshot.connectionState == ConnectionState.waiting)
              const _LoadingLeaderboard()
            else if (entries.isEmpty)
              _OnlineOnlyNotice(
                message:
                    'No weekly entries yet for ${scope.placeName}. Save a ride online to take the first spot.',
              )
            else ...[
              _TopClaim(scope: scope, entry: entries.first),
              const SizedBox(height: 18),
              const _SectionTitle('Top 10 this week'),
              const SizedBox(height: 10),
              ...entries.asMap().entries.map((entry) {
                return _LeaderboardTile(
                  rank: entry.key + 1,
                  entry: entry.value,
                );
              }),
            ],
          ],
        );
      },
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
  const _LeaderboardHero({required this.scope, required this.totalRides});

  final LeaderboardScope scope;
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
                Text(
                  scope.placeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${scope.motorModel.label} ${scope.motorModel.ccLabel} - ${scope.weekId}. $totalRides local rides saved.',
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

class _TopClaim extends StatelessWidget {
  const _TopClaim({required this.scope, required this.entry});

  final LeaderboardScope scope;
  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    final claim =
        'TOP 1 ${scope.motorModel.label.toUpperCase()} IN ${scope.placeName.toUpperCase()} THIS WEEK';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.orange.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            claim,
            style: const TextStyle(
              color: AppColors.orange,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${entry.displayName} - ${entry.topSpeedKmh.toStringAsFixed(1)} km/h',
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () => SharePlus.instance.share(
                ShareParams(
                  text:
                      '$claim\n${entry.displayName}\n${entry.topSpeedKmh.toStringAsFixed(1)} KM/H\nRYDAR',
                ),
              ),
              icon: const Icon(Icons.ios_share_rounded, size: 18),
              label: const Text('SHARE RESULT'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.orange,
                side: const BorderSide(color: AppColors.orange),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  const _LeaderboardTile({required this.rank, required this.entry});

  final int rank;
  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.glassWhite(rank == 1 ? 0.08 : 0.045),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: rank == 1
              ? AppColors.orange.withValues(alpha: 0.48)
              : AppColors.glassBorder(0.08),
        ),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${DistanceUtils.formatMeters(entry.distanceMeters)} - ${DurationUtils.formatSeconds(entry.durationSeconds)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.text.withValues(alpha: 0.48),
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${SpeedUtils.formatKmh(entry.topSpeedKmh / 3.6)} km/h',
            style: TextStyle(
              color: AppColors.text.withValues(alpha: 0.72),
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _MotorCategorySelector extends StatelessWidget {
  const _MotorCategorySelector({
    required this.selected,
    required this.selectedId,
    required this.onSelected,
  });

  final ScooterModel selected;
  final String? selectedId;
  final ValueChanged<ScooterModel> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.glassWhite(0.055),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.glassBorder(0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose motor category',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Honda and Yamaha scooters from 110cc to 160cc.',
            style: TextStyle(
              color: AppColors.text.withValues(alpha: 0.54),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          MotorcycleCategoryPicker(
            selected: selected,
            selectedId: selectedId,
            onSelected: onSelected,
          ),
        ],
      ),
    );
  }
}

class _OnlineOnlyNotice extends StatelessWidget {
  const _OnlineOnlyNotice({this.message});

  final String? message;

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
            Icons.cloud_off_rounded,
            color: AppColors.orange.withValues(alpha: 0.76),
            size: 42,
          ),
          const SizedBox(height: 12),
          const Text(
            'Online leaderboard',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message ?? 'Connect to the internet to load rankings.',
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

class _LoadingLeaderboard extends StatelessWidget {
  const _LoadingLeaderboard();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 80),
      child: Center(child: CircularProgressIndicator(color: AppColors.orange)),
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
