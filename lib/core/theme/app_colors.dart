import 'package:flutter/material.dart';

/// Color tokens from the design system (§15.2).
abstract final class AppColors {
  // Shared brand/semantic tokens.
  static const Color primary = Color(0xFF2557F6);
  static const Color success = Color(0xFF16A34A);
  static const Color danger = Color(0xFFDC2626);
  static const Color warning = Color(0xFFF59E0B);

  // Light theme surfaces.
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceAltLight = Color(0xFFF4F6FA);
  static const Color onSurfaceLight = Color(0xFF111827);
  static const Color subtleLight = Color(0xFF6B7280);

  // Dark theme surfaces.
  static const Color surfaceDark = Color(0xFF0B1020);
  static const Color surfaceAltDark = Color(0xFF111827);
  static const Color onSurfaceDark = Color(0xFFF4F6FA);
  static const Color subtleDark = Color(0xFF9CA3AF);
}
