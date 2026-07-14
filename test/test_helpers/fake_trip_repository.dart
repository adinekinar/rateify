import 'package:rateify/features/trips/domain/entities/trip.dart';
import 'package:rateify/features/trips/domain/entities/trip_expense.dart';
import 'package:rateify/features/trips/domain/repositories/trip_repository.dart';

/// In-memory [TripRepository] fake for widget/controller tests that don't
/// care about actual Hive persistence — only about provider
/// wiring/behavior. Mirrors `FakeBenchmarkRepository`'s shape.
class FakeTripRepository implements TripRepository {
  FakeTripRepository({
    List<Trip>? initialTrips,
    List<TripExpense>? initialExpenses,
  }) : _trips = List.of(initialTrips ?? const []),
       _expenses = List.of(initialExpenses ?? const []);

  final List<Trip> _trips;
  final List<TripExpense> _expenses;
  int _idCounter = 0;

  @override
  List<Trip> getAllTrips() => List.unmodifiable(_trips);

  @override
  void createTrip({
    required String name,
    required String localCurrency,
    required String homeCurrency,
    required double totalBudget,
  }) {
    final now = DateTime.now();
    _trips.add(
      Trip(
        id: 'fake-trip-${_idCounter++}',
        name: name,
        localCurrency: localCurrency,
        homeCurrency: homeCurrency,
        totalBudget: totalBudget,
        isArchived: false,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  @override
  void editTrip({
    required String id,
    required String name,
    required String localCurrency,
    required double totalBudget,
  }) {
    final index = _trips.indexWhere((trip) => trip.id == id);
    if (index == -1) return;
    _trips[index] = _trips[index].copyWith(
      name: name,
      localCurrency: localCurrency,
      totalBudget: totalBudget,
      updatedAt: DateTime.now(),
    );
  }

  @override
  void archiveTrip(String id) {
    final index = _trips.indexWhere((trip) => trip.id == id);
    if (index == -1) return;
    _trips[index] = _trips[index].copyWith(
      isArchived: true,
      updatedAt: DateTime.now(),
    );
  }

  @override
  void deleteTrip(String id) {
    _trips.removeWhere((trip) => trip.id == id);
    _expenses.removeWhere((expense) => expense.tripId == id);
  }

  @override
  List<TripExpense> getExpensesForTrip(String tripId) =>
      _expenses.where((expense) => expense.tripId == tripId).toList();

  @override
  void addExpense({
    required String tripId,
    required String title,
    required double amountLocal,
    required ExpenseCategory category,
    String? note,
    required DateTime spentAt,
  }) {
    final now = DateTime.now();
    _expenses.add(
      TripExpense(
        id: 'fake-expense-${_idCounter++}',
        tripId: tripId,
        title: title,
        amountLocal: amountLocal,
        category: category,
        note: note,
        spentAt: spentAt,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  @override
  void editExpense({
    required String id,
    required String title,
    required double amountLocal,
    required ExpenseCategory category,
    String? note,
    required DateTime spentAt,
  }) {
    final index = _expenses.indexWhere((expense) => expense.id == id);
    if (index == -1) return;
    _expenses[index] = _expenses[index].copyWith(
      title: title,
      amountLocal: amountLocal,
      category: category,
      note: note,
      clearNote: note == null,
      spentAt: spentAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  void deleteExpense(String id) =>
      _expenses.removeWhere((expense) => expense.id == id);
}
