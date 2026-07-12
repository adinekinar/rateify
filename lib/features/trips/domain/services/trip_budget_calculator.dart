import '../../../converter/data/models/rate_snapshot_model.dart';
import '../../../converter/domain/services/conversion_calculator.dart';
import '../entities/trip.dart';
import '../entities/trip_expense.dart';

/// §5.4 Budget Calculation Rule's three progress states.
enum BudgetProgressState { normal, warning, danger }

/// §5.4 spent/remaining/progress-ratio math + the three progress states. No
/// widget, no Riverpod — independently unit-testable, same discipline as
/// the converter feature's `conversion_calculator.dart` and the benchmark
/// feature's `benchmark_calculator.dart`.
abstract final class TripBudgetCalculator {
  static double spentLocal(List<TripExpense> expenses) =>
      expenses.fold(0.0, (sum, expense) => sum + expense.amountLocal);

  static double remainingLocal({
    required double totalBudget,
    required double spent,
  }) => totalBudget - spent;

  /// `spent / totalBudget`. A non-positive budget can't be divided into —
  /// treated as 0% progress rather than throwing or producing infinity/NaN.
  static double progressRatio({
    required double totalBudget,
    required double spent,
  }) {
    if (totalBudget <= 0) return 0;
    return spent / totalBudget;
  }

  /// §5.4: below budget is normal, 80%+ is warning, over 100% is danger.
  static BudgetProgressState progressState(double ratio) {
    if (ratio > 1) return BudgetProgressState.danger;
    if (ratio >= 0.8) return BudgetProgressState.warning;
    return BudgetProgressState.normal;
  }

  /// Converts [spentLocal] (in [trip]'s local currency) into [trip]'s own
  /// *snapshotted* `homeCurrency` (§5.2/§20.7 — never the current global
  /// home currency) using the latest [snapshot]. Reuses Batch 03's
  /// cross-rate math directly rather than reimplementing it, the same way
  /// `BenchmarkCalculator` does. Returns `null` if no rate is resolvable.
  static double? spentInHomeCurrency({
    required Trip trip,
    required double spentLocal,
    required RateSnapshotModel snapshot,
  }) {
    final rate = ConversionCalculator.rateBetween(
      snapshot: snapshot,
      fromCurrency: trip.localCurrency,
      toCurrency: trip.homeCurrency,
    );
    if (rate == null) return null;
    return spentLocal * rate;
  }
}
