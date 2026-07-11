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
          padding: const EdgeInsets.all(UiConstants.spaceMd),
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
          child: Row(
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
          ),
        ),
      ),
    );
  }
}
