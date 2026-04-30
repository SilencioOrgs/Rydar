import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/distance_utils.dart';
import '../../core/utils/duration_utils.dart';
import '../../core/utils/speed_utils.dart';
import '../../data/models/ride_model.dart';
import '../../data/models/route_point_model.dart';
import '../../shared/widgets/rydar_logo.dart';

class RideCardWidget extends StatelessWidget {
  const RideCardWidget({super.key, required this.ride});

  final RideModel ride;

  @override
  Widget build(BuildContext context) {
    final photoPath = ride.photoPath;
    return Container(
      width: 1080,
      height: 1350,
      color: AppColors.background,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (photoPath != null && File(photoPath).existsSync())
            Image.file(File(photoPath), fit: BoxFit.cover)
          else
            const _NoPhotoBackdrop(),
          Container(color: Colors.black.withValues(alpha: 0.58)),
          Positioned(
            left: 64,
            right: 64,
            top: 64,
            child: Row(
              children: [
                const RydarLogo(size: 88),
                const SizedBox(width: 22),
                const Expanded(
                  child: Text(
                    'Rydar',
                    style: TextStyle(
                      color: AppColors.orange,
                      fontSize: 56,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  DateFormat('MMM d, yyyy').format(ride.dateTime),
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 64,
            right: 64,
            bottom: 64,
            child: Container(
              padding: const EdgeInsets.all(38),
              decoration: BoxDecoration(
                color: AppColors.panel.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColors.orange, width: 3),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'GUEST RIDE',
                    style: TextStyle(
                      color: AppColors.orange,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '${DistanceUtils.formatKilometers(ride.distanceMeters)} km',
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 92,
                      fontWeight: FontWeight.w900,
                      height: 0.95,
                    ),
                  ),
                  const SizedBox(height: 34),
                  Row(
                    children: [
                      _CardStat(
                        label: 'Duration',
                        value: DurationUtils.formatSeconds(
                          ride.durationSeconds,
                        ),
                      ),
                      _CardStat(
                        label: 'Avg speed',
                        value:
                            '${SpeedUtils.formatKmh(ride.averageSpeedMetersPerSecond)} km/h',
                      ),
                      _CardStat(
                        label: 'Max speed',
                        value:
                            '${SpeedUtils.formatKmh(ride.maxSpeedMetersPerSecond)} km/h',
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    height: 150,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _MiniRoutePainter(ride.routePoints),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardStat extends StatelessWidget {
  const _CardStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: AppColors.orange,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 34,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
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

class _MiniRoutePainter extends CustomPainter {
  const _MiniRoutePainter(this.points);

  final List<RoutePointModel> points;

  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = AppColors.divider
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(22)),
      borderPaint,
    );

    if (points.length < 2) {
      final textPainter = TextPainter(
        text: const TextSpan(
          text: 'Route preview',
          style: TextStyle(
            color: AppColors.orange,
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout(maxWidth: size.width);
      textPainter.paint(
        canvas,
        Offset(
          (size.width - textPainter.width) / 2,
          (size.height - textPainter.height) / 2,
        ),
      );
      return;
    }

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
          26 + ((point.longitude - minLng) / lngRange) * (size.width - 52);
      final y =
          26 +
          (1 - ((point.latitude - minLat) / latRange)) * (size.height - 52);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final glowPaint = Paint()
      ..color = AppColors.orange.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 16;
    final linePaint = Paint()
      ..color = AppColors.orange
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 7;
    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _MiniRoutePainter oldDelegate) =>
      oldDelegate.points != points;
}
