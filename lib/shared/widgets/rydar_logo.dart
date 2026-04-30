import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';

class RydarLogo extends StatelessWidget {
  const RydarLogo({super.key, this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppAssets.appIcon,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
