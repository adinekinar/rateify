import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/currency_reference.dart';
import '../../../../core/constants/ui_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../settings/presentation/widgets/currency_picker_sheet.dart';
import '../../domain/entities/alert_trigger_history.dart';
import '../../domain/entities/rate_alert.dart';
import '../providers/alert_providers.dart';
import '../widgets/alert_list_item.dart';

/// §6.2/§6.6 Rate Alert management screen: full CRUD, activate/deactivate,
/// trigger history view, and the §6.6 empty state.
class AlertPage extends ConsumerWidget {
  const AlertPage({super.key});

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref, {
    RateAlert? editing,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AlertFormSheet(editing: editing),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    RateAlert alert,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete alert?'),
        content: Text(
          'This removes the ${alert.baseCurrency}/${alert.quoteCurrency} '
          'alert and its trigger history permanently.',
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
    if (confirmed == true) {
      ref.read(alertListControllerProvider.notifier).deleteAlert(alert.id);
    }
  }

  void _openHistory(BuildContext context, WidgetRef ref, RateAlert alert) {
    final history = ref
        .read(alertListControllerProvider.notifier)
        .triggerHistoryFor(alert.id);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AlertHistorySheet(alert: alert, history: history),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(alertListControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Rate Alerts')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context, ref),
        child: const Icon(Icons.add),
      ),
      body: alerts.isEmpty
          ? const _EmptyState()
          : ListView.separated(
              padding: const EdgeInsets.all(UiConstants.spaceMd),
              itemCount: alerts.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: UiConstants.spaceSm),
              itemBuilder: (context, index) {
                final alert = alerts[index];
                return AlertListItem(
                  alert: alert,
                  onTap: () => _openForm(context, ref, editing: alert),
                  onToggleActive: (isActive) {
                    final notifier = ref.read(
                      alertListControllerProvider.notifier,
                    );
                    if (isActive) {
                      notifier.activateAlert(alert.id);
                    } else {
                      notifier.deactivateAlert(alert.id);
                    }
                  },
                  onDelete: () => _confirmDelete(context, ref, alert),
                  onViewHistory: () => _openHistory(context, ref, alert),
                );
              },
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

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
              Icons.notifications_none_outlined,
              size: 48,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(height: UiConstants.spaceMd),
            Text(
              'Belum ada rate alert.',
              style: AppTypography.section(color: theme.colorScheme.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: UiConstants.spaceXs),
            Text(
              'Tambahkan alert untuk diberi tahu saat rate mencapai target.',
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

/// Add/edit bottom sheet (§16.4). Both currency pickers reuse the settings
/// feature's plain "pick one" [CurrencyPickerSheet] — same reasoning as the
/// benchmark form's currency picker reuse: neither pair side has an
/// "already in use" concept to guard against.
class _AlertFormSheet extends ConsumerStatefulWidget {
  const _AlertFormSheet({this.editing});

  final RateAlert? editing;

  @override
  ConsumerState<_AlertFormSheet> createState() => _AlertFormSheetState();
}

class _AlertFormSheetState extends ConsumerState<_AlertFormSheet> {
  late final TextEditingController _targetRateController;
  late String _baseCurrency;
  late String _quoteCurrency;
  late AlertDirection _direction;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final editing = widget.editing;
    _targetRateController = TextEditingController(
      text: editing == null ? '' : editing.targetRate.toString(),
    );
    _baseCurrency = editing?.baseCurrency ?? CurrencyReference.all.first.code;
    _quoteCurrency = editing?.quoteCurrency ?? CurrencyReference.all[1].code;
    _direction = editing?.direction ?? AlertDirection.aboveTarget;
  }

  @override
  void dispose() {
    _targetRateController.dispose();
    super.dispose();
  }

  Future<void> _pickBaseCurrency() async {
    final picked = await CurrencyPickerSheet.show(
      context,
      selectedCode: _baseCurrency,
    );
    if (picked != null) setState(() => _baseCurrency = picked);
  }

  Future<void> _pickQuoteCurrency() async {
    final picked = await CurrencyPickerSheet.show(
      context,
      selectedCode: _quoteCurrency,
    );
    if (picked != null) setState(() => _quoteCurrency = picked);
  }

  void _submit() {
    final targetRate = double.tryParse(_targetRateController.text.trim());

    if (_baseCurrency == _quoteCurrency) {
      setState(() => _errorText = 'Base and quote currency must differ.');
      return;
    }
    if (targetRate == null || targetRate <= 0) {
      setState(() => _errorText = 'Enter a valid target rate greater than 0.');
      return;
    }

    final editing = widget.editing;
    final notifier = ref.read(alertListControllerProvider.notifier);
    if (editing == null) {
      notifier.createAlert(
        baseCurrency: _baseCurrency,
        quoteCurrency: _quoteCurrency,
        targetRate: targetRate,
        direction: _direction,
      );
    } else {
      notifier.editAlert(
        id: editing.id,
        baseCurrency: _baseCurrency,
        quoteCurrency: _quoteCurrency,
        targetRate: targetRate,
        direction: _direction,
      );
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final baseInfo = CurrencyReference.all.firstWhere(
      (currency) => currency.code == _baseCurrency,
    );
    final quoteInfo = CurrencyReference.all.firstWhere(
      (currency) => currency.code == _quoteCurrency,
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
              widget.editing == null ? 'Add alert' : 'Edit alert',
              style: AppTypography.section(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: UiConstants.spaceMd),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Base currency'),
              subtitle: Text('${baseInfo.code} — ${baseInfo.displayName}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _pickBaseCurrency,
            ),
            const Divider(height: 1),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Quote currency'),
              subtitle: Text('${quoteInfo.code} — ${quoteInfo.displayName}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _pickQuoteCurrency,
            ),
            const SizedBox(height: UiConstants.spaceMd),
            TextField(
              controller: _targetRateController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Target rate ($_baseCurrency/$_quoteCurrency)',
              ),
            ),
            const SizedBox(height: UiConstants.spaceMd),
            SegmentedButton<AlertDirection>(
              segments: const [
                ButtonSegment(
                  value: AlertDirection.aboveTarget,
                  label: Text('Above'),
                ),
                ButtonSegment(
                  value: AlertDirection.belowTarget,
                  label: Text('Below'),
                ),
              ],
              selected: {_direction},
              onSelectionChanged: (selection) =>
                  setState(() => _direction = selection.first),
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

/// §6.2 "view trigger history" — a read-only bottom sheet listing every
/// past fire for one alert, most recent first.
class _AlertHistorySheet extends StatelessWidget {
  const _AlertHistorySheet({required this.alert, required this.history});

  final RateAlert alert;
  final List<AlertTriggerHistory> history;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(UiConstants.spaceMd),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${alert.baseCurrency}/${alert.quoteCurrency} trigger history',
              style: AppTypography.section(color: theme.colorScheme.onSurface),
            ),
            const SizedBox(height: UiConstants.spaceMd),
            if (history.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: UiConstants.spaceLg,
                ),
                child: Text(
                  'No triggers yet.',
                  style: AppTypography.body(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: history.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: UiConstants.gapSm),
                  itemBuilder: (context, index) {
                    final entry = history[index];
                    return Text(
                      '${entry.triggeredRate.toStringAsFixed(2)} — '
                      '${formatAlertTimestamp(entry.triggeredAt)}',
                      style: AppTypography.body(
                        color: theme.colorScheme.onSurface,
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
