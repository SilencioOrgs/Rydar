import 'dart:ui';

import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  // ── Backgrounds ──────────────────────────────────────────────────────
  static const Color background = Color(0xFF000000);
  static const Color panel = Color(0xFF0F0F0F);
  static const Color panelSoft = Color(0xFF161616);
  static const Color surface = Color(0xFF0A0A0A);
  static const Color surfaceContainerLowest = Color(0xFF0B0C0D);
  static const Color surfaceContainerLow = Color(0xFF141616);
  static const Color surfaceContainer = Color(0xFF1A1C1C);
  static const Color surfaceContainerHigh = Color(0xFF242626);
  static const Color surfaceContainerHighest = Color(0xFF2E3030);

  // ── Brand ────────────────────────────────────────────────────────────
  static const Color orange = Color(0xFFFC4C02); // Strava-inspired primary
  static const Color primaryContainer = Color(0xFFFC4C02);
  static const Color primaryFixedDim = Color(0xFFFF9466);
  static const Color orangeDeep = Color(0xFFE04400);
  static const Color orangeGlow = Color(0xFFFF6A33);

  // ── Text ─────────────────────────────────────────────────────────────
  static const Color text = Color(0xFFF5F5F5);
  static const Color mutedText = Color(0xFF9E9E9E);
  static const Color secondary = Color(0xFFBDBDBD);
  static const Color onSurfaceVariant = Color(0xFFD4A898);
  static const Color outline = Color(0xFF705850);
  static const Color outlineVariant = Color(0xFF3D2E28);
  static const Color divider = Color(0xFF1E1E1E);

  // ── Glassmorphism helpers ────────────────────────────────────────────
  static Color glassWhite([double opacity = 0.06]) =>
      Colors.white.withValues(alpha: opacity);

  static Color glassBorder([double opacity = 0.10]) =>
      Colors.white.withValues(alpha: opacity);

  static ImageFilter get glassBlur => ImageFilter.blur(sigmaX: 24, sigmaY: 24);
}
