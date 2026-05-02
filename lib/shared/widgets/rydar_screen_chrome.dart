import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../features/leaderboard/leaderboard_screen.dart';
import '../../features/ride_tracking/ride_tracking_screen.dart';

enum RydarNavItem { dashboard, map, leaderboard, profile }

// ═══════════════════════════════════════════════════════════════════════════
//  Floating task header (back + title + trailing)
// ═══════════════════════════════════════════════════════════════════════════
class RydarTaskHeader extends StatelessWidget {
  const RydarTaskHeader({
    super.key,
    required this.title,
    this.onBack,
    this.trailing,
    this.centerTitle = true,
  });

  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;
  final bool centerTitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: AppColors.glassBlur,
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: AppColors.glassWhite(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.glassBorder(0.12)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      tooltip: 'Back',
                      onPressed:
                          onBack ?? () => Navigator.of(context).maybePop(),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppColors.text,
                        size: 18,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    textAlign: centerTitle ? TextAlign.center : TextAlign.start,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                SizedBox(
                  width: 40,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: trailing ?? const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Floating brand header (logo + label + trailing action)
// ═══════════════════════════════════════════════════════════════════════════
class RydarBrandHeader extends StatelessWidget {
  const RydarBrandHeader({
    super.key,
    this.label = 'Guest',
    this.leading,
    this.trailing,
  });

  final String label;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: AppColors.glassBlur,
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.glassWhite(0.07),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.glassBorder(0.10)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 56,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child:
                        leading ??
                        Icon(
                          Icons.speed_rounded,
                          color: AppColors.orange.withValues(alpha: 0.8),
                          size: 22,
                        ),
                  ),
                ),
                const Expanded(
                  child: Text(
                    'RYDAR',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.orange,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
                SizedBox(
                  width: 56,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child:
                        trailing ??
                        Text(
                          label.toUpperCase(),
                          style: TextStyle(
                            color: AppColors.text.withValues(alpha: 0.6),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                          ),
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Floating bottom navigation bar — fixes the "BOTTOM OVERFLOWED" issue
// ═══════════════════════════════════════════════════════════════════════════
class RydarBottomNav extends StatelessWidget {
  const RydarBottomNav({super.key, required this.current});

  final RydarNavItem current;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPadding + 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: AppColors.glassBlur,
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.glassWhite(0.08),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.glassBorder(0.12)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _RydarBottomNavButton(
                  item: RydarNavItem.dashboard,
                  current: current,
                  icon: Icons.space_dashboard_rounded,
                  activeIcon: Icons.space_dashboard_rounded,
                  label: 'Home',
                  onTap: () {
                    if (current != RydarNavItem.dashboard) {
                      Navigator.of(
                        context,
                      ).pushNamedAndRemoveUntil('/home', (route) => false);
                    }
                  },
                ),
                _RydarBottomNavButton(
                  item: RydarNavItem.map,
                  current: current,
                  icon: Icons.explore_outlined,
                  activeIcon: Icons.explore_rounded,
                  label: 'Ride',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const RideTrackingScreen(),
                      ),
                    );
                  },
                ),
                _RydarBottomNavButton(
                  item: RydarNavItem.leaderboard,
                  current: current,
                  icon: Icons.leaderboard_outlined,
                  activeIcon: Icons.leaderboard_rounded,
                  label: 'Ranks',
                  onTap: () {
                    if (current != RydarNavItem.leaderboard) {
                      Navigator.of(
                        context,
                      ).pushNamed(LeaderboardScreen.routeName);
                    }
                  },
                ),
                _RydarBottomNavButton(
                  item: RydarNavItem.profile,
                  current: current,
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: 'Profile',
                  onTap: () {
                    if (current != RydarNavItem.profile) {
                      Navigator.of(context).pushNamed('/profile');
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RydarBottomNavButton extends StatelessWidget {
  const _RydarBottomNavButton({
    required this.item,
    required this.current,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.onTap,
  });

  final RydarNavItem item;
  final RydarNavItem current;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isActive = item == current;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.orange.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isActive ? activeIcon : icon,
                key: ValueKey(isActive),
                color: isActive
                    ? AppColors.orange
                    : AppColors.text.withValues(alpha: 0.45),
                size: 24,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isActive
                    ? AppColors.orange
                    : AppColors.text.withValues(alpha: 0.45),
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
