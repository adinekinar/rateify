import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/cache_constants.dart';
import '../../../../core/errors/cache_exception.dart';
import '../../../../core/errors/network_exception.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../domain/repositories/exchange_rate_repository.dart';
import '../datasources/exchange_rate_local_data_source.dart';
import '../datasources/exchange_rate_remote_data_source.dart';
import '../models/rate_snapshot_model.dart';

/// §9.2 fallback order + §9.3 staleness rule, in one place so callers never
/// have to reason about network/cache details themselves.
class ExchangeRateRepositoryImpl implements ExchangeRateRepository {
  ExchangeRateRepositoryImpl({
    required ExchangeRateRemoteDataSource remoteDataSource,
    required ExchangeRateLocalDataSource localDataSource,
    DateTime Function()? clock,
  }) : _remote = remoteDataSource,
       _local = localDataSource,
       _clock = clock ?? DateTime.now;

  final ExchangeRateRemoteDataSource _remote;
  final ExchangeRateLocalDataSource _local;

  /// Injectable so tests can control "now" precisely instead of depending on
  /// wall-clock time to exercise the staleness boundary.
  final DateTime Function() _clock;

  @override
  Future<RateSnapshotModel> getSnapshot() async {
    final stored = _local.readSnapshot();
    final isStale =
        stored == null ||
        DateTimeUtils.isOlderThan(
          stored.fetchedAt,
          CacheConstants.staleRateThreshold,
          now: _clock(),
        );

    if (!isStale) {
      // §9.3 — snapshot is fresh enough; reuse it with no network call.
      return stored;
    }
    return _fetchWithFallback(cachedFallback: stored);
  }

  @override
  Future<RateSnapshotModel> refresh() {
    return _fetchWithFallback(cachedFallback: _local.readSnapshot());
  }

  Future<RateSnapshotModel> _fetchWithFallback({
    required RateSnapshotModel? cachedFallback,
  }) async {
    try {
      final response = await _remote.fetchLatestRates(
        baseCurrency: AppConstants.rateSnapshotAnchorCurrency,
      );
      final fresh = RateSnapshotModel.fromFrankfurterResponse(
        response,
        fetchedAt: _clock(),
      );
      try {
        _local.writeSnapshot(fresh);
      } on CacheException {
        // A cache-write failure doesn't invalidate data we just fetched
        // successfully — still return it, just unpersisted this time.
      }
      return fresh;
    } on NetworkException {
      if (cachedFallback != null) {
        return cachedFallback.copyWith(sourceStatus: RateSourceStatus.cached);
      }
      return RateSnapshotModel.unavailable(
        baseCurrency: AppConstants.rateSnapshotAnchorCurrency,
        determinedAt: _clock(),
      );
    }
  }
}
