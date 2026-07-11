import 'package:rateify/features/converter/data/models/rate_snapshot_model.dart';
import 'package:rateify/features/converter/domain/repositories/exchange_rate_repository.dart';

/// In-memory [ExchangeRateRepository] fake for controller/widget tests —
/// no Dio, no Hive, fully synchronous-feeling snapshot control.
class FakeExchangeRateRepository implements ExchangeRateRepository {
  FakeExchangeRateRepository({RateSnapshotModel? initialSnapshot})
    : _snapshot =
          initialSnapshot ??
          RateSnapshotModel(
            baseCurrency: 'USD',
            rates: const {
              'EUR': 0.8,
              'JPY': 160.0,
              'IDR': 16000.0,
              'GBP': 0.75,
              'AUD': 1.5,
              'CAD': 1.35,
              'CHF': 0.9,
              'CNY': 7.2,
            },
            fetchedAt: DateTime(2026, 7, 10, 12),
            sourceStatus: RateSourceStatus.freshRemote,
          );

  RateSnapshotModel _snapshot;
  int getSnapshotCallCount = 0;
  int refreshCallCount = 0;

  void setSnapshot(RateSnapshotModel snapshot) => _snapshot = snapshot;

  @override
  Future<RateSnapshotModel> getSnapshot() async {
    getSnapshotCallCount++;
    return _snapshot;
  }

  @override
  Future<RateSnapshotModel> refresh() async {
    refreshCallCount++;
    return _snapshot;
  }
}
