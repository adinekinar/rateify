import 'package:flutter/material.dart';

import '../../../../core/constants/ui_constants.dart';
import '../../../../core/formatting/number_formatter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/services/trip_budget_calculator.dart';
import '../providers/trip_providers.dart';

/// §5.1/§5.4 — spent, remaining, and the progress bar in its normal/warning/
/// danger state, plus the home-currency conversion when it's resolvable.
class BudgetProgressCard extends StatelessWidget {
  const BudgetProgressCard({
    super.key,
    required this.state,
    required this.numberFormatPreference,
  });

  final TripDetailUiState state;
  final NumberFormatPreference numberFormatPreference;

  Color _progressColor(BudgetProgressState progressState) => switch (progressState) {
    BudgetProgressState.normal => AppColors.success,
    BudgetProgressState.warning => AppColors.warning,
    BudgetProgressState.danger => AppColors.danger,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trip = state.trip;
    final progressColor = _progressColor(state.progressState);
    final spentHome = state.spentHomeCurrency;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(UiConstants.gapMd),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(UiConstants.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spent ${formatNumber(state.spentLocal, preference: numberFormatPreference)} '
            '${trip.localCurrency}',
            style: AppTypography.section(color: theme.colorScheme.onSurface),
          ),
          const SizedBox(height: UiConstants.gapXs),
          Text(
            'of ${formatNumber(trip.totalBudget, preference: numberFormatPreference)} '
            '${trip.localCurrency} budget',
            style: AppTypography.caption(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: UiConstants.gapMd),
          ClipRRect(
            borderRadius: BorderRadius.circular(UiConstants.smallButtonRadius),
            child: LinearProgressIndicator(
              value: state.progressRatio.clamp(0, 1).toDouble(),
              minHeight: 8,
              backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
          const SizedBox(height: UiConstants.gapMd),
          Text(
            state.isOverBudget
                ? 'Over budget by '
                      '${formatNumber(state.remainingLocal.abs(), preference: numberFormatPreference)} '
                      '${trip.localCurrency}'
                : 'Remaining '
                      '${formatNumber(state.remainingLocal, preference: numberFormatPreference)} '
                      '${trip.localCurrency}',
            style: AppTypography.body(color: progressColor),
          ),
          if (spentHome != null && trip.localCurrency != trip.homeCurrency) ...[
            const SizedBox(height: UiConstants.gapXs),
            Text(
              '≈ ${formatNumber(spentHome, preference: numberFormatPreference)} '
              '${trip.homeCurrency}',
              style: AppTypography.caption(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
