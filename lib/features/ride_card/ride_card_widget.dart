import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/distance_utils.dart';
import '../../core/utils/duration_utils.dart';
import '../../core/utils/speed_utils.dart';
import '../../data/models/ride_model.dart';
import '../../data/models/route_point_model.dart';

enum RideCardColorTheme {
  orangeBlack,
  redBlack;

  String get label {
    return switch (this) {
      RideCardColorTheme.orangeBlack => 'Orange',
      RideCardColorTheme.redBlack => 'Red',
    };
  }

  Color get accent {
    return switch (this) {
      RideCardColorTheme.orangeBlack => AppColors.orange,
      RideCardColorTheme.redBlack => const Color(0xFFE32828),
    };
  }

  Color get shadow {
    return switch (this) {
      RideCardColorTheme.orangeBlack => const Color(0xFF5A2500),
      RideCardColorTheme.redBlack => const Color(0xFF4E0507),
    };
  }
}

class RideCardWidget extends StatelessWidget {
  const RideCardWidget({
    super.key,
    required this.ride,
    this.colorTheme = RideCardColorTheme.orangeBlack,
  });

  final RideModel ride;
  final RideCardColorTheme colorTheme;

  @override
  Widget build(BuildContext context) {
    final photoPath = ride.photoPath;
    return Container(
      width: 1080,
      height: 1920,
      color: AppColors.background,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (photoPath != null && File(photoPath).existsSync())
            Image.file(File(photoPath), fit: BoxFit.cover)
          else
            const _NoPhotoBackdrop(),
          _RideCardFade(colorTheme: colorTheme),
          if (ride.routePoints.length >= 2)
            Positioned(
              left: 72,
              right: 72,
              bottom: 330,
              height: 360,
              child: CustomPaint(
                painter: _MinimalRoutePainter(
                  points: ride.routePoints,
                  accent: colorTheme.accent,
                ),
              ),
            ),
          Positioned(
            left: 52,
            right: 52,
            bottom: 52,
            child: _RideCardContent(ride: ride, colorTheme: colorTheme),
          ),
        ],
      ),
    );
  }
}

class _RideCardFade extends StatelessWidget {
  const _RideCardFade({required this.colorTheme});

  final RideCardColorTheme colorTheme;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.02),
            Colors.black.withValues(alpha: 0.08),
            Colors.black.withValues(alpha: 0.20),
            colorTheme.shadow.withValues(alpha: 0.70),
            Colors.black.withValues(alpha: 0.96),
          ],
          stops: const [0, 0.45, 0.63, 0.82, 1],
        ),
      ),
    );
  }
}

class _RideCardContent extends StatelessWidget {
  const _RideCardContent({required this.ride, required this.colorTheme});

  final RideModel ride;
  final RideCardColorTheme colorTheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MetricGrid(ride: ride, accent: colorTheme.accent),
        const SizedBox(height: 34),
        Row(
          children: [
            _CardLogo(accent: colorTheme.accent),
            const SizedBox(width: 14),
            Text(
              'RYDAR',
              style: TextStyle(
                color: colorTheme.accent,
                fontSize: 36,
                height: 1,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.ride, required this.accent});

  final RideModel ride;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _TextMetric(
                label: 'Distance',
                value:
                    '${DistanceUtils.formatKilometers(ride.distanceMeters)} km',
                accent: accent,
              ),
            ),
            const SizedBox(width: 42),
            Expanded(
              child: _TextMetric(
                label: 'Avg Speed',
                value:
                    '${SpeedUtils.formatKmh(ride.averageSpeedMetersPerSecond)} kph',
                accent: accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _TextMetric(
                label: 'Top Speed',
                value:
                    '${SpeedUtils.formatKmh(ride.maxSpeedMetersPerSecond)} kph',
                accent: accent,
              ),
            ),
            const SizedBox(width: 42),
            Expanded(
              child: _TextMetric(
                label: 'Duration',
                value: DurationUtils.formatSeconds(ride.durationSeconds),
                accent: accent,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TextMetric extends StatelessWidget {
  const _TextMetric({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            label,
            maxLines: 1,
            style: TextStyle(
              color: accent,
              fontSize: 34,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            maxLines: 1,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 48,
              height: 0.95,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _CardLogo extends StatelessWidget {
  const _CardLogo({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 46,
      child: ColorFiltered(
        colorFilter: ColorFilter.mode(accent, BlendMode.srcIn),
        child: Image.asset(AppAssets.appIconTransparent, fit: BoxFit.contain),
      ),
    );
  }
}

class _MinimalRoutePainter extends CustomPainter {
  const _MinimalRoutePainter({required this.points, required this.accent});

  final List<RoutePointModel> points;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    if (!_hasVisibleShape) {
      return;
    }

    final rect = Rect.fromLTWH(
      size.width * 0.10,
      size.height * 0.08,
      size.width * 0.80,
      size.height * 0.84,
    );
    final path = _routePath(rect);
    final glow = Paint()
      ..color = accent.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 18
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    final line = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 7;

    canvas.drawPath(path, glow);
    canvas.drawPath(path, line);
  }

  Path _routePath(Rect rect) {
    final minLat = points.map((p) => p.latitude).reduce(min);
    final maxLat = points.map((p) => p.latitude).reduce(max);
    final minLng = points.map((p) => p.longitude).reduce(min);
    final maxLng = points.map((p) => p.longitude).reduce(max);
    final latRange = max(0.00001, maxLat - minLat);
    final lngRange = max(0.00001, maxLng - minLng);
    final path = Path();

    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      final x =
          rect.left + ((point.longitude - minLng) / lngRange) * rect.width;
      final y =
          rect.top + (1 - ((point.latitude - minLat) / latRange)) * rect.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    return path;
  }

  bool get _hasVisibleShape {
    final minLat = points.map((p) => p.latitude).reduce(min);
    final maxLat = points.map((p) => p.latitude).reduce(max);
    final minLng = points.map((p) => p.longitude).reduce(min);
    final maxLng = points.map((p) => p.longitude).reduce(max);
    return (maxLat - minLat).abs() > 0.00002 ||
        (maxLng - minLng).abs() > 0.00002;
  }

  @override
  bool shouldRepaint(covariant _MinimalRoutePainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.accent != accent;
}

class _NoPhotoBackdrop extends StatelessWidget {
  const _NoPhotoBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.background),
      child: CustomPaint(painter: _TrackBackdropPainter()),
    );
  }
}

class _TrackBackdropPainter extends CustomPainter {
  const _TrackBackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.orange.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    for (var i = 0; i < 9; i++) {
      final offset = i * 95.0;
      canvas.drawLine(
        Offset(-120, offset),
        Offset(size.width + 120, offset + 360),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
