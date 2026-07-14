import 'dart:convert';

import 'package:hive/hive.dart';

import '../../../../core/errors/cache_exception.dart';
import '../../../../core/utils/id_generator.dart';
import '../../domain/entities/trip.dart';
import '../../domain/entities/trip_expense.dart';
import '../../domain/repositories/trip_repository.dart';
import '../models/trip_expense_model.dart';
import '../models/trip_model.dart';

/// Hive-backed [TripRepository]. Trips and expenses each live in their own
/// `Box<dynamic>`, one JSON string per record keyed by its own `id` — same
/// storage pattern as `HiveBenchmarkRepository`.
class HiveTripRepository implements TripRepository {
  HiveTripRepository(this._tripBox, this._expenseBox);

  final Box<dynamic> _tripBox;
  final Box<dynamic> _expenseBox;

  @override
  List<Trip> getAllTrips() {
    return _tripBox.values
        .map(
          (raw) =>
              tripFromJson(jsonDecode(raw as String) as Map<String, dynamic>),
        )
        .toList();
  }

  @override
  void createTrip({
    required String name,
    required String localCurrency,
    required String homeCurrency,
    required double totalBudget,
  }) {
    final now = DateTime.now();
    _putTrip(
      Trip(
        id: IdGenerator.generate(),
        name: name,
        localCurrency: localCurrency,
        // §5.2/§20.7 — stored verbatim, exactly as passed in by the
        // caller at this single moment in time; never revisited.
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
    final existing = _findTrip(id);
    if (existing == null) return;
    _putTrip(
      existing.copyWith(
        name: name,
        localCurrency: localCurrency,
        totalBudget: totalBudget,
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  void archiveTrip(String id) {
    final existing = _findTrip(id);
    if (existing == null) return;
    _putTrip(existing.copyWith(isArchived: true, updatedAt: DateTime.now()));
  }

  @override
  void deleteTrip(String id) {
    _tripBox.delete(id);
    // An expense can't outlive its trip — cascade-delete every expense that
    // belonged to it so deleting a trip never leaves an orphaned record
    // behind that `getExpensesForTrip` would otherwise keep returning for a
    // trip id nothing else references anymore.
    final orphanedKeys = _expenseBox.keys.where((key) {
      final expense = _decodeExpense(_expenseBox.get(key) as String?);
      return expense?.tripId == id;
    }).toList();
    _expenseBox.deleteAll(orphanedKeys);
  }

  @override
  List<TripExpense> getExpensesForTrip(String tripId) {
    return _expenseBox.values
        .map(
          (raw) => tripExpenseFromJson(
            jsonDecode(raw as String) as Map<String, dynamic>,
          ),
        )
        .where((expense) => expense.tripId == tripId)
        .toList();
  }

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
    _putExpense(
      TripExpense(
        id: IdGenerator.generate(),
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
    final existing = _findExpense(id);
    if (existing == null) return;
    _putExpense(
      existing.copyWith(
        title: title,
        // §5.4/§20.4 — this is the one place `amountLocal` is ever
        // rewritten, and only via an explicit user-driven edit, never as a
        // side effect of a rate change.
        amountLocal: amountLocal,
        category: category,
        note: note,
        clearNote: note == null,
        spentAt: spentAt,
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  void deleteExpense(String id) => _expenseBox.delete(id);

  Trip? _findTrip(String id) => _decodeTrip(_tripBox.get(id) as String?);

  TripExpense? _findExpense(String id) =>
      _decodeExpense(_expenseBox.get(id) as String?);

  Trip? _decodeTrip(String? raw) {
    if (raw == null) return null;
    return tripFromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  TripExpense? _decodeExpense(String? raw) {
    if (raw == null) return null;
    return tripExpenseFromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  void _putTrip(Trip trip) {
    try {
      _tripBox.put(trip.id, jsonEncode(trip.toJson()));
    } catch (e) {
      throw CacheException.readWriteFailed(e.toString());
    }
  }

  void _putExpense(TripExpense expense) {
    try {
      _expenseBox.put(expense.id, jsonEncode(expense.toJson()));
    } catch (e) {
      throw CacheException.readWriteFailed(e.toString());
    }
  }
}
