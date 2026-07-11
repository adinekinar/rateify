import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/currency_reference.dart';
import '../../../../core/constants/ui_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../settings/presentation/widgets/currency_picker_sheet.dart';
import '../../domain/entities/benchmark_item.dart';
import '../providers/benchmark_providers.dart';

/// §4.2/§4.4 benchmark management screen: full CRUD plus both real §4.4
/// empty states.
///
/// Design decision (not fully specified by §4.4 itself, which only gives
/// the two message strings without saying exactly where/how each renders
/// on this page): a totally empty benchmark list replaces the whole body
/// with the "zero benchmarks" message, since there is nothing else useful
/// to show. But "benchmarks exist, none active" still shows the full list
/// (with its per-row toggle, so the user can act on the notice) alongside
/// a banner carrying the "none active" message, rather than replacing the
/// list — hiding the very controls needed to fix the empty state would be
/// counterproductive.
class BenchmarkPage extends ConsumerWidget {
  const BenchmarkPage({super.key});

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref, {
    BenchmarkItem? editing,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _BenchmarkFormSheet(editing: editing),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    BenchmarkItem benchmark,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete benchmark?'),
        content: Text('This removes "${benchmark.name}" permanently.'),
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
      ref.read(benchmarksProvider.notifier).delete(benchmark.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final benchmarks = ref.watch(benchmarksProvider);
    final hasAnyActive = benchmarks.any((b) => b.isActive);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage benchmarks')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context, ref),
        child: const Icon(Icons.add),
      ),
      body: benchmarks.isEmpty
          ? const _EmptyState(
              title: 'Belum ada benchmark.',
              subtitle:
                  'Tambahkan barang yang familiar supaya harga lebih mudah dibandingkan.',
            )
          : Column(
              children: [
                if (!hasAnyActive)
                  const _InactiveBanner(
                    title: 'Tidak ada benchmark aktif.',
                    subtitle:
                        'Aktifkan benchmark untuk melihat perbandingan harga nyata.',
                  ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(UiConstants.spaceMd),
                    itemCount: benchmarks.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: UiConstants.spaceSm),
                    itemBuilder: (context, index) {
                      final benchmark = benchmarks[index];
                      return _BenchmarkRow(
                        benchmark: benchmark,
                        onToggleActive: (isActive) {
                          final notifier = ref.read(
                            benchmarksProvider.notifier,
                          );
                          if (isActive) {
                            notifier.activate(benchmark.id);
                          } else {
                            notifier.deactivate(benchmark.id);
                          }
                        },
                        onEdit: () =>
                            _openForm(context, ref, editing: benchmark),
                        onDelete: () => _confirmDelete(context, ref, benchmark),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

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
              Icons.local_offer_outlined,
              size: 48,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(height: UiConstants.spaceMd),
            Text(
              title,
              style: AppTypography.section(color: theme.colorScheme.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: UiConstants.spaceXs),
            Text(
              subtitle,
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

class _InactiveBanner extends StatelessWidget {
  const _InactiveBanner({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        UiConstants.spaceMd,
        UiConstants.spaceMd,
        UiConstants.spaceMd,
        0,
      ),
      padding: const EdgeInsets.all(UiConstants.spaceMd),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(UiConstants.currencyTileRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.body(
              color: theme.colorScheme.onSurface,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: UiConstants.spaceXs),
          Text(
            subtitle,
            style: AppTypography.caption(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _BenchmarkRow extends StatelessWidget {
  const _BenchmarkRow({
    required this.benchmark,
    required this.onToggleActive,
    required this.onEdit,
    required this.onDelete,
  });

  final BenchmarkItem benchmark;
  final ValueChanged<bool> onToggleActive;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(UiConstants.currencyTileRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(UiConstants.currencyTileRadius),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: UiConstants.spaceMd,
            vertical: UiConstants.spaceSm,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      benchmark.name,
                      style: AppTypography.body(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      '${benchmark.price} ${benchmark.currencyCode}',
                      style: AppTypography.caption(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(value: benchmark.isActive, onChanged: onToggleActive),
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

/// Add/edit bottom sheet (§16.4). Reuses the settings feature's
/// [CurrencyPickerSheet] (the plain "pick one, show a checkmark" variant)
/// rather than the converter's disable-existing one — a benchmark's
/// currency has no "already in use" concept to guard against.
class _BenchmarkFormSheet extends ConsumerStatefulWidget {
  const _BenchmarkFormSheet({this.editing});

  final BenchmarkItem? editing;

  @override
  ConsumerState<_BenchmarkFormSheet> createState() =>
      _BenchmarkFormSheetState();
}

class _BenchmarkFormSheetState extends ConsumerState<_BenchmarkFormSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late String _currencyCode;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final editing = widget.editing;
    _nameController = TextEditingController(text: editing?.name ?? '');
    _priceController = TextEditingController(
      text: editing == null ? '' : editing.price.toString(),
    );
    _currencyCode = editing?.currencyCode ?? CurrencyReference.all.first.code;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickCurrency() async {
    final picked = await CurrencyPickerSheet.show(
      context,
      selectedCode: _currencyCode,
    );
    if (picked != null) setState(() => _currencyCode = picked);
  }

  void _submit() {
    final name = _nameController.text.trim();
    final price = double.tryParse(_priceController.text.trim());

    if (name.isEmpty) {
      setState(() => _errorText = 'Name is required.');
      return;
    }
    if (price == null || price <= 0) {
      setState(() => _errorText = 'Enter a valid price greater than 0.');
      return;
    }

    final editing = widget.editing;
    final notifier = ref.read(benchmarksProvider.notifier);
    if (editing == null) {
      notifier.create(name: name, price: price, currencyCode: _currencyCode);
    } else {
      notifier.edit(
        id: editing.id,
        name: name,
        price: price,
        currencyCode: _currencyCode,
      );
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final currencyInfo = CurrencyReference.all.firstWhere(
      (currency) => currency.code == _currencyCode,
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
              widget.editing == null ? 'Add benchmark' : 'Edit benchmark',
              style: AppTypography.section(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: UiConstants.spaceMd),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g. Nasi Padang',
              ),
            ),
            const SizedBox(height: UiConstants.spaceMd),
            TextField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Price'),
            ),
            const SizedBox(height: UiConstants.spaceMd),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Currency'),
              subtitle: Text(
                '${currencyInfo.code} — ${currencyInfo.displayName}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _pickCurrency,
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
