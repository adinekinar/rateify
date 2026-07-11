import '../../../../core/formatting/number_formatter.dart';
import '../../data/models/rate_snapshot_model.dart';
import '../entities/conversion_result.dart';

/// Pure cross-rate math (§3.4) against a single anchored [RateSnapshotModel]
/// (Batch 02 design decision: the cached snapshot is always anchored to one
/// fixed base currency, `USD`). No I/O, no Riverpod — fully unit-testable.
abstract final class ConversionCalculator {
  /// `rate(from→to) = snapshot.rates[to] / snapshot.rates[from]`.
  ///
  /// Identity case: if [fromCurrency] or [toCurrency] is the snapshot's own
  /// `baseCurrency`, its rate is `1.0` rather than looked up — Frankfurter's
  /// response never includes the base currency in its own rates map.
  ///
  /// Returns `null` if a rate can't be resolved (currency absent from the
  /// snapshot — e.g. an `unavailable` snapshot's empty rates map).
  static double? rateBetween({
    required RateSnapshotModel snapshot,
    required String fromCurrency,
    required String toCurrency,
  }) {
    final rateFrom = _rateFromBase(snapshot, fromCurrency);
    final rateTo = _rateFromBase(snapshot, toCurrency);
    if (rateFrom == null || rateTo == null || rateFrom == 0) return null;
    return rateTo / rateFrom;
  }

  static double? _rateFromBase(RateSnapshotModel snapshot, String currency) {
    if (currency == snapshot.baseCurrency) return 1.0;
    return snapshot.rates[currency];
  }

  /// Converts a full-precision [amount] from [fromCurrency] to
  /// [toCurrency], producing a [ConversionResult] with the display string
  /// capped at 2 decimals (§3.4) per [numberFormatPreference] — the raw
  /// value keeps full precision (§20.2). Returns `null` if no rate is
  /// resolvable (caller decides how to render that, e.g. a dash).
  static ConversionResult? convert({
    required RateSnapshotModel snapshot,
    required double amount,
    required String fromCurrency,
    required String toCurrency,
    required NumberFormatPreference numberFormatPreference,
  }) {
    final rate = rateBetween(
      snapshot: snapshot,
      fromCurrency: fromCurrency,
      toCurrency: toCurrency,
    );
    if (rate == null) return null;

    final rawConverted = amount * rate;
    return ConversionResult(
      targetCurrency: toCurrency,
      rawConvertedAmount: rawConverted,
      formattedDisplayValue: formatNumber(
        rawConverted,
        preference: numberFormatPreference,
      ),
      sourceStatus: snapshot.sourceStatus,
    );
  }
}
