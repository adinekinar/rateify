import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/ui_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/trip_expense.dart';
import '../providers/trip_providers.dart';
import 'expense_list_item.dart';

/// §5.3/§16.4 add/edit expense bottom sheet. `amountLocal` is always
/// entered and stored in the trip's own local currency (§5.3/§20.4) — this
/// sheet has no currency picker of its own.
class ExpenseFormSheet extends ConsumerStatefulWidget {
  const ExpenseFormSheet({
    super.key,
    required this.tripId,
    required this.localCurrencyCode,
    this.editing,
  });

  final String tripId;
  final String localCurrencyCode;
  final TripExpense? editing;

  static Future<void> show(
    BuildContext context, {
    required String tripId,
    required String localCurrencyCode,
    TripExpense? editing,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => ExpenseFormSheet(
        tripId: tripId,
        localCurrencyCode: localCurrencyCode,
        editing: editing,
      ),
    );
  }

  @override
  ConsumerState<ExpenseFormSheet> createState() => _ExpenseFormSheetState();
}

class _ExpenseFormSheetState extends ConsumerState<ExpenseFormSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late ExpenseCategory _category;
  late DateTime _spentAt;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final editing = widget.editing;
    _titleController = TextEditingController(text: editing?.title ?? '');
    _amountController = TextEditingController(
      text: editing == null ? '' : editing.amountLocal.toString(),
    );
    _noteController = TextEditingController(text: editing?.note ?? '');
    _category = editing?.category ?? ExpenseCategory.other;
    _spentAt = editing?.spentAt ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _spentAt,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _spentAt = picked);
  }

  void _submit() {
    final title = _titleController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());
    final note = _noteController.text.trim();

    if (title.isEmpty) {
      setState(() => _errorText = 'Title is required.');
      return;
    }
    if (amount == null || amount <= 0) {
      setState(() => _errorText = 'Enter a valid amount greater than 0.');
      return;
    }

    final editing = widget.editing;
    final notifier = ref.read(
      tripDetailControllerProvider(widget.tripId).notifier,
    );
    if (editing == null) {
      notifier.addExpense(
        title: title,
        amountLocal: amount,
        category: _category,
        note: note.isEmpty ? null : note,
        spentAt: _spentAt,
      );
    } else {
      notifier.editExpense(
        id: editing.id,
        title: title,
        amountLocal: amount,
        category: _category,
        note: note.isEmpty ? null : note,
        spentAt: _spentAt,
      );
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: UiConstants.spaceMd,
        right: UiConstants.spaceMd,
        top: UiConstants.spaceMd,
        bottom: MediaQuery.of(context).viewInsets.bottom + UiConstants.spaceMd,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.editing == null ? 'Add expense' : 'Edit expense',
              style: AppTypography.section(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: UiConstants.spaceMd),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'e.g. Dinner',
              ),
            ),
            const SizedBox(height: UiConstants.spaceMd),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Amount (${widget.localCurrencyCode})',
              ),
            ),
            const SizedBox(height: UiConstants.spaceMd),
            DropdownButtonFormField<ExpenseCategory>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: [
                for (final category in ExpenseCategory.values)
                  DropdownMenuItem(
                    value: category,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(iconForExpenseCategory(category), size: 18),
                        const SizedBox(width: UiConstants.gapXs),
                        Text(category.name),
                      ],
                    ),
                  ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _category = value);
              },
            ),
            const SizedBox(height: UiConstants.spaceMd),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date'),
              subtitle: Text(formatExpenseDate(_spentAt)),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: _pickDate,
            ),
            const SizedBox(height: UiConstants.spaceMd),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(labelText: 'Note (optional)'),
            ),
            if (_errorText != null) ...[
              const SizedBox(height: UiConstants.spaceXs),
              Text(
                _errorText!,
                style: AppTypography.caption(color: AppColors.danger),
              ),
            ],
            const SizedBox(height: UiConstants.spaceMd),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submit,
                child: Text(widget.editing == null ? 'Add' : 'Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
