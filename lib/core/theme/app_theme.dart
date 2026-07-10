import 'package:flutter/material.dart';

import '../constants/ui_constants.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// Builds the app's light and dark [ThemeData] from the design tokens in
/// `app_colors.dart` and `app_typography.dart` (§15).
abstract final class AppTheme {
  static ThemeData light() => _build(
    brightness: Brightness.light,
    surface: AppColors.surfaceLight,
    surfaceAlt: AppColors.surfaceAltLight,
    onSurface: AppColors.onSurfaceLight,
    subtle: AppColors.subtleLight,
  );

  static ThemeData dark() => _build(
    brightness: Brightness.dark,
    surface: AppColors.surfaceDark,
    surfaceAlt: AppColors.surfaceAltDark,
    onSurface: AppColors.onSurfaceDark,
    subtle: AppColors.subtleDark,
  );

  static ThemeData _build({
    required Brightness brightness,
    required Color surface,
    required Color surfaceAlt,
    required Color onSurface,
    required Color subtle,
  }) {
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.primary,
      onSecondary: Colors.white,
      error: AppColors.danger,
      onError: Colors.white,
      surface: surface,
      onSurface: onSurface,
      surfaceContainerHighest: surfaceAlt,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: surface,
      textTheme: TextTheme(
        displayLarge: AppTypography.display(color: onSurface),
        titleLarge: AppTypography.title(color: onSurface),
        titleMedium: AppTypography.section(color: onSurface),
        bodyLarge: AppTypography.body(color: onSurface),
        bodySmall: AppTypography.caption(color: subtle),
        labelLarge: AppTypography.currencyCode(color: onSurface),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UiConstants.cardRadius),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(UiConstants.smallButtonRadius),
          ),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(UiConstants.bottomSheetTopRadius),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UiConstants.dialogRadius),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: onSurface,
        elevation: 0,
        titleTextStyle: AppTypography.title(color: onSurface),
      ),
    );
  }
}
