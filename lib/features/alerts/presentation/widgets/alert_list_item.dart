import 'package:flutter/material.dart';

import '../../../../core/constants/ui_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/rate_alert.dart';

/// `yyyy-MM-dd HH:mm`, matching the converter feature's own manual
/// (non-`intl`) absolute-time formatting in `rate_timestamp_label.dart`.
String formatAlertTimestamp(DateTime dateTime) {
  final y = dateTime.year.toString().padLeft(4, '0');
  final mo = dateTime.month.toString().padLeft(2, '0');
  final d = dateTime.day.toString().padLeft(2, '0');
  final h = dateTime.hour.toString().padLeft(2, '0');
  final mi = dateTime.minute.toString().padLeft(2, '0');
  return '$y-$mo-$d $h:$mi';
}

String directionLabel(AlertDirection direction) => switch (direction) {
  AlertDirection.aboveTarget => 'above',
  AlertDirection.belowTarget => 'below',
};

/// §6.2 — one alert row: pair, target/direction, active toggle, and a
/// small armed/disarmed status hint (§10.8's own suggestion — "reasonable
/// to surface... if convenient").
class AlertListItem extends StatelessWidget {
  const AlertListItem({
    super.key,
    required this.alert,
    required this.onTap,
    required this.onToggleActive,
    required this.onDelete,
    required this.onViewHistory,
  });

  final RateAlert alert;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggleActive;
  final VoidCallback onDelete;
  final VoidCallback onViewHistory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(UiConstants.currencyTileRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(UiConstants.currencyTileRadius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(UiConstants.gapMd),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${alert.baseCurrency}/${alert.quoteCurrency}',
                      style: AppTypography.currencyCode(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: UiConstants.gapXs),
                    Text(
                      'Notify ${directionLabel(alert.direction)} '
                      '${alert.targetRate.toStringAsFixed(2)}',
                      style: AppTypography.body(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: UiConstants.gapXs),
                    Text(
                      alert.isActive
                          ? (alert.isArmed ? 'Armed' : 'Waiting to reset')
                          : 'Inactive',
                      style: AppTypography.caption(
                        color: !alert.isActive
                            ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
                            : alert.isArmed
                            ? AppColors.success
                            : AppColors.warning,
                      ),
                    ),
                    if (alert.lastTriggeredAt != null) ...[
                      const SizedBox(height: UiConstants.gapXs),
                      Text(
                        'Last triggered '
                        '${formatAlertTimestamp(alert.lastTriggeredAt!)}',
                        style: AppTypography.caption(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.history),
                tooltip: 'Trigger history',
                onPressed: onViewHistory,
              ),
              Switch(value: alert.isActive, onChanged: onToggleActive),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Delete',
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
