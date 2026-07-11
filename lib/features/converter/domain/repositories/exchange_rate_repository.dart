import '../../data/models/rate_snapshot_model.dart';

/// Domain-layer contract for exchange-rate access. Per §9.1, the repository
/// — not the UI — decides whether to serve remote or cached data; the
/// presentation layer only ever talks to this interface, never to Dio or
/// Hive directly (§18.8).
///
/// Design note: this returns [RateSnapshotModel] (a data-layer type)
/// directly rather than a separate domain entity. The spec's own §11
/// architecture tree lists no domain entity for the rate snapshot — only
/// `data/models/rate_snapshot_model.dart` — so a parallel domain class here
/// would just be an unnecessary duplicate with a mapper and no behavioral
/// difference.
abstract class ExchangeRateRepository {
  /// Returns the current snapshot. Refreshes from remote first if there is
  /// no cached snapshot yet or the cached one is older than
  /// `CacheConstants.staleRateThreshold` (§9.3); otherwise returns the
  /// cached snapshot as-is, with no network call.
  Future<RateSnapshotModel> getSnapshot();

  /// Forces an immediate remote refresh, bypassing the staleness check.
  Future<RateSnapshotModel> refresh();
}
