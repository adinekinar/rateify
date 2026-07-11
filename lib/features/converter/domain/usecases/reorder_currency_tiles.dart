import '../../../../core/constants/app_constants.dart';
import '../entities/currency_tile_state.dart';

/// Why a tile-list mutation was rejected (§3.2, §3.2b) — a non-crashing,
/// non-destructive no-op in every case, with a specific reason the
/// presentation layer turns into a user-facing message.
enum TileListMutationFailure {
  maxTilesReached,
  minTilesRequired,
  duplicateCurrency,
}

/// A typed outcome so the presentation layer reacts to *why* a mutation was
/// rejected instead of re-checking tile count/duplicates itself.
class TileListMutationResult {
  const TileListMutationResult.success(this.tiles) : failure = null;

  const TileListMutationResult.rejected(this.failure) : tiles = null;

  final List<CurrencyTileState>? tiles;
  final TileListMutationFailure? failure;

  bool get isSuccess => failure == null;
}

/// Owns every currency-tile list mutation — reorder, add, remove — and the
/// §3.2b min-2/max-8 boundary + §3.2 duplicate-currency checks.
abstract final class ReorderCurrencyTilesUsecase {
  /// Pure reorder — no boundary check applies since tile count is
  /// unchanged. Only `sortOrder` changes; `isActiveInput`/`rawInput` are
  /// left untouched so the active input amount never changes from
  /// reordering alone (§3.6).
  static List<CurrencyTileState> reorder(
    List<CurrencyTileState> tiles,
    int oldIndex,
    int newIndex,
  ) {
    final updated = List<CurrencyTileState>.of(tiles);
    final moved = updated.removeAt(oldIndex);
    updated.insert(newIndex, moved);
    return [
      for (var i = 0; i < updated.length; i++)
        updated[i].copyWith(sortOrder: i),
    ];
  }

  static TileListMutationResult addTile({
    required List<CurrencyTileState> tiles,
    required CurrencyTileState newTile,
  }) {
    if (tiles.length >= AppConstants.maxConverterTileCount) {
      return const TileListMutationResult.rejected(
        TileListMutationFailure.maxTilesReached,
      );
    }
    final isDuplicate = tiles.any(
      (tile) => tile.currencyCode == newTile.currencyCode,
    );
    if (isDuplicate) {
      return const TileListMutationResult.rejected(
        TileListMutationFailure.duplicateCurrency,
      );
    }
    return TileListMutationResult.success([
      ...tiles,
      newTile.copyWith(sortOrder: tiles.length),
    ]);
  }

  static TileListMutationResult removeTile({
    required List<CurrencyTileState> tiles,
    required String tileId,
  }) {
    if (tiles.length <= AppConstants.minConverterTileCount) {
      return const TileListMutationResult.rejected(
        TileListMutationFailure.minTilesRequired,
      );
    }
    final remaining = tiles.where((tile) => tile.id != tileId).toList();
    // Defensive: if the removed tile was active, promote the new first tile
    // so the app never ends up with zero active tiles.
    final hasActive = remaining.any((tile) => tile.isActiveInput);
    final reindexed = [
      for (var i = 0; i < remaining.length; i++)
        remaining[i].copyWith(
          sortOrder: i,
          isActiveInput: !hasActive && i == 0 ? true : null,
        ),
    ];
    return TileListMutationResult.success(reindexed);
  }
}
