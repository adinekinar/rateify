/// Shared UI dimension/motion constants (§15.4, §17).
abstract final class UiConstants {
  // Shape radii — §15.4
  static const double cardRadius = 16;
  static const double currencyTileRadius = 12;
  static const double smallButtonRadius = 8;
  static const double bottomSheetTopRadius = 24;
  static const double dialogRadius = 16;

  // Floating nav bar — not an explicit §15.4 token, added for the floating
  // shell nav bar (§15.1/§15.5: flat design, shadow only for floating
  // surfaces).
  static const double floatingNavBarRadius = 28;
  static const double floatingNavBarIndicatorRadius = 20;
  static const double floatingNavBarHeight = 72;

  // Spacing scale
  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 16;
  static const double spaceLg = 24;
  static const double spaceXl = 32;

  // §15.6 Spacing Scale (Batch 04b) — minimum visible gap between adjacent
  // elements, and minimum internal padding inside a tile/card, on dense
  // screens (the Converter page first). `gapXs`/`gapSm` equal `spaceXs`/
  // `spaceSm` above exactly, reused directly; `gapMd`/`gapLg` are their own
  // smaller steps (12/16) rather than reusing `spaceMd`/`spaceLg` (16/24),
  // which remain the general-purpose page-padding scale used by other,
  // already-shipped screens this rule doesn't touch. Gaps are a hard
  // minimum — if honoring them means a small amount of scrolling on the
  // smallest supported screen, that's the correct tradeoff, never shrink
  // these to force zero scroll.
  static const double gapXs = spaceXs;
  static const double gapSm = spaceSm;
  static const double gapMd = 12;
  static const double gapLg = 16;

  // Motion — §17
  static const Duration valueChangeAnimationDuration = Duration(
    milliseconds: 200,
  );
  static const Duration bottomSheetAnimationDuration = Duration(
    milliseconds: 250,
  );
}
