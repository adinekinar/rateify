import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/ui_constants.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../../domain/entities/trip_expense.dart';
import '../providers/trip_providers.dart';
import '../widgets/budget_progress_card.dart';
import '../widgets/expense_form_sheet.dart';
import '../widgets/expense_list_item.dart';
import '../widgets/trip_form_sheet.dart';

/// §5.1/§5.5 Trip detail screen: budget progress, expense list, add/edit/
/// delete expense, edit/archive/delete trip.
class TripDetailPage extends ConsumerWidget {
  const TripDetailPage({super.key, required this.tripId});

  final String tripId;

  Future<void> _confirmDeleteTrip(
    BuildContext context,
    WidgetRef ref,
    String tripName,
  ) async {
    // §18.10 — no hidden destructive action.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete trip?'),
        content: Text(
          'This removes "$tripName" and all its expenses permanently.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      ref.read(tripListControllerProvider.notifier).deleteTrip(tripId);
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleMenuAction(
    BuildContext context,
    WidgetRef ref,
    String action,
    TripDetailUiState state,
  ) async {
    switch (action) {
      case 'edit':
        await TripFormSheet.show(context, editing: state.trip);
      case 'archive':
        ref.read(tripListControllerProvider.notifier).archiveTrip(tripId);
        if (context.mounted) Navigator.of(context).pop();
      case 'delete':
        await _confirmDeleteTrip(context, ref, state.trip.name);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(tripDetailControllerProvider(tripId));

    return Scaffold(
      appBar: AppBar(
        title: Text(asyncState.valueOrNull?.trip.name ?? 'Trip'),
        actions: [
          if (asyncState.valueOrNull case final state?)
            PopupMenuButton<String>(
              onSelected: (action) =>
                  _handleMenuAction(context, ref, action, state),
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit trip')),
                PopupMenuItem(value: 'archive', child: Text('Archive trip')),
                PopupMenuItem(value: 'delete', child: Text('Delete trip')),
              ],
            ),
        ],
      ),
      floatingActionButton: asyncState.valueOrNull == null
          ? null
          : FloatingActionButton(
              onPressed: () => ExpenseFormSheet.show(
                context,
                tripId: tripId,
                localCurrencyCode: asyncState.value!.trip.localCurrency,
              ),
              child: const Icon(Icons.add),
            ),
      body: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => const Center(
          child: Text('Something went wrong loading this trip.'),
        ),
        data: (state) => _TripDetailBody(tripId: tripId, state: state),
      ),
    );
  }
}

class _TripDetailBody extends ConsumerWidget {
  const _TripDetailBody({required this.tripId, required this.state});

  final String tripId;
  final TripDetailUiState state;

  Future<void> _confirmDeleteExpense(
    BuildContext context,
    WidgetRef ref,
    TripExpense expense,
  ) async {
    // §18.10 — no hidden destructive action.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete expense?'),
        content: Text('This removes "${expense.title}" permanently.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref
          .read(tripDetailControllerProvider(tripId).notifier)
          .deleteExpense(expense.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final numberFormatPreference = ref.watch(
      appSettingsProvider.select((settings) => settings.numberFormatPreference),
    );

    return Padding(
      padding: const EdgeInsets.all(UiConstants.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BudgetProgressCard(
            state: state,
            numberFormatPreference: numberFormatPreference,
          ),
          const SizedBox(height: UiConstants.gapMd),
          Expanded(
            child: state.expenses.isEmpty
                ? const _EmptyExpensesState()
                : ListView.separated(
                    itemCount: state.expenses.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: UiConstants.gapSm),
                    itemBuilder: (context, index) {
                      final expense = state.expenses[index];
                      return ExpenseListItem(
                        expense: expense,
                        currencyCode: state.trip.localCurrency,
                        numberFormatPreference: numberFormatPreference,
                        onTap: () => ExpenseFormSheet.show(
                          context,
                          tripId: tripId,
                          localCurrencyCode: state.trip.localCurrency,
                          editing: expense,
                        ),
                        onDelete: () =>
                            _confirmDeleteExpense(context, ref, expense),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmptyExpensesState extends StatelessWidget {
  const _EmptyExpensesState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(UiConstants.spaceLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(height: UiConstants.spaceMd),
            Text(
              'Belum ada pengeluaran.',
              style: AppTypography.section(color: theme.colorScheme.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: UiConstants.spaceXs),
            Text(
              'Tambahkan expense pertama untuk melihat progress budget.',
              style: AppTypography.body(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
