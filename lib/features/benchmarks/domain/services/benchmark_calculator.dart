import '../../../../core/formatting/number_formatter.dart';
import '../../../converter/data/models/rate_snapshot_model.dart';
import '../../../converter/domain/services/conversion_calculator.dart';
import '../entities/benchmark_comparison_result.dart';
import '../entities/benchmark_item.dart';

/// §4.2 "top" ordering rule + §4.3 benchmark calculation rule. No widget,
/// no Riverpod — independently unit-testable, same discipline as the
/// converter feature's `conversion_calculator.dart`.
abstract final class BenchmarkCalculator {
  /// §4.2 "Top" ordering rule (added in review pass): active benchmarks
  /// ordered by most recent `updatedAt`, falling back to most recent
  /// `createdAt` on a tie. Must be computed here, never by a widget.
  static List<BenchmarkItem> orderActiveByRecency(
    List<BenchmarkItem> benchmarks,
  ) {
    final active = benchmarks.where((b) => b.isActive).toList();
    active.sort((a, b) {
      final byUpdatedAt = b.updatedAt.compareTo(a.updatedAt);
      if (byUpdatedAt != 0) return byUpdatedAt;
      return b.createdAt.compareTo(a.createdAt);
    });
    return active;
  }

  /// §4.3 — converts [fromAmount] (in [fromCurrency]) into [benchmark]'s
  /// own currency via `ConversionCalculator` (Batch 03's cross-rate math,
  /// deliberately not reimplemented here), then divides by the benchmark's
  /// price. Returns `null` if no rate is resolvable for the benchmark's
  /// currency — mirrors `ConversionCalculator.convert`'s own null contract
  /// — or if the benchmark's price isn't positive.
  static BenchmarkComparisonResult? compareOne({
    required BenchmarkItem benchmark,
    required RateSnapshotModel snapshot,
    required String fromCurrency,
    required double fromAmount,
    required NumberFormatPreference numberFormatPreference,
  }) {
    if (benchmark.price <= 0) return null;

    final converted = ConversionCalculator.convert(
      snapshot: snapshot,
      amount: fromAmount,
      fromCurrency: fromCurrency,
      toCurrency: benchmark.currencyCode,
      numberFormatPreference: numberFormatPreference,
    );
    if (converted == null) return null;

    final equivalentCount = converted.rawConvertedAmount / benchmark.price;

    return BenchmarkComparisonResult(
      benchmarkId: benchmark.id,
      benchmarkName: benchmark.name,
      equivalentCount: equivalentCount,
      displayText:
          'Setara ${_formatEquivalentCount(equivalentCount, numberFormatPreference)} '
          '${benchmark.name}',
    );
  }

  /// Combines both rules: order active benchmarks by recency (§4.2), then
  /// compute a comparison for each (§4.3) — the first entry in the
  /// returned list is always the "top" one. A benchmark with no
  /// resolvable rate is silently skipped rather than surfaced as an
  /// error, matching how the converter itself treats an unresolvable
  /// inactive-tile conversion.
  static List<BenchmarkComparisonResult> compareAll({
    required List<BenchmarkItem> benchmarks,
    required RateSnapshotModel snapshot,
    required String fromCurrency,
    required double fromAmount,
    required NumberFormatPreference numberFormatPreference,
  }) {
    final ordered = orderActiveByRecency(benchmarks);
    return ordered
        .map(
          (benchmark) => compareOne(
            benchmark: benchmark,
            snapshot: snapshot,
            fromCurrency: fromCurrency,
            fromAmount: fromAmount,
            numberFormatPreference: numberFormatPreference,
          ),
        )
        .nonNulls
        .toList();
  }

  /// §4.3 display rounding rule, added in review pass to make "close to a
  /// whole number" and "small" concrete:
  ///
  /// * Within [_wholeNumberEpsilon] of an integer → shown as that whole
  ///   number, no decimals (`Setara 3 Nasi Padang`).
  /// * Otherwise, magnitude under 1 → up to 2 decimals, so small
  ///   fractional comparisons keep useful precision (`Setara 0.5 Onigiri`).
  /// * Otherwise → 1 decimal (`Setara 12.4 Coffee`).
  ///
  /// Trailing zeros are always trimmed — never excessive decimals either
  /// way.
  static const _wholeNumberEpsilon = 0.05;

  static String _formatEquivalentCount(
    double value,
    NumberFormatPreference preference,
  ) {
    final nearestWhole = value.roundToDouble();
    if ((value - nearestWhole).abs() < _wholeNumberEpsilon) {
      return formatNumber(
        nearestWhole,
        preference: preference,
        decimalDigits: 0,
      );
    }
    final decimalDigits = value.abs() < 1 ? 2 : 1;
    return formatNumber(
      value,
      preference: preference,
      decimalDigits: decimalDigits,
      trimTrailingZeros: true,
    );
  }
}
