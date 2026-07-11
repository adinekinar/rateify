import '../../../../core/formatting/number_formatter.dart';
import '../../data/models/rate_snapshot_model.dart';
import '../entities/conversion_result.dart';
import '../entities/currency_tile_state.dart';
import '../services/conversion_calculator.dart';

/// §3.5 steps 7–8: for the current active tile's amount, produce one
/// [ConversionResult] per other (inactive) tile.
class CalculateConversionUsecase {
  const CalculateConversionUsecase();

  List<ConversionResult> call({
    required List<CurrencyTileState> tiles,
    required String activeTileId,
    required RateSnapshotModel snapshot,
    required NumberFormatPreference numberFormatPreference,
  }) {
    final activeTile = tiles.firstWhere((tile) => tile.id == activeTileId);
    final amount = double.tryParse(activeTile.rawInput) ?? 0;

    final results = <ConversionResult>[];
    for (final tile in tiles) {
      if (tile.id == activeTileId) continue;
      final result = ConversionCalculator.convert(
        snapshot: snapshot,
        amount: amount,
        fromCurrency: activeTile.currencyCode,
        toCurrency: tile.currencyCode,
        numberFormatPreference: numberFormatPreference,
      );
      if (result != null) results.add(result);
    }
    return results;
  }
}
