import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/currency_reference.dart';
import '../../../../core/constants/ui_constants.dart';
import '../../../../core/formatting/number_formatter.dart';
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

    // The tile list (+ its timestamp label and "Add currency" button) is the
    // ONLY scrollable/flexible region on this page. It lives inside Expanded
    // so it can never push the keypad off-screen or force the whole page to
    // scroll; a SingleChildScrollView inside that Expanded lets the tile
    // section itself scroll if it doesn't fit (e.g. many tiles, or a very
    // short device), while the keypad below stays outside any scroll view,
    // in its own fixed-height region that Flutter always lays out in full.
    return Padding(
      padding: const EdgeInsets.all(UiConstants.spaceMd),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (state.rateSnapshot != null)
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: UiConstants.spaceSm,
                      ),
                      child: RateTimestampLabel(
                        snapshot: state.rateSnapshot!,
                        errorMessage: state.errorMessage,
                      ),
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

                      return Padding(
                        key: ValueKey(tile.id),
                        padding: const EdgeInsets.only(
                          bottom: UiConstants.spaceSm,
                        ),
                        child: CurrencyInputTile(
                          currencyInfo: info,
                          displayAmount: displayAmount,
                          isActive: tile.isActiveInput,
                          onTap: () => notifier.selectTile(tile.id),
                          onLongPress: () => _showTileMenu(context, ref, tile),
                          dragHandle: ReorderableDragStartListener(
                            index: index,
                            child: const Padding(
                              padding: EdgeInsets.all(UiConstants.spaceSm),
                              child: Icon(Icons.drag_handle),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: UiConstants.spaceSm),
                  OutlinedButton.icon(
                    onPressed: () => _addCurrency(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Add currency'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: UiConstants.spaceMd),
          CustomKeypad(
            onDigit: notifier.appendDigit,
            onDecimal: notifier.appendDecimalSeparator,
            onBackspace: notifier.backspace,
            onClear: notifier.clear,
          ),
        ],
      ),
    );
  }
}
