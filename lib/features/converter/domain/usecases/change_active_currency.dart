import '../entities/currency_tile_state.dart';

/// §20.1 — the active tile is the sole source of input truth. Switching
/// which tile is active always starts that tile's input fresh at `"0"`;
/// inactive tiles never retain independent input state, so there is
/// deliberately no "remember what I typed before I switched away" behavior.
class ChangeActiveCurrencyUsecase {
  const ChangeActiveCurrencyUsecase();

  List<CurrencyTileState> call({
    required List<CurrencyTileState> tiles,
    required String newActiveTileId,
  }) {
    return [
      for (final tile in tiles)
        if (tile.id == newActiveTileId)
          tile.copyWith(
            isActiveInput: true,
            rawInput: '0',
            clearConvertedAmount: true,
          )
        else
          tile.copyWith(isActiveInput: false),
    ];
  }
}
