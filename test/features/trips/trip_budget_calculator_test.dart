import 'package:flutter_test/flutter_test.dart';
import 'package:rateify/features/converter/data/models/rate_snapshot_model.dart';
import 'package:rateify/features/trips/domain/entities/trip.dart';
import 'package:rateify/features/trips/domain/entities/trip_expense.dart';
import 'package:rateify/features/trips/domain/services/trip_budget_calculator.dart';

void main() {
  TripExpense expense({required double amountLocal, String id = 'e1'}) {
    final now = DateTime(2026, 7);
    return TripExpense(
      id: id,
      tripId: 'trip-1',
      title: 'Expense',
      amountLocal: amountLocal,
      category: ExpenseCategory.food,
      spentAt: now,
      createdAt: now,
      updatedAt: now,
    );
  }

  Trip trip({
    required String localCurrency,
    required String homeCurrency,
    required double totalBudget,
  }) {
    final now = DateTime(2026, 7);
    return Trip(
      id: 'trip-1',
      name: 'Trip',
      localCurrency: localCurrency,
      homeCurrency: homeCurrency,
      totalBudget: totalBudget,
      isArchived: false,
      createdAt: now,
      updatedAt: now,
    );
  }

  group('spentLocal (TC-TRIP-004)', () {
    test('sums every expense amountLocal', () {
      final expenses = [
        expense(amountLocal: 100),
        expense(id: 'e2', amountLocal: 250.5),
        expense(id: 'e3', amountLocal: 49.5),
      ];
      expect(TripBudgetCalculator.spentLocal(expenses), 400);
    });

    test('empty expense list sums to 0', () {
      expect(TripBudgetCalculator.spentLocal(const []), 0);
    });
  });

  group('remainingLocal (TC-TRIP-005)', () {
    test('totalBudget - spent, including the negative over-budget case', () {
      expect(
        TripBudgetCalculator.remainingLocal(totalBudget: 1000, spent: 400),
        600,
      );
      expect(
        TripBudgetCalculator.remainingLocal(totalBudget: 1000, spent: 1200),
        -200,
      );
    });
  });

  group('progressRatio (TC-TRIP-006)', () {
    test('spent / totalBudget', () {
      expect(
        TripBudgetCalculator.progressRatio(totalBudget: 1000, spent: 400),
        0.4,
      );
      expect(
        TripBudgetCalculator.progressRatio(totalBudget: 1000, spent: 1500),
        1.5,
      );
    });

    test('non-positive totalBudget is treated as 0 progress, not a crash', () {
      expect(TripBudgetCalculator.progressRatio(totalBudget: 0, spent: 400), 0);
    });
  });

  group('progressState thresholds (TC-TRIP-007)', () {
    test('below 80% is normal', () {
      expect(
        TripBudgetCalculator.progressState(0.79),
        BudgetProgressState.normal,
      );
    });

    test('exactly 80% is warning', () {
      expect(
        TripBudgetCalculator.progressState(0.80),
        BudgetProgressState.warning,
      );
    });

    test('just under 100% is still warning, not danger', () {
      expect(
        TripBudgetCalculator.progressState(0.99),
        BudgetProgressState.warning,
      );
    });

    test('over 100% (e.g. 101%) is danger', () {
      expect(
        TripBudgetCalculator.progressState(1.01),
        BudgetProgressState.danger,
      );
    });

    test('exactly 100% is not yet danger (only "exceeds" triggers it)', () {
      expect(
        TripBudgetCalculator.progressState(1.0),
        BudgetProgressState.warning,
      );
    });
  });

  group('spentInHomeCurrency uses the latest rate against the trip\'s own '
      'snapshotted homeCurrency (TC-TRIP-008, TC-TRIP-010)', () {
    test('converts spentLocal using the current snapshot rate, never touching '
        'amountLocal itself', () {
      final t = trip(
        localCurrency: 'JPY',
        homeCurrency: 'USD',
        totalBudget: 100000,
      );
      final snapshot = RateSnapshotModel(
        baseCurrency: 'USD',
        rates: const {'JPY': 160.0, 'EUR': 0.8},
        fetchedAt: DateTime(2026, 7),
        sourceStatus: RateSourceStatus.freshRemote,
      );

      final result = TripBudgetCalculator.spentInHomeCurrency(
        trip: t,
        spentLocal: 16000,
        snapshot: snapshot,
      );

      // rate(JPY->USD) = rateFromBase(USD)/rateFromBase(JPY) = 1/160
      expect(result, closeTo(100, 0.0001));
    });

    test('a later snapshot with a different rate changes only the converted '
        'value — the stored amountLocal (simulated by the caller) is never '
        'touched by this function', () {
      final t = trip(
        localCurrency: 'JPY',
        homeCurrency: 'USD',
        totalBudget: 100000,
      );
      const spentLocal = 16000.0;

      final before = TripBudgetCalculator.spentInHomeCurrency(
        trip: t,
        spentLocal: spentLocal,
        snapshot: RateSnapshotModel(
          baseCurrency: 'USD',
          rates: const {'JPY': 160.0},
          fetchedAt: DateTime(2026, 7),
          sourceStatus: RateSourceStatus.freshRemote,
        ),
      );
      final after = TripBudgetCalculator.spentInHomeCurrency(
        trip: t,
        spentLocal: spentLocal,
        snapshot: RateSnapshotModel(
          baseCurrency: 'USD',
          rates: const {'JPY': 150.0},
          fetchedAt: DateTime(2026, 7, 2),
          sourceStatus: RateSourceStatus.freshRemote,
        ),
      );

      expect(before, closeTo(100, 0.0001));
      expect(after, closeTo(106.6667, 0.0001));
      expect(before, isNot(equals(after)));
      // spentLocal itself never changed between the two calls.
    });

    test('TC-TRIP-010: converts against the trip\'s own snapshotted '
        'homeCurrency, never a "current global" concept the function does '
        'not even accept as input', () {
      // Trip was created while global home currency was USD.
      final t = trip(
        localCurrency: 'JPY',
        homeCurrency: 'USD',
        totalBudget: 100000,
      );
      // The global home currency is now (hypothetically) EUR, but the
      // snapshot still carries both rates — spentInHomeCurrency has no
      // way to read "the current global home currency" at all, so it
      // can only ever resolve against trip.homeCurrency ('USD').
      final snapshot = RateSnapshotModel(
        baseCurrency: 'USD',
        rates: const {'JPY': 160.0, 'EUR': 0.8},
        fetchedAt: DateTime(2026, 7),
        sourceStatus: RateSourceStatus.freshRemote,
      );

      final result = TripBudgetCalculator.spentInHomeCurrency(
        trip: t,
        spentLocal: 16000,
        snapshot: snapshot,
      );

      expect(result, closeTo(100, 0.0001));
    });

    test('returns null when no rate is resolvable for either currency', () {
      final t = trip(
        localCurrency: 'JPY',
        homeCurrency: 'XYZ',
        totalBudget: 100000,
      );
      final snapshot = RateSnapshotModel(
        baseCurrency: 'USD',
        rates: const {'JPY': 160.0},
        fetchedAt: DateTime(2026, 7),
        sourceStatus: RateSourceStatus.freshRemote,
      );

      final result = TripBudgetCalculator.spentInHomeCurrency(
        trip: t,
        spentLocal: 16000,
        snapshot: snapshot,
      );

      expect(result, isNull);
    });
  });
}
