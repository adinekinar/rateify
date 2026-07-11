import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/currency_reference.dart';
import '../../../../core/constants/ui_constants.dart';
import '../../../../core/formatting/number_formatter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../../domain/entities/currency_tile_state.dart';
import '../providers/converter_controller.dart';
import '../widgets/currency_input_tile.dart';
import '../widgets/currency_picker_sheet.dart';
import '../widgets/custom_keypad.dart';
import '../widgets/rate_timestamp_label.dart';

/// The Core Converter screen (§3) — replaces the Batch 00 placeholder.
class ConverterPage extends ConsumerWidget {
  const ConverterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(converterControllerProvider);
    final isRefreshing = asyncState.valueOrNull?.isRefreshing ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Converter'),
        toolbarHeight: 44,
        actions: [
          if (isRefreshing)
            const Padding(
              padding: EdgeInsets.all(UiConstants.spaceMd),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh rates',
              onPressed: () =>
                  ref.read(converterControllerProvider.notifier).refresh(),
            ),
        ],
      ),
      // §17.5 — loading state is a small, non-blocking spinner.
      body: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => const Center(
          child: Text('Something went wrong loading the converter.'),
        ),
        data: (state) => _ConverterBody(state: state),
      ),
    );
  }
}

class _ConverterBody extends ConsumerWidget {
  const _ConverterBody({required this.state});

  final ConverterUiState state;

  CurrencyInfo _resolveCurrencyInfo(String code) {
    return CurrencyReference.all.firstWhereOrNull(
          (currency) => currency.code == code,
        ) ??
        CurrencyInfo(code: code, displayName: code);
  }

  Future<void> _addCurrency(BuildContext context, WidgetRef ref) async {
    final existingCodes = state.tiles.map((tile) => tile.currencyCode).toSet();
    final picked = await ConverterCurrencyPickerSheet.show(
      context,
      existingCurrencyCodes: existingCodes,
    );
    if (picked == null) return;

    final failure = ref
        .read(converterControllerProvider.notifier)
        .addCurrency(picked);
    if (failure != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(describeTileListMutationFailure(failure))),
      );
    }
  }

  Future<void> _showTileMenu(
    BuildContext context,
    WidgetRef ref,
    CurrencyTileState tile,
  ) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Remove currency'),
              onTap: () => Navigator.of(context).pop('remove'),
            ),
          ],
        ),
      ),
    );
    if (action != 'remove') return;

    final failure = ref
        .read(converterControllerProvider.notifier)
        .removeCurrency(tile.id);
    if (failure != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(describeTileListMutationFailure(failure))),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(converterControllerProvider.notifier);
    final numberFormatPreference = ref.watch(
      appSettingsProvider.select((settings) => settings.numberFormatPreference),
    );

    // Keypad space-filling rule (§16.2, Batch 03d): the tile section hugs
    // its own content height — `Flexible` (loose fit), unlike `Expanded`
    // (tight fit), lets the SingleChildScrollView size itself to content
    // rather than being forced to fill all available space, which was
    // creating a dead gap above the keypad when there were only 2-3 tiles.
    // It still scrolls internally if 8 tiles' worth of content exceeds
    // whatever room is actually available. The keypad is now the `Expanded`
    // element instead, growing to fill whatever's left.
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: UiConstants.spaceMd,
        vertical: UiConstants.spaceXs,
      ),
      child: Column(
        children: [
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (state.rateSnapshot != null)
                    RateTimestampLabel(
                      snapshot: state.rateSnapshot!,
                      errorMessage: state.errorMessage,
                    ),
                  ReorderableListView.builder(
                    // Nested inside the outer SingleChildScrollView, so this
                    // list sizes to its content and defers scrolling to the
                    // ancestor rather than competing with it.
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    buildDefaultDragHandles: false,
                    itemCount: state.tiles.length,
                    // onReorderItem (not the deprecated onReorder) already
                    // pre-adjusts newIndex for the removed item at oldIndex,
                    // which is what ReorderCurrencyTilesUsecase.reorder's
                    // plain removeAt+insert logic expects.
                    onReorderItem: notifier.reorder,
                    itemBuilder: (context, index) {
                      final tile = state.tiles[index];
                      final info = _resolveCurrencyInfo(tile.currencyCode);
                      // Active tile shows the literal raw input as typed;
                      // inactive tiles show the formatted converted amount,
                      // reformatted live from the raw double whenever the
                      // format preference changes (§20.2 — never derived
                      // from a formatted string).
                      final displayAmount = tile.isActiveInput
                          ? tile.rawInput
                          : tile.convertedAmount != null
                          ? formatNumber(
                              tile.convertedAmount!,
                              preference: numberFormatPreference,
                            )
                          : '—';

                      return CurrencyInputTile(
                        key: ValueKey(tile.id),
                        currencyInfo: info,
                        displayAmount: displayAmount,
                        isActive: tile.isActiveInput,
                        onTap: () => notifier.selectTile(tile.id),
                        onLongPress: () => _showTileMenu(context, ref, tile),
                        dragHandle: ReorderableDragStartListener(
                          index: index,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: UiConstants.spaceXs,
                            ),
                            child: Icon(Icons.drag_handle, size: 18),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: UiConstants.spaceSm),
                  _AddCurrencyRow(onTap: () => _addCurrency(context, ref)),
                ],
              ),
            ),
          ),
          const SizedBox(height: UiConstants.spaceSm),
          Expanded(
            child: CustomKeypad(
              onDigit: notifier.appendDigit,
              onDecimal: notifier.appendDecimalSeparator,
              onBackspace: notifier.backspace,
              onClear: notifier.clear,
            ),
          ),
        ],
      ),
    );
  }
}

/// §16.1 compact inactive tile rule: "add currency" is not a separate
/// full-width button — it's a compact row the same height as a compact
/// inactive tile, appended at the end of the tile list, opening the exact
/// same picker sheet (§16.4) as before. Only what triggers the picker
/// changed here, not the picker itself.
class _AddCurrencyRow extends StatelessWidget {
  const _AddCurrencyRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const color = AppColors.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(UiConstants.currencyTileRadius),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: UiConstants.spaceMd,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(UiConstants.currencyTileRadius),
          ),
          child: Row(
            children: [
              const Icon(Icons.add, color: color, size: 18),
              const SizedBox(width: UiConstants.spaceSm),
              Text(
                'Add currency',
                style: AppTypography.section(
                  color: color,
                ).copyWith(height: 1.0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
