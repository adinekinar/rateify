/// Shared UI dimension/motion constants (§15.4, §17).
abstract final class UiConstants {
  // Shape radii — §15.4
  static const double cardRadius = 16;
  static const double currencyTileRadius = 12;
  static const double smallButtonRadius = 8;
  static const double bottomSheetTopRadius = 24;
  static const double dialogRadius = 16;

  // Spacing scale
  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 16;
  static const double spaceLg = 24;
  static const double spaceXl = 32;

  // Motion — §17
  static const Duration valueChangeAnimationDuration = Duration(
    milliseconds: 200,
  );
  static const Duration bottomSheetAnimationDuration = Duration(
    milliseconds: 250,
  );
}
