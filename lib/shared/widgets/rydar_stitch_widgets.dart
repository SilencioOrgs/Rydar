import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/route_point_model.dart';
import 'map_route_view.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  Metric card — glassmorphic stat display
// ═══════════════════════════════════════════════════════════════════════════
class RydarMetricCard extends StatelessWidget {
  const RydarMetricCard({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    this.large = false,
    this.center = false,
    this.icon,
  });

  final String label;
  final String value;
  final String? unit;
  final bool large;
  final bool center;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(large ? 22 : 16),
      decoration: BoxDecoration(
        color: AppColors.glassWhite(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder(large ? 0.12 : 0.08)),
        boxShadow: large
            ? [
                BoxShadow(
                  color: AppColors.orange.withValues(alpha: 0.06),
                  blurRadius: 20,
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment:
            center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                center ? MainAxisAlignment.center : MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: AppColors.orange, size: 16),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label.toUpperCase(),
                  textAlign: center ? TextAlign.center : TextAlign.start,
                  style: TextStyle(
                    color: AppColors.text.withValues(alpha: 0.45),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: center ? Alignment.center : Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: large ? AppColors.orange : AppColors.text,
                    fontSize: large ? 40 : 30,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                if (unit != null) ...[
                  const SizedBox(width: 5),
                  Text(
                    unit!,
                    style: TextStyle(
                      color: AppColors.text.withValues(alpha: 0.4),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Settings row — clean Strava-style list item
// ═══════════════════════════════════════════════════════════════════════════
class RydarSettingsRow extends StatelessWidget {
  const RydarSettingsRow({
    super.key,
    required this.icon,
    required this.label,
    this.value,
    this.trailing,
    this.locked = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String? value;
  final Widget? trailing;
  final bool locked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.glassBorder(0.06),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.glassWhite(0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: AppColors.orange.withValues(alpha: locked ? 0.4 : 0.8),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.text.withValues(alpha: locked ? 0.6 : 1),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (trailing != null)
            trailing!
          else ...[
            if (value != null)
              Text(
                value!,
                style: TextStyle(
                  color: AppColors.text.withValues(alpha: 0.4),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            const SizedBox(width: 4),
            Icon(
              locked ? Icons.lock_rounded : Icons.chevron_right_rounded,
              color: locked
                  ? AppColors.text.withValues(alpha: 0.25)
                  : AppColors.text.withValues(alpha: 0.3),
              size: locked ? 16 : 22,
            ),
          ],
        ],
      ),
    );

    if (onTap == null) {
      return Opacity(opacity: locked ? 0.7 : 1, child: content);
    }

    return InkWell(onTap: onTap, child: content);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Route preview card — map with glass overlay
// ═══════════════════════════════════════════════════════════════════════════
class RydarRoutePreviewCard extends StatelessWidget {
  const RydarRoutePreviewCard({
    super.key,
    required this.points,
    this.height = 220,
  });

  final List<RoutePointModel> points;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder(0.10)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.glassWhite(0.04),
              border: Border(
                bottom: BorderSide(color: AppColors.glassBorder(0.08)),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'YOUR ROUTE',
                  style: TextStyle(
                    color: AppColors.text.withValues(alpha: 0.6),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.map_rounded,
                  color: AppColors.orange.withValues(alpha: 0.7),
                  size: 18,
                ),
              ],
            ),
          ),
          SizedBox(
            height: height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                MapRouteView(points: points, borderRadius: 0),
                IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.orange.withValues(alpha: 0.06),
                          Colors.transparent,
                          AppColors.orange.withValues(alpha: 0.03),
                        ],
                      ),
                    ),
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

// ═══════════════════════════════════════════════════════════════════════════
//  Glow button — primary & outlined CTA
// ═══════════════════════════════════════════════════════════════════════════
class RydarGlowButton extends StatelessWidget {
  const RydarGlowButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.filled = true,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool filled;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = enabled ? onPressed : null;
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
        Flexible(child: Text(label.toUpperCase())),
      ],
    );

    final textStyle = const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.8,
    );

    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: filled
            ? FilledButton(
                onPressed: effectiveOnPressed,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.orange,
                  disabledForegroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                  textStyle: textStyle,
                ),
                child: child,
              )
            : OutlinedButton(
                onPressed: effectiveOnPressed,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.text,
                  disabledForegroundColor: AppColors.secondary,
                  side: BorderSide(
                    color: AppColors.glassBorder(0.18),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: textStyle,
                ),
                child: child,
              ),
      ),
    );
  }
}
