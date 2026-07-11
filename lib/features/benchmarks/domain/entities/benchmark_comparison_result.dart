/// §13.2 Benchmark Comparison Result.
///
/// Not in the original §11 architecture tree for the benchmarks feature
/// (which lists no entity file besides `benchmark_item.dart`), added here
/// following the converter feature's own precedent
/// (`domain/entities/conversion_result.dart`) of giving a calculator's
/// output type its own file rather than nesting it inside the service.
class BenchmarkComparisonResult {
  const BenchmarkComparisonResult({
    required this.benchmarkId,
    required this.benchmarkName,
    required this.equivalentCount,
    required this.displayText,
  });

  final String benchmarkId;
  final String benchmarkName;

  /// Full-precision `converted amount / benchmark price` (§4.3). Never
  /// derived from [displayText] (§20.2).
  final double equivalentCount;

  /// Ready-to-render "Setara N Item" string, already rounded per §4.3's
  /// display rule. Never parsed back into a number.
  final String displayText;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BenchmarkComparisonResult &&
        other.benchmarkId == benchmarkId &&
        other.benchmarkName == benchmarkName &&
        other.equivalentCount == equivalentCount &&
        other.displayText == displayText;
  }

  @override
  int get hashCode =>
      Object.hash(benchmarkId, benchmarkName, equivalentCount, displayText);
}
