import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography scale from the design system (§15.3).
///
/// Text color is intentionally left to the caller (usually via `Theme.of`)
/// so the same scale works for both light and dark surfaces.
abstract final class AppTypography {
  /// Large converter numbers — 40px / 700 / Inter.
  static TextStyle display({Color? color}) => GoogleFonts.inter(
    fontSize: 40,
    fontWeight: FontWeight.w700,
    color: color,
  );

  /// Screen title — 22px / 700 / Inter.
  static TextStyle title({Color? color}) => GoogleFonts.inter(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: color,
  );

  /// Section header — 18px / 600 / Inter.
  static TextStyle section({Color? color}) => GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: color,
  );

  /// General body text — 16px / 400 / Inter.
  static TextStyle body({Color? color}) => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: color,
  );

  /// Timestamp / helper text — 12px / 400 / Inter.
  static TextStyle caption({Color? color}) => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: color,
  );

  /// Currency code label (e.g. USD, IDR, JPY) — 14px / 600 / JetBrains Mono.
  static TextStyle currencyCode({Color? color}) => GoogleFonts.jetBrainsMono(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: color,
  );
}
