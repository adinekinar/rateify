import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/currency_reference.dart';
import '../../../../core/constants/ui_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../settings/presentation/widgets/currency_picker_sheet.dart';
import '../../domain/entities/trip.dart';
import '../providers/trip_providers.dart';

/// Add/edit bottom sheet (§16.4-style — trips aren't explicitly listed
/// there, but a sheet keeps this consistent with every other add/edit flow
/// in the app). `homeCurrency` is never a field here — it's captured
/// silently by `TripListController.createTrip` (§5.2/§20.7) and is not
/// editable afterward, so the edit path never touches it either.
class TripFormSheet extends ConsumerStatefulWidget {
  const TripFormSheet({super.key, this.editing});

  final Trip? editing;

  static Future<void> show(BuildContext context, {Trip? editing}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => TripFormSheet(editing: editing),
    );
  }

  @override
  ConsumerState<TripFormSheet> createState() => _TripFormSheetState();
}

class _TripFormSheetState extends ConsumerState<TripFormSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _budgetController;
  late String _localCurrency;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final editing = widget.editing;
    _nameController = TextEditingController(text: editing?.name ?? '');
    _budgetController = TextEditingController(
      text: editing == null ? '' : editing.totalBudget.toString(),
    );
    _localCurrency = editing?.localCurrency ?? CurrencyReference.all.first.code;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _pickCurrency() async {
    final picked = await CurrencyPickerSheet.show(
      context,
      selectedCode: _localCurrency,
    );
    if (picked != null) setState(() => _localCurrency = picked);
  }

  void _submit() {
    final name = _nameController.text.trim();
    final budget = double.tryParse(_budgetController.text.trim());

    if (name.isEmpty) {
      setState(() => _errorText = 'Trip name is required.');
      return;
    }
    if (budget == null || budget <= 0) {
      setState(() => _errorText = 'Enter a valid budget greater than 0.');
      return;
    }

    final editing = widget.editing;
    final notifier = ref.read(tripListControllerProvider.notifier);
    if (editing == null) {
      notifier.createTrip(
        name: name,
        localCurrency: _localCurrency,
        totalBudget: budget,
      );
    } else {
      notifier.editTrip(
        id: editing.id,
        name: name,
        localCurrency: _localCurrency,
        totalBudget: budget,
      );
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final currencyInfo = CurrencyReference.all.firstWhere(
      (currency) => currency.code == _localCurrency,
    );

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
              widget.editing == null ? 'Add trip' : 'Edit trip',
              style: AppTypography.section(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: UiConstants.spaceMd),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Trip name',
                hintText: 'e.g. Tokyo Trip',
              ),
            ),
            const SizedBox(height: UiConstants.spaceMd),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Local currency'),
              subtitle: Text(
                '${currencyInfo.code} — ${currencyInfo.displayName}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _pickCurrency,
            ),
            const SizedBox(height: UiConstants.spaceMd),
            TextField(
              controller: _budgetController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Total budget'),
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
                child: Text(widget.editing == null ? 'Create' : 'Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
