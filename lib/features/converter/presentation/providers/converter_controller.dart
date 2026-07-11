import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/id_generator.dart';
import '../../../benchmarks/domain/entities/benchmark_comparison_result.dart';
import '../../../benchmarks/domain/services/benchmark_calculator.dart';
import '../../../benchmarks/presentation/providers/benchmark_providers.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../../data/models/rate_snapshot_model.dart';
import '../../domain/entities/currency_tile_state.dart';
import '../../domain/services/keypad_input_parser.dart';
import '../../domain/usecases/calculate_conversion.dart';
import '../../domain/usecases/change_active_currency.dart';
import '../../domain/usecases/refresh_rates.dart';
import '../../domain/usecases/reorder_currency_tiles.dart';
import 'converter_providers.dart';

/// §13.1 Converter UI State.
class ConverterUiState {
  const ConverterUiState({
    required this.tiles,
    required this.activeTileId,
    this.rateSnapshot,
    this.errorMessage,
    required this.isRefreshing,
    required this.isOffline,
    required this.benchmarkResults,
  });

  final List<CurrencyTileState> tiles;
  final String activeTileId;
  final RateSnapshotModel? rateSnapshot;
  final String? errorMessage;
  final bool isRefreshing;
  final bool isOffline;
  final List<BenchmarkComparisonResult> benchmarkResults;

  ConverterUiState copyWith({bool? isRefreshing}) {
    return ConverterUiState(
      tiles: tiles,
      activeTileId: activeTileId,
      rateSnapshot: rateSnapshot,
      errorMessage: errorMessage,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isOffline: isOffline,
      benchmarkResults: benchmarkResults,
    );
  }
}

/// Maps a rejected tile-list mutation to a user-facing message — exact
/// copy from §3.2b's own examples.
String describeTileListMutationFailure(TileListMutationFailure failure) =>
    switch (failure) {
      TileListMutationFailure.maxTilesReached => 'Maksimum 8 mata uang.',
      TileListMutationFailure.minTilesRequired =>
        'Minimal 2 mata uang diperlukan.',
      TileListMutationFailure.duplicateCurrency =>
        'Mata uang ini sudah ada di daftar.',
    };

/// §12.2 Converter Controller. Owns active-tile state, keypad input,
/// conversion display state, refresh state, and offline/cache label state.
/// Contains no raw API/Hive details — everything goes through the
/// exchange-rate repository and usecases.
class ConverterController extends AsyncNotifier<ConverterUiState> {
  static const _calculateConversion = CalculateConversionUsecase();

  @override
  Future<ConverterUiState> build() async {
    // Read (not watch) — the tile list is seeded once per session from
    // whatever AppSettings held at that moment (§10.4 session-restore
    // rule). Later Settings changes (theme, format, etc.) must not blow
    // away an in-progress converter session.
    final settings = ref.read(appSettingsProvider);
    final repository = ref.read(exchangeRateRepositoryProvider);

    // Benchmarks (Batch 04) can be created/edited/activated from a
    // completely different page while this controller's state sits idle —
    // unlike `numberFormatPreference` (only ever re-read on the next tile
    // mutation), benchmark changes must show up immediately, so listen
    // and recompute in place rather than waiting for the user to type.
    ref.listen(benchmarksProvider, (previous, next) {
      final current = state.valueOrNull;
      if (current == null) return;
      _emit(
        tiles: current.tiles,
        activeTileId: current.activeTileId,
        current: current,
      );
    });

    final tiles = _seedTiles(settings.selectedConverterCurrencies);
    final snapshot = await repository.getSnapshot();

    return _recompute(
      tiles: tiles,
      activeTileId: tiles.first.id,
      snapshot: snapshot,
      isRefreshing: false,
    );
  }

  List<CurrencyTileState> _seedTiles(List<String> currencyCodes) {
    return [
      for (var i = 0; i < currencyCodes.length; i++)
        CurrencyTileState(
          id: IdGenerator.generate(),
          currencyCode: currencyCodes[i],
          isActiveInput: i == 0,
          rawInput: '0',
          convertedAmount: null,
          sortOrder: i,
        ),
    ];
  }

  /// Re-derives display state (converted amounts, offline/error flags) for
  /// [tiles] against [snapshot]. `numberFormatPreference` is read fresh
  /// here (not cached in state — it isn't part of §13.1's shape) so a
  /// Settings change is reflected the next time anything triggers a
  /// recompute, without needing to watch/rebuild this whole controller.
  ConverterUiState _recompute({
    required List<CurrencyTileState> tiles,
    required String activeTileId,
    required RateSnapshotModel snapshot,
    required bool isRefreshing,
  }) {
    final numberFormatPreference = ref
        .read(appSettingsProvider)
        .numberFormatPreference;
    final results = _calculateConversion(
      tiles: tiles,
      activeTileId: activeTileId,
      snapshot: snapshot,
      numberFormatPreference: numberFormatPreference,
    );

    final updatedTiles = tiles.map((tile) {
      if (tile.id == activeTileId) {
        return tile.copyWith(isActiveInput: true, clearConvertedAmount: true);
      }
      final match = results.firstWhereOrNull(
        (r) => r.targetCurrency == tile.currencyCode,
      );
      return tile.copyWith(
        isActiveInput: false,
        convertedAmount: match?.rawConvertedAmount,
        clearConvertedAmount: match == null,
      );
    }).toList();

    final activeTile = tiles.firstWhere((tile) => tile.id == activeTileId);
    final benchmarkResults = BenchmarkCalculator.compareAll(
      benchmarks: ref.read(benchmarksProvider),
      snapshot: snapshot,
      fromCurrency: activeTile.currencyCode,
      fromAmount: double.tryParse(activeTile.rawInput) ?? 0,
      numberFormatPreference: numberFormatPreference,
    );

    return ConverterUiState(
      tiles: updatedTiles,
      activeTileId: activeTileId,
      rateSnapshot: snapshot,
      errorMessage: snapshot.sourceStatus == RateSourceStatus.unavailable
          ? 'You need an internet connection for the first rate fetch.'
          : null,
      isRefreshing: isRefreshing,
      isOffline: snapshot.sourceStatus != RateSourceStatus.freshRemote,
      benchmarkResults: benchmarkResults,
    );
  }

  void selectTile(String tileId) {
    final current = state.valueOrNull;
    if (current == null || current.activeTileId == tileId) return;

    final updatedTiles = const ChangeActiveCurrencyUsecase().call(
      tiles: current.tiles,
      newActiveTileId: tileId,
    );
    _emit(tiles: updatedTiles, activeTileId: tileId, current: current);
  }

  void appendDigit(String digit) =>
      _updateActiveRawInput((raw) => KeypadInputParser.appendDigit(raw, digit));

  void appendDecimalSeparator() =>
      _updateActiveRawInput(KeypadInputParser.appendDecimalSeparator);

  void backspace() => _updateActiveRawInput(KeypadInputParser.backspace);

  void clear() => _updateActiveRawInput((_) => KeypadInputParser.clear());

  void _updateActiveRawInput(String Function(String) transform) {
    final current = state.valueOrNull;
    if (current == null) return;

    final updatedTiles = current.tiles.map((tile) {
      if (tile.id != current.activeTileId) return tile;
      return tile.copyWith(rawInput: transform(tile.rawInput));
    }).toList();

    _emit(
      tiles: updatedTiles,
      activeTileId: current.activeTileId,
      current: current,
    );
  }

  /// §3.6 — reordering must never change the active input amount or
  /// trigger a rate refresh by itself; it only reshuffles `sortOrder` and
  /// persists the new order.
  void reorder(int oldIndex, int newIndex) {
    final current = state.valueOrNull;
    if (current == null) return;

    final reordered = ReorderCurrencyTilesUsecase.reorder(
      current.tiles,
      oldIndex,
      newIndex,
    );
    _persistTileOrder(reordered);
    _emit(
      tiles: reordered,
      activeTileId: current.activeTileId,
      current: current,
    );
  }

  /// Returns `null` on success (state already updated), or the rejection
  /// reason (state unchanged) for the caller to turn into a message.
  TileListMutationFailure? addCurrency(String currencyCode) {
    final current = state.valueOrNull;
    if (current == null) return null;

    final newTile = CurrencyTileState(
      id: IdGenerator.generate(),
      currencyCode: currencyCode,
      isActiveInput: false,
      rawInput: '0',
      convertedAmount: null,
      sortOrder: current.tiles.length,
    );
    final result = ReorderCurrencyTilesUsecase.addTile(
      tiles: current.tiles,
      newTile: newTile,
    );
    if (!result.isSuccess) return result.failure;

    _persistTileOrder(result.tiles!);
    _emit(
      tiles: result.tiles!,
      activeTileId: current.activeTileId,
      current: current,
    );
    return null;
  }

  /// Returns `null` on success (state already updated), or the rejection
  /// reason (state unchanged) for the caller to turn into a message.
  TileListMutationFailure? removeCurrency(String tileId) {
    final current = state.valueOrNull;
    if (current == null) return null;

    final result = ReorderCurrencyTilesUsecase.removeTile(
      tiles: current.tiles,
      tileId: tileId,
    );
    if (!result.isSuccess) return result.failure;

    _persistTileOrder(result.tiles!);
    final newActiveId =
        result.tiles!.firstWhereOrNull((tile) => tile.isActiveInput)?.id ??
        result.tiles!.first.id;
    _emit(tiles: result.tiles!, activeTileId: newActiveId, current: current);
    return null;
  }

  Future<void> refresh() async {
    final current = state.valueOrNull;
    if (current == null) return;

    state = AsyncData(current.copyWith(isRefreshing: true));
    final snapshot = await RefreshRatesUsecase(
      ref.read(exchangeRateRepositoryProvider),
    )();

    final latest = state.valueOrNull ?? current;
    state = AsyncData(
      _recompute(
        tiles: latest.tiles,
        activeTileId: latest.activeTileId,
        snapshot: snapshot,
        isRefreshing: false,
      ),
    );
  }

  void _emit({
    required List<CurrencyTileState> tiles,
    required String activeTileId,
    required ConverterUiState current,
  }) {
    state = AsyncData(
      _recompute(
        tiles: tiles,
        activeTileId: activeTileId,
        snapshot: current.rateSnapshot!,
        isRefreshing: current.isRefreshing,
      ),
    );
  }

  void _persistTileOrder(List<CurrencyTileState> tiles) {
    ref
        .read(appSettingsProvider.notifier)
        .updateSelectedConverterCurrencies(
          tiles.map((tile) => tile.currencyCode).toList(),
        );
  }
}

final converterControllerProvider =
    AsyncNotifierProvider<ConverterController, ConverterUiState>(
      ConverterController.new,
    );
