import 'package:flutter/material.dart';

import '../../../../core/constants/currency_reference.dart';
import '../../../../core/constants/ui_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// §16.1 CurrencyInputTile.
///
/// Deliberately "dumb": it only renders whatever [displayAmount] string
/// it's given — active-vs-inactive formatting choices (raw input vs.
/// formatted converted amount) are the caller's job, keeping §20.2's
/// raw/display separation entirely out of this widget.
///
/// Reordering uses an explicit drag handle rather than long-press, freeing
/// long-press up for the remove/change-currency menu (§16.1 offers either
/// "long press OR drag handle" for reorder — this picks the handle).
///
/// Compact inactive tile rule (§16.1, added Batch 03c): the active tile
/// keeps its comfortable stacked layout (it's the live typing surface) but
/// an inactive tile collapses to a single compact row — code + short label
/// on one side, amount on the other — since up to 8 full-size tiles plus
/// the keypad don't fit one phone screen. This is also a stronger
/// active/inactive visual distinction than size alone.
class CurrencyInputTile extends StatelessWidget {
  const CurrencyInputTile({
    super.key,
    required this.currencyInfo,
    required this.displayAmount,
    required this.isActive,
    required this.onTap,
    required this.onLongPress,
    this.dragHandle,
  });

  final CurrencyInfo currencyInfo;
  final String displayAmount;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  /// Supplied by the reorderable list (e.g. a `ReorderableDragStartListener`
  /// wrapping a drag icon) — `null` when this tile isn't in a reorderable
  /// context (e.g. isolated widget tests).
  final Widget? dragHandle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(UiConstants.currencyTileRadius),
        onTap: onTap,
        onLongPress: onLongPress,
        child: AnimatedContainer(
          duration: UiConstants.valueChangeAnimationDuration,
          curve: Curves.easeOutCubic,
          padding: isActive
              ? const EdgeInsets.all(UiConstants.spaceMd)
              // Deliberately tighter than the spaceXs token — this is the
              // compact single-row layout (§16.1), where every pixel of
              // vertical padding is directly traded for scroll-free tiles.
              : const EdgeInsets.symmetric(
                  horizontal: UiConstants.spaceMd,
                  vertical: 2,
                ),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary.withValues(alpha: 0.08)
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(UiConstants.currencyTileRadius),
            border: Border.all(
              color: isActive ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
          child: isActive
              ? _buildActiveContent(onSurface)
              : _buildCompactContent(onSurface),
        ),
      ),
    );
  }

  Widget _buildActiveContent(Color onSurface) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    currencyInfo.code,
                    style: AppTypography.currencyCode(color: onSurface),
                  ),
                  const SizedBox(width: UiConstants.spaceSm),
                  Flexible(
                    child: Text(
                      currencyInfo.displayName,
                      style: AppTypography.caption(
                        color: onSurface.withValues(alpha: 0.6),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: UiConstants.spaceXs),
              AnimatedSwitcher(
                duration: UiConstants.valueChangeAnimationDuration,
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeOutCubic,
                child: Text(
                  displayAmount,
                  key: ValueKey(displayAmount),
                  style: AppTypography.display(color: onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        ?dragHandle,
      ],
    );
  }

  /// Single compact row: code + short label on one side, amount on the
  /// other, minimal vertical padding (§16.1 compact inactive tile rule).
  Widget _buildCompactContent(Color onSurface) {
    // Tighter line heights than the shared typography defaults — this row
    // has to fit within a minimal-padding compact tile (§16.1), so its text
    // shouldn't carry more line-box space than it actually needs.
    return Row(
      children: [
        Text(
          currencyInfo.code,
          style: AppTypography.currencyCode(
            color: onSurface,
          ).copyWith(height: 1.0),
        ),
        const SizedBox(width: UiConstants.spaceSm),
        Expanded(
          child: Text(
            currencyInfo.displayName,
            style: AppTypography.caption(
              color: onSurface.withValues(alpha: 0.6),
            ).copyWith(height: 1.0),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: UiConstants.spaceSm),
        AnimatedSwitcher(
          duration: UiConstants.valueChangeAnimationDuration,
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeOutCubic,
          child: Text(
            displayAmount,
            key: ValueKey(displayAmount),
            style: AppTypography.section(
              color: onSurface,
            ).copyWith(height: 1.0),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        ?dragHandle,
      ],
    );
  }
}
