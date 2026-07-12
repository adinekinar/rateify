import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../converter/data/models/rate_snapshot_model.dart';
import '../../../converter/presentation/providers/converter_providers.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../../domain/entities/trip.dart';
import '../../domain/entities/trip_expense.dart';
import '../../domain/repositories/trip_repository.dart';
import '../../domain/services/trip_budget_calculator.dart';

/// §12.1 core provider. Overridden in `main()` with a real
/// [HiveTripRepository] once the trip/trip-expense Hive boxes have been
/// opened — same composition-root pattern as the other repository
/// providers.
final tripRepositoryProvider = Provider<TripRepository>((ref) {
  throw UnimplementedError(
    'tripRepositoryProvider must be overridden with a HiveTripRepository in main()',
  );
});

/// §12.3 — all trips, in whatever order the repository returns them. Not
/// filtered to active-only here: the list page needs to distinguish
/// "no trips at all" from "trips exist but all archived", so filtering is
/// the page's job, same as `BenchmarksController` leaves active-filtering
/// to `BenchmarkPage`.
///
/// Plain `Notifier`, not `AsyncNotifierProvider` as §12.3 sketches — Hive
/// reads are synchronous, so there's nothing to await, same deliberate
/// deviation `BenchmarksController` already made from its own spec sketch.
final tripListControllerProvider =
    NotifierProvider<TripListController, List<Trip>>(TripListController.new);

class TripListController extends Notifier<List<Trip>> {
  @override
  List<Trip> build() => ref.watch(tripRepositoryProvider).getAllTrips();

  /// §5.2/§20.7 — the form itself never asks for a home currency; this
  /// silently captures whatever the *current* global home currency is at
  /// the moment of creation and hands it to the repository as the trip's
  /// permanent snapshot.
  void createTrip({
    required String name,
    required String localCurrency,
    required double totalBudget,
  }) {
    final homeCurrency = ref.read(appSettingsProvider).homeCurrency;
    ref
        .read(tripRepositoryProvider)
        .createTrip(
          name: name,
          localCurrency: localCurrency,
          homeCurrency: homeCurrency,
          totalBudget: totalBudget,
        );
    _reload();
  }

  void editTrip({
    required String id,
    required String name,
    required String localCurrency,
    required double totalBudget,
  }) {
    ref
        .read(tripRepositoryProvider)
        .editTrip(
          id: id,
          name: name,
          localCurrency: localCurrency,
          totalBudget: totalBudget,
        );
    _reload();
  }

  void archiveTrip(String id) {
    ref.read(tripRepositoryProvider).archiveTrip(id);
    _reload();
  }

  void deleteTrip(String id) {
    ref.read(tripRepositoryProvider).deleteTrip(id);
    _reload();
  }

  void _reload() {
    state = ref.read(tripRepositoryProvider).getAllTrips();
  }
}

/// §13.3 Trip Detail UI State.
class TripDetailUiState {
  const TripDetailUiState({
    required this.trip,
    required this.expenses,
    required this.spentLocal,
    required this.remainingLocal,
    required this.progressRatio,
    required this.spentHomeCurrency,
    required this.isOverBudget,
  });

  final Trip trip;
  final List<TripExpense> expenses;
  final double spentLocal;
  final double remainingLocal;
  final double progressRatio;
  final double? spentHomeCurrency;
  final bool isOverBudget;

  BudgetProgressState get progressState =>
      TripBudgetCalculator.progressState(progressRatio);
}

/// Per-trip detail state, combining the trip + its expenses (both from
/// [tripRepositoryProvider], synchronous) with the latest available rate
/// (from [exchangeRateRepositoryProvider], asynchronous) — an
/// `AsyncNotifierProvider.family` for the same reason
/// `rateHistoryControllerProvider` is one in §12.3: state that's keyed per
/// argument and needs an `await` in `build`.
final tripDetailControllerProvider =
    AsyncNotifierProvider.family<TripDetailController, TripDetailUiState, String>(
      TripDetailController.new,
    );

class TripDetailController extends FamilyAsyncNotifier<TripDetailUiState, String> {
  /// Cached rather than re-fetched on every expense mutation — recomputing
  /// spent/remaining/progress after an add/edit/delete doesn't need a fresh
  /// network round-trip each time; only [refresh] (explicit pull-to-refresh)
  /// or a fresh `build` re-fetches it.
  RateSnapshotModel? _latestSnapshot;

  @override
  Future<TripDetailUiState> build(String tripId) async {
    _latestSnapshot = await _fetchSnapshotSafely();
    return _computeState();
  }

  Future<RateSnapshotModel?> _fetchSnapshotSafely() async {
    try {
      return await ref.read(exchangeRateRepositoryProvider).getSnapshot();
    } on Object {
      // No home-currency conversion this cycle; local budget math is
      // unaffected (§20.3 offline is still a valid state to render in).
      return null;
    }
  }

  TripDetailUiState _computeState() {
    final repository = ref.read(tripRepositoryProvider);
    final trip = repository.getAllTrips().firstWhere((t) => t.id == arg);
    final expenses = repository.getExpensesForTrip(arg);

    final spent = TripBudgetCalculator.spentLocal(expenses);
    final snapshot = _latestSnapshot;
    return TripDetailUiState(
      trip: trip,
      expenses: expenses,
      spentLocal: spent,
      remainingLocal: TripBudgetCalculator.remainingLocal(
        totalBudget: trip.totalBudget,
        spent: spent,
      ),
      progressRatio: TripBudgetCalculator.progressRatio(
        totalBudget: trip.totalBudget,
        spent: spent,
      ),
      spentHomeCurrency: snapshot == null
          ? null
          : TripBudgetCalculator.spentInHomeCurrency(
              trip: trip,
              spentLocal: spent,
              snapshot: snapshot,
            ),
      isOverBudget: spent > trip.totalBudget,
    );
  }

  Future<void> refresh() async {
    _latestSnapshot = await _fetchSnapshotSafely();
    state = AsyncData(_computeState());
  }

  void addExpense({
    required String title,
    required double amountLocal,
    required ExpenseCategory category,
    String? note,
    required DateTime spentAt,
  }) {
    ref
        .read(tripRepositoryProvider)
        .addExpense(
          tripId: arg,
          title: title,
          amountLocal: amountLocal,
          category: category,
          note: note,
          spentAt: spentAt,
        );
    state = AsyncData(_computeState());
  }

  void editExpense({
    required String id,
    required String title,
    required double amountLocal,
    required ExpenseCategory category,
    String? note,
    required DateTime spentAt,
  }) {
    ref
        .read(tripRepositoryProvider)
        .editExpense(
          id: id,
          title: title,
          amountLocal: amountLocal,
          category: category,
          note: note,
          spentAt: spentAt,
        );
    state = AsyncData(_computeState());
  }

  void deleteExpense(String id) {
    ref.read(tripRepositoryProvider).deleteExpense(id);
    state = AsyncData(_computeState());
  }
}
