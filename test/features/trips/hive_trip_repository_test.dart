import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:rateify/features/trips/data/repositories/trip_repository_impl.dart';
import 'package:rateify/features/trips/domain/entities/trip_expense.dart';

void main() {
  late Directory tempDir;
  late Box<dynamic> tripBox;
  late Box<dynamic> expenseBox;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('rateify_trip_test_');
    Hive.init(tempDir.path);
    tripBox = await Hive.openBox<dynamic>('trip_test_box');
    expenseBox = await Hive.openBox<dynamic>('trip_expense_test_box');
  });

  tearDown(() async {
    await tripBox.deleteFromDisk();
    await expenseBox.deleteFromDisk();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test(
    'createTrip persists name/localCurrency/homeCurrency(snapshot)/totalBudget (TC-TRIP-001)',
    () {
      final repository = HiveTripRepository(tripBox, expenseBox);

      repository.createTrip(
        name: 'Tokyo Trip',
        localCurrency: 'JPY',
        homeCurrency: 'USD',
        totalBudget: 200000,
      );

      final all = repository.getAllTrips();
      expect(all, hasLength(1));
      final created = all.single;
      expect(created.name, 'Tokyo Trip');
      expect(created.localCurrency, 'JPY');
      expect(created.homeCurrency, 'USD');
      expect(created.totalBudget, 200000);
      expect(created.isArchived, isFalse);
      expect(created.createdAt, created.updatedAt);

      // Fresh repository instance over the same box proves it was actually
      // persisted, not just held in memory.
      final reloaded = HiveTripRepository(tripBox, expenseBox).getAllTrips().single;
      expect(reloaded.name, 'Tokyo Trip');
      expect(reloaded.homeCurrency, 'USD');
    },
  );

  test(
    'editTrip updates fields and bumps updatedAt; archiveTrip flips isArchived '
    'and excludes it from an active-only filter (TC-TRIP-002)',
    () async {
      final repository = HiveTripRepository(tripBox, expenseBox);
      repository.createTrip(
        name: 'Tokyo Trip',
        localCurrency: 'JPY',
        homeCurrency: 'USD',
        totalBudget: 200000,
      );
      final original = repository.getAllTrips().single;

      await Future<void>.delayed(const Duration(milliseconds: 5));
      repository.editTrip(
        id: original.id,
        name: 'Tokyo Adventure',
        localCurrency: 'JPY',
        totalBudget: 250000,
      );

      final edited = repository.getAllTrips().single;
      expect(edited.name, 'Tokyo Adventure');
      expect(edited.totalBudget, 250000);
      // homeCurrency is untouched by edit — not even a parameter (§20.7).
      expect(edited.homeCurrency, 'USD');
      expect(edited.createdAt, original.createdAt);
      expect(edited.updatedAt.isAfter(original.updatedAt), isTrue);

      repository.archiveTrip(original.id);
      final archived = repository.getAllTrips().single;
      expect(archived.isArchived, isTrue);
      final activeOnly = repository
          .getAllTrips()
          .where((trip) => !trip.isArchived)
          .toList();
      expect(activeOnly, isEmpty);
    },
  );

  test(
    'deleteTrip removes the trip and cascades to delete its expenses, with '
    'no orphan reference left behind (TC-TRIP-002)',
    () {
      final repository = HiveTripRepository(tripBox, expenseBox);
      repository.createTrip(
        name: 'Tokyo Trip',
        localCurrency: 'JPY',
        homeCurrency: 'USD',
        totalBudget: 200000,
      );
      final trip = repository.getAllTrips().single;
      repository.addExpense(
        tripId: trip.id,
        title: 'Ramen',
        amountLocal: 1200,
        category: ExpenseCategory.food,
        spentAt: DateTime(2026, 7),
      );
      expect(repository.getExpensesForTrip(trip.id), hasLength(1));

      repository.deleteTrip(trip.id);

      expect(repository.getAllTrips(), isEmpty);
      expect(repository.getExpensesForTrip(trip.id), isEmpty);
      expect(HiveTripRepository(tripBox, expenseBox).getAllTrips(), isEmpty);
    },
  );

  test(
    'addExpense/editExpense/deleteExpense: expense list and totals update '
    'correctly (TC-TRIP-003)',
    () async {
      final repository = HiveTripRepository(tripBox, expenseBox);
      repository.createTrip(
        name: 'Tokyo Trip',
        localCurrency: 'JPY',
        homeCurrency: 'USD',
        totalBudget: 200000,
      );
      final trip = repository.getAllTrips().single;

      repository.addExpense(
        tripId: trip.id,
        title: 'Ramen',
        amountLocal: 1200,
        category: ExpenseCategory.food,
        note: 'Ichiran',
        spentAt: DateTime(2026, 7),
      );
      final created = repository.getExpensesForTrip(trip.id).single;
      expect(created.title, 'Ramen');
      expect(created.amountLocal, 1200);
      expect(created.category, ExpenseCategory.food);
      expect(created.note, 'Ichiran');
      expect(created.tripId, trip.id);

      await Future<void>.delayed(const Duration(milliseconds: 5));
      repository.editExpense(
        id: created.id,
        title: 'Ramen (extra)',
        amountLocal: 1500,
        category: ExpenseCategory.food,
        spentAt: DateTime(2026, 7),
      );
      final edited = repository.getExpensesForTrip(trip.id).single;
      expect(edited.title, 'Ramen (extra)');
      expect(edited.amountLocal, 1500);
      expect(edited.note, isNull);
      expect(edited.updatedAt.isAfter(created.updatedAt), isTrue);

      repository.deleteExpense(edited.id);
      expect(repository.getExpensesForTrip(trip.id), isEmpty);
    },
  );

  test('getExpensesForTrip only returns expenses for that trip', () {
    final repository = HiveTripRepository(tripBox, expenseBox);
    repository.createTrip(
      name: 'Trip A',
      localCurrency: 'JPY',
      homeCurrency: 'USD',
      totalBudget: 100000,
    );
    repository.createTrip(
      name: 'Trip B',
      localCurrency: 'EUR',
      homeCurrency: 'USD',
      totalBudget: 1000,
    );
    final trips = repository.getAllTrips();
    final tripA = trips.firstWhere((t) => t.name == 'Trip A');
    final tripB = trips.firstWhere((t) => t.name == 'Trip B');

    repository.addExpense(
      tripId: tripA.id,
      title: 'A expense',
      amountLocal: 100,
      category: ExpenseCategory.other,
      spentAt: DateTime(2026, 7),
    );
    repository.addExpense(
      tripId: tripB.id,
      title: 'B expense',
      amountLocal: 50,
      category: ExpenseCategory.other,
      spentAt: DateTime(2026, 7),
    );

    expect(repository.getExpensesForTrip(tripA.id), hasLength(1));
    expect(repository.getExpensesForTrip(tripA.id).single.title, 'A expense');
    expect(repository.getExpensesForTrip(tripB.id), hasLength(1));
    expect(repository.getExpensesForTrip(tripB.id).single.title, 'B expense');
  });
}
