import '../../data/models/rate_snapshot_model.dart';
import '../repositories/exchange_rate_repository.dart';

/// Explicit user-triggered refresh — bypasses the staleness check (§9.3).
/// A thin wrapper around the repository, kept as its own usecase so the
/// controller calls an explicit "refresh rates" action rather than reaching
/// into the repository directly for this one operation.
class RefreshRatesUsecase {
  const RefreshRatesUsecase(this._repository);

  final ExchangeRateRepository _repository;

  Future<RateSnapshotModel> call() => _repository.refresh();
}
