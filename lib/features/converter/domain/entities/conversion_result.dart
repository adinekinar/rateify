import '../../data/models/rate_snapshot_model.dart' show RateSourceStatus;

/// §10.3a Conversion Result — one produced per inactive tile whenever the
/// active tile's amount changes.
///
/// Reuses [RateSourceStatus] from `data/models/rate_snapshot_model.dart`
/// rather than duplicating it: same reasoning as
/// `ExchangeRateRepository` reusing `RateSnapshotModel` directly (Batch 02)
/// — the spec defines this as one of the shared §10.1 core enums, not a
/// separate per-layer copy.
class ConversionResult {
  const ConversionResult({
    required this.targetCurrency,
    required this.rawConvertedAmount,
    required this.formattedDisplayValue,
    required this.sourceStatus,
  });

  final String targetCurrency;

  /// Full precision — the only value ever used for further calculation
  /// (§20.2). Never derive this from [formattedDisplayValue].
  final double rawConvertedAmount;

  /// Display-only, capped at 2 decimals per §3.4. Must never be parsed back
  /// into a number anywhere (§20.2).
  final String formattedDisplayValue;

  final RateSourceStatus sourceStatus;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConversionResult &&
        other.targetCurrency == targetCurrency &&
        other.rawConvertedAmount == rawConvertedAmount &&
        other.formattedDisplayValue == formattedDisplayValue &&
        other.sourceStatus == sourceStatus;
  }

  @override
  int get hashCode => Object.hash(
    targetCurrency,
    rawConvertedAmount,
    formattedDisplayValue,
    sourceStatus,
  );
}
