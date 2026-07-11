import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:rateify/core/errors/network_exception.dart';
import 'package:rateify/features/converter/data/datasources/exchange_rate_local_data_source.dart';
import 'package:rateify/features/converter/data/datasources/exchange_rate_remote_data_source.dart';
import 'package:rateify/features/converter/data/models/frankfurter_rate_response_model.dart';
import 'package:rateify/features/converter/data/models/rate_snapshot_model.dart';
import 'package:rateify/features/converter/data/repositories/exchange_rate_repository_impl.dart';

/// Test double for [ExchangeRateRemoteDataSource] — a real subclass
/// overriding the one public method, rather than mocking Dio. There is
/// exactly one production implementation reason for this class (Frankfurter
/// is the sole provider, §9.1), so it isn't split into an interface+impl
/// pair; overriding the method directly is simpler than introducing one.
class _FakeRemoteDataSource extends ExchangeRateRemoteDataSource {
  _FakeRemoteDataSource({this.response, this.exception});

  final FrankfurterRateResponseModel? response;
  final NetworkException? exception;
  int callCount = 0;

  @override
  Future<FrankfurterRateResponseModel> fetchLatestRates({
    required String baseCurrency,
  }) async {
    callCount++;
    if (exception != null) throw exception!;
    return response!;
  }
}

void main() {
  late Directory tempDir;
  late Box<dynamic> box;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'rateify_exchange_rate_test_',
    );
    Hive.init(tempDir.path);
    box = await Hive.openBox<dynamic>('exchange_rate_test_box');
  });

  tearDown(() async {
    await box.deleteFromDisk();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  final freshResponse = FrankfurterRateResponseModel(
    base: 'USD',
    date: DateTime(2026, 7, 10),
    rates: const {'EUR': 0.87, 'JPY': 161.87, 'IDR': 18077},
  );

  test(
    'successful fetch updates the cache and returns freshRemote (TC-CONV-017)',
    () async {
      final remote = _FakeRemoteDataSource(response: freshResponse);
      final local = ExchangeRateLocalDataSource(box);
      final now = DateTime(2026, 7, 10, 12);
      final repository = ExchangeRateRepositoryImpl(
        remoteDataSource: remote,
        localDataSource: local,
        clock: () => now,
      );

      final snapshot = await repository.getSnapshot();

      expect(remote.callCount, 1);
      expect(snapshot.sourceStatus, RateSourceStatus.freshRemote);
      expect(snapshot.baseCurrency, 'USD');
      expect(snapshot.rates['EUR'], 0.87);
      expect(snapshot.fetchedAt, now);

      // Cache was actually written, not just returned in memory.
      final cached = local.readSnapshot();
      expect(cached, isNotNull);
      expect(cached!.rates['JPY'], 161.87);
    },
  );

  test(
    'remote fails but a cache exists -> falls back with sourceStatus = cached (TC-CONV-018)',
    () async {
      final local = ExchangeRateLocalDataSource(box);
      final staleFetchTime = DateTime(2026, 7, 10);
      local.writeSnapshot(
        RateSnapshotModel(
          baseCurrency: 'USD',
          rates: const {'EUR': 0.9},
          fetchedAt: staleFetchTime,
          sourceStatus: RateSourceStatus.freshRemote,
        ),
      );

      final remote = _FakeRemoteDataSource(
        exception: NetworkException.noConnection(),
      );
      final now = staleFetchTime.add(
        const Duration(minutes: 20),
      ); // past the 15-min threshold
      final repository = ExchangeRateRepositoryImpl(
        remoteDataSource: remote,
        localDataSource: local,
        clock: () => now,
      );

      final snapshot = await repository.getSnapshot();

      expect(remote.callCount, 1); // it did try, since the cache was stale
      expect(snapshot.sourceStatus, RateSourceStatus.cached);
      expect(snapshot.rates['EUR'], 0.9);
      expect(
        snapshot.fetchedAt,
        staleFetchTime,
      ); // original fetch time preserved
    },
  );

  test(
    'remote fails and no cache exists -> unavailable, no crash (TC-CONV-019)',
    () async {
      final remote = _FakeRemoteDataSource(
        exception: NetworkException.noConnection(),
      );
      final local = ExchangeRateLocalDataSource(box);
      final repository = ExchangeRateRepositoryImpl(
        remoteDataSource: remote,
        localDataSource: local,
      );

      final snapshot = await repository.getSnapshot();

      expect(snapshot.sourceStatus, RateSourceStatus.unavailable);
      expect(snapshot.rates, isEmpty);
    },
  );

  test(
    'snapshot younger than the staleness threshold -> remote is NOT called (TC-CONV-020)',
    () async {
      final local = ExchangeRateLocalDataSource(box);
      final fetchTime = DateTime(2026, 7, 10, 12);
      local.writeSnapshot(
        RateSnapshotModel(
          baseCurrency: 'USD',
          rates: const {'EUR': 0.87},
          fetchedAt: fetchTime,
          sourceStatus: RateSourceStatus.freshRemote,
        ),
      );

      final remote = _FakeRemoteDataSource(response: freshResponse);
      final now = fetchTime.add(
        const Duration(minutes: 5),
      ); // well under 15 min
      final repository = ExchangeRateRepositoryImpl(
        remoteDataSource: remote,
        localDataSource: local,
        clock: () => now,
      );

      final snapshot = await repository.getSnapshot();

      expect(remote.callCount, 0);
      expect(snapshot.rates['EUR'], 0.87);
    },
  );

  test(
    'snapshot older than the staleness threshold -> remote IS called (TC-CONV-021)',
    () async {
      final local = ExchangeRateLocalDataSource(box);
      final fetchTime = DateTime(2026, 7, 10, 12);
      local.writeSnapshot(
        RateSnapshotModel(
          baseCurrency: 'USD',
          rates: const {'EUR': 0.87},
          fetchedAt: fetchTime,
          sourceStatus: RateSourceStatus.freshRemote,
        ),
      );

      final remote = _FakeRemoteDataSource(response: freshResponse);
      final now = fetchTime.add(const Duration(minutes: 16)); // past 15 min
      final repository = ExchangeRateRepositoryImpl(
        remoteDataSource: remote,
        localDataSource: local,
        clock: () => now,
      );

      final snapshot = await repository.getSnapshot();

      expect(remote.callCount, 1);
      expect(snapshot.sourceStatus, RateSourceStatus.freshRemote);
      expect(snapshot.rates['EUR'], 0.87); // from the fake's freshResponse
    },
  );

  test(
    'refresh() calls remote even when the cached snapshot is still fresh',
    () async {
      final local = ExchangeRateLocalDataSource(box);
      final fetchTime = DateTime(2026, 7, 10, 12);
      local.writeSnapshot(
        RateSnapshotModel(
          baseCurrency: 'USD',
          rates: const {'EUR': 0.87},
          fetchedAt: fetchTime,
          sourceStatus: RateSourceStatus.freshRemote,
        ),
      );

      final remote = _FakeRemoteDataSource(response: freshResponse);
      final now = fetchTime.add(const Duration(minutes: 1)); // still fresh
      final repository = ExchangeRateRepositoryImpl(
        remoteDataSource: remote,
        localDataSource: local,
        clock: () => now,
      );

      final snapshot = await repository.refresh();

      expect(remote.callCount, 1);
      expect(snapshot.fetchedAt, now);
    },
  );
}
