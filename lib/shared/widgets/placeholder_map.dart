import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class PlaceholderMap extends StatelessWidget {
  const PlaceholderMap({super.key, this.height});

  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.orange.withValues(alpha: 0.55)),
      ),
      child: const Text(
        'Add your Mapbox access token to enable maps.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.orange,
          fontWeight: FontWeight.w800,
          fontSize: 16,
        ),
      ),
    );
  }
}
