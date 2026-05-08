import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/duration_utils.dart';
import '../../core/utils/speed_utils.dart';
import '../../data/local/local_ride_storage.dart';
import '../../data/models/ride_model.dart';
import '../../data/models/route_point_model.dart';
import '../../services/auth_service.dart';
import '../../services/cloud_ride_service.dart';
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          const Positioned.fill(child: _SummaryBackdrop()),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 18),
              children: [
                _HeroResultHeader(ride: _ride),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      if (!_ride.hasMeaningfulDistance) ...[
                        const SizedBox(height: 10),
                        const _SummaryNotice(
                          message:
                              'This ride is too short to save. Track at least 10 meters.',
                        ),
                      ],
                      const SizedBox(height: 14),
                      _PrimaryMetricsRow(ride: _ride),
                      const SizedBox(height: 12),
                      _RouteResultPanel(ride: _ride),
                      const SizedBox(height: 12),
                      _ActionBar(
                        canSave: _ride.hasMeaningfulDistance && !_saved,
                        onCreateCard: _openRideCard,
                        onSave: _saveRide,
                        onDiscard: _discardRide,
                      ),
                      const SizedBox(height: 12),
                      _ShareHint(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveRide() async {
    if (!_ride.hasMeaningfulDistance) {
      _showMessage('Ride is too short to save.');
      return;
    }
    await LocalRideStorage.instance.saveRide(_ride);
    var message = 'Ride saved locally.';
    if (AuthService.instance.currentUser != null ||
        _ride.recordForLeaderboard) {
      try {
        final scope = await CloudRideService.instance
            .saveRideAndSubmitBestSpeed(_ride);
        if (scope != null) {
          message =
              'Ride saved online. Weekly top speed submitted for ${scope.placeName}.';
        }
      } on CloudRideException catch (error) {
        message = 'Ride saved locally. ${error.message}';
      } catch (_) {
        message = 'Ride saved locally. Could not upload online right now.';
      }
    }
    setState(() => _saved = true);
    _showMessage(message);
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

  Future<void> _discardRide() async {
    if (_saved) {
      await LocalRideStorage.instance.deleteRide(_ride.id);
    }
    if (!mounted) {
      return;
    }
    Navigator.of(context).popUntil(ModalRoute.withName(HomeScreen.routeName));
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _HeroResultHeader extends StatelessWidget {
  const _HeroResultHeader({required this.ride});

  final RideModel ride;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: _MountainHeroPainter()),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.10),
                  Colors.black.withValues(alpha: 0.28),
                  Colors.black.withValues(alpha: 0.82),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(painter: _HeroRoutePainter(ride.routePoints)),
          ),
          Positioned(
            left: 0,
            top: 0,
            right: 0,
            child: Container(height: 2, color: AppColors.orange),
          ),
          Positioned(
            left: 12,
            top: 18,
            child: Row(
              children: const [
                Icon(Icons.bolt_rounded, color: AppColors.orange, size: 24),
                SizedBox(width: 4),
                Text(
                  'Rydar',
                  style: TextStyle(
                    color: AppColors.orange,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          Positioned(right: 12, top: 18, child: _DateChip(ride: ride)),
          Positioned(
            left: 12,
            bottom: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'RIDE',
                  style: TextStyle(
                    color: AppColors.orange,
                    fontSize: 20,
                    height: 0.9,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const Text(
                  'COMPLETE!',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 22,
                    height: 0.95,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Great effort. Here are your stats.',
                  style: TextStyle(
                    color: AppColors.text.withValues(alpha: 0.70),
                    fontSize: 10,
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

class _DateChip extends StatelessWidget {
  const _DateChip({required this.ride});

  final RideModel ride;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.orange.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.calendar_month_rounded,
            color: AppColors.orange,
            size: 13,
          ),
          const SizedBox(width: 5),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('MMM d, yyyy').format(ride.dateTime),
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                DateFormat('hh:mm a').format(ride.dateTime),
                style: TextStyle(
                  color: AppColors.text.withValues(alpha: 0.68),
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PrimaryMetricsRow extends StatelessWidget {
  const _PrimaryMetricsRow({required this.ride});

  final RideModel ride;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      _ResultMetricTile(
        icon: Icons.straighten_rounded,
        label: 'Distance',
        value: _distanceNumber(ride.distanceMeters),
        unit: _distanceUnit(ride.distanceMeters),
      ),
      _ResultMetricTile(
        icon: Icons.timer_rounded,
        label: 'Duration',
        value: DurationUtils.formatSeconds(ride.durationSeconds),
        unit: 'h',
      ),
      _ResultMetricTile(
        icon: Icons.speed_rounded,
        label: 'Avg Speed',
        value: SpeedUtils.formatKmh(ride.averageSpeedMetersPerSecond),
        unit: 'km/h',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 360 ? 1 : 3;
        final spacing = 8.0;
        final width =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: metrics
              .map((metric) => SizedBox(width: width, child: metric))
              .toList(),
        );
      },
    );
  }
}

class _ResultMetricTile extends StatelessWidget {
  const _ResultMetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
  });

  final IconData icon;
  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 112,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.glassWhite(0.055),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder(0.10)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.orange, size: 22),
          const SizedBox(height: 8),
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.text.withValues(alpha: 0.82),
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.orange,
                fontSize: 27,
                height: 0.95,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            unit,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteResultPanel extends StatelessWidget {
  const _RouteResultPanel({required this.ride});

  final RideModel ride;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 178,
      decoration: BoxDecoration(
        color: AppColors.glassWhite(0.045),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.glassBorder(0.10)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: CustomPaint(
              painter: _RouteMapPanelPainter(ride.routePoints),
              child: const SizedBox.expand(),
            ),
          ),
          Container(width: 1, color: AppColors.orange.withValues(alpha: 0.35)),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 10, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'YOUR ROUTE',
                    style: TextStyle(
                      color: AppColors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  _RouteDetail(
                    icon: Icons.flag_rounded,
                    label: 'Route points',
                    value: '${ride.routePoints.length}',
                  ),
                  _RouteDetail(
                    icon: Icons.bolt_rounded,
                    label: 'Top speed',
                    value:
                        '${SpeedUtils.formatKmh(ride.maxSpeedMetersPerSecond)} km/h',
                  ),
                  _RouteDetail(
                    icon: Icons.schedule_rounded,
                    label: 'Recorded',
                    value: DateFormat('hh:mm a').format(ride.dateTime),
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

class _RouteDetail extends StatelessWidget {
  const _RouteDetail({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.orange, size: 15),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    color: AppColors.text.withValues(alpha: 0.50),
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
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

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.canSave,
    required this.onCreateCard,
    required this.onSave,
    required this.onDiscard,
  });

  final bool canSave;
  final VoidCallback onCreateCard;
  final VoidCallback onSave;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 380;
        final primary = _SummaryActionButton(
          label: 'Add Photo & Create Card',
          icon: Icons.add_a_photo_rounded,
          filled: true,
          onPressed: onCreateCard,
        );
        final save = _SummaryActionButton(
          label: 'Save Ride',
          icon: Icons.save_rounded,
          enabled: canSave,
          onPressed: onSave,
        );
        final discard = TextButton(
          onPressed: onDiscard,
          child: const Text(
            'DISCARD RIDE',
            style: TextStyle(
              color: AppColors.orange,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        );

        if (compact) {
          return Column(
            children: [
              primary,
              const SizedBox(height: 8),
              save,
              const SizedBox(height: 6),
              discard,
            ],
          );
        }

        return Row(
          children: [
            Expanded(flex: 5, child: primary),
            const SizedBox(width: 8),
            Expanded(flex: 4, child: save),
            const SizedBox(width: 8),
            discard,
          ],
        );
      },
    );
  }
}

class _SummaryActionButton extends StatelessWidget {
  const _SummaryActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.filled = false,
    this.enabled = true,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool filled;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final background = filled ? AppColors.orange : Colors.transparent;
    final foreground = filled ? Colors.black : AppColors.orange;
    return SizedBox(
      height: 54,
      child: TextButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: Icon(icon, size: 18),
        label: Text(
          label.toUpperCase(),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        style: TextButton.styleFrom(
          backgroundColor: enabled
              ? background
              : AppColors.text.withValues(alpha: 0.04),
          foregroundColor: enabled
              ? foreground
              : AppColors.text.withValues(alpha: 0.28),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: filled
                  ? AppColors.orange
                  : AppColors.orange.withValues(alpha: 0.62),
            ),
          ),
          textStyle: const TextStyle(
            fontSize: 9,
            height: 1.05,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _ShareHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.orange.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.share_rounded, color: AppColors.orange, size: 15),
          const SizedBox(width: 8),
          Text(
            'Share your ride with friends!',
            style: TextStyle(
              color: AppColors.text.withValues(alpha: 0.55),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryNotice extends StatelessWidget {
  const _SummaryNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.orange.withValues(alpha: 0.65)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: AppColors.text,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _SummaryBackdrop extends StatelessWidget {
  const _SummaryBackdrop();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _ContourPainter());
  }
}

class _ContourPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.black);
    final paint = Paint()
      ..color = AppColors.orange.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = 0; i < 13; i++) {
      final y = size.height * (0.58 + i * 0.042);
      final path = Path()..moveTo(-20, y);
      for (var x = -20.0; x <= size.width + 30; x += 36) {
        path.lineTo(x, y + math.sin((x / 48) + i) * 14);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MountainHeroPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF050505),
    );

    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [const Color(0xFF111111), const Color(0xFF030303)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, skyPaint);

    final back = Paint()..color = const Color(0xFF171717);
    final mid = Paint()..color = const Color(0xFF0F0F0F);
    final front = Paint()..color = const Color(0xFF060606);

    canvas.drawPath(
      Path()
        ..moveTo(0, size.height * 0.70)
        ..lineTo(size.width * 0.22, size.height * 0.38)
        ..lineTo(size.width * 0.42, size.height * 0.58)
        ..lineTo(size.width * 0.62, size.height * 0.30)
        ..lineTo(size.width, size.height * 0.66)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close(),
      back,
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height * 0.82)
        ..lineTo(size.width * 0.28, size.height * 0.50)
        ..lineTo(size.width * 0.46, size.height * 0.68)
        ..lineTo(size.width * 0.72, size.height * 0.40)
        ..lineTo(size.width, size.height * 0.76)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close(),
      mid,
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height * 0.90)
        ..lineTo(size.width * 0.34, size.height * 0.64)
        ..lineTo(size.width * 0.54, size.height * 0.80)
        ..lineTo(size.width * 0.84, size.height * 0.56)
        ..lineTo(size.width, size.height * 0.72)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close(),
      front,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HeroRoutePainter extends CustomPainter {
  const _HeroRoutePainter(this.points);

  final List<RoutePointModel> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) {
      return;
    }
    final rect = Rect.fromLTWH(
      size.width * 0.30,
      size.height * 0.10,
      size.width * 0.46,
      size.height * 0.74,
    );
    final path = _routePath(points, rect);
    final glow = Paint()
      ..color = AppColors.orange.withValues(alpha: 0.24)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 10
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    final line = Paint()
      ..color = AppColors.orange
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 4;
    canvas.drawPath(path, glow);
    canvas.drawPath(path, line);
    _drawEndpoints(canvas, path, radius: 6);
  }

  @override
  bool shouldRepaint(covariant _HeroRoutePainter oldDelegate) =>
      oldDelegate.points != points;
}

class _RouteMapPanelPainter extends CustomPainter {
  const _RouteMapPanelPainter(this.points);

  final List<RoutePointModel> points;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF070707),
    );
    final gridPaint = Paint()
      ..color = AppColors.text.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = -2; i < 12; i++) {
      final x = i * size.width / 8;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.width * 0.38, size.height),
        gridPaint,
      );
    }
    for (var i = 0; i < 8; i++) {
      final y = i * size.height / 7;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y - size.height * 0.28),
        gridPaint,
      );
    }

    if (points.length < 2) {
      return;
    }
    final rect = Rect.fromLTWH(18, 16, size.width - 36, size.height - 32);
    final path = _routePath(points, rect);
    final glow = Paint()
      ..color = AppColors.orange.withValues(alpha: 0.20)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 12;
    final line = Paint()
      ..color = AppColors.orange
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 4;
    canvas.drawPath(path, glow);
    canvas.drawPath(path, line);
    _drawEndpoints(canvas, path, radius: 5);
  }

  @override
  bool shouldRepaint(covariant _RouteMapPanelPainter oldDelegate) =>
      oldDelegate.points != points;
}

Path _routePath(List<RoutePointModel> points, Rect rect) {
  final minLat = points.map((p) => p.latitude).reduce(math.min);
  final maxLat = points.map((p) => p.latitude).reduce(math.max);
  final minLng = points.map((p) => p.longitude).reduce(math.min);
  final maxLng = points.map((p) => p.longitude).reduce(math.max);
  final latRange = math.max(0.00001, maxLat - minLat);
  final lngRange = math.max(0.00001, maxLng - minLng);
  final path = Path();
  for (var i = 0; i < points.length; i++) {
    final point = points[i];
    final x = rect.left + ((point.longitude - minLng) / lngRange) * rect.width;
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

void _drawEndpoints(Canvas canvas, Path path, {required double radius}) {
  final metrics = path.computeMetrics().toList();
  if (metrics.isEmpty) {
    return;
  }
  final start = metrics.first.getTangentForOffset(0)?.position;
  final end = metrics.last.getTangentForOffset(metrics.last.length)?.position;
  final fill = Paint()..color = AppColors.orange;
  final stroke = Paint()
    ..color = AppColors.text
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  if (start != null) {
    canvas.drawCircle(start, radius, fill);
    canvas.drawCircle(start, radius, stroke);
  }
  if (end != null) {
    canvas.drawCircle(end, radius, fill);
    canvas.drawCircle(end, radius, stroke);
  }
}

String _distanceNumber(double meters) {
  if (meters >= 1000) {
    return (meters / 1000).toStringAsFixed(1);
  }
  return meters.toStringAsFixed(0);
}

String _distanceUnit(double meters) {
  return meters >= 1000 ? 'km' : 'm';
}
