import 'package:flutter/material.dart';

import '../../../../core/constants/ui_constants.dart';
import '../../../../core/formatting/number_formatter.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/trip_expense.dart';

/// `yyyy-MM-dd`, matching the converter feature's own manual (non-`intl`)
/// absolute-date formatting in `rate_timestamp_label.dart` — reused here by
/// both this list item and the add/edit expense form.
String formatExpenseDate(DateTime dateTime) {
  final y = dateTime.year.toString().padLeft(4, '0');
  final mo = dateTime.month.toString().padLeft(2, '0');
  final d = dateTime.day.toString().padLeft(2, '0');
  return '$y-$mo-$d';
}

IconData iconForExpenseCategory(ExpenseCategory category) => switch (category) {
  ExpenseCategory.food => Icons.restaurant_outlined,
  ExpenseCategory.transport => Icons.directions_car_outlined,
  ExpenseCategory.hotel => Icons.hotel_outlined,
  ExpenseCategory.shopping => Icons.shopping_bag_outlined,
  ExpenseCategory.ticket => Icons.confirmation_number_outlined,
  ExpenseCategory.other => Icons.category_outlined,
};

/// §5.3 — one expense row: category icon, title, amount (local currency),
/// date, and optional note.
class ExpenseListItem extends StatelessWidget {
  const ExpenseListItem({
    super.key,
    required this.expense,
    required this.currencyCode,
    required this.numberFormatPreference,
    required this.onTap,
    required this.onDelete,
  });

  final TripExpense expense;
  final String currencyCode;
  final NumberFormatPreference numberFormatPreference;
  final VoidCallback onTap;
  final VoidCallback onDelete;

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
              Icon(
                iconForExpenseCategory(expense.category),
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              const SizedBox(width: UiConstants.gapSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      expense.title,
                      style: AppTypography.body(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      formatExpenseDate(expense.spentAt),
                      style: AppTypography.caption(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                    if (expense.note != null && expense.note!.isNotEmpty)
                      Text(
                        expense.note!,
                        style: AppTypography.caption(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                '${formatNumber(expense.amountLocal, preference: numberFormatPreference)} '
                '$currencyCode',
                style: AppTypography.body(
                  color: theme.colorScheme.onSurface,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
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
