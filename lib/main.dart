import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/constants/cache_constants.dart';
import 'features/benchmarks/data/repositories/benchmark_repository_impl.dart';
import 'features/benchmarks/presentation/providers/benchmark_providers.dart';
import 'features/converter/data/datasources/exchange_rate_local_data_source.dart';
import 'features/converter/data/datasources/exchange_rate_remote_data_source.dart';
import 'features/converter/data/repositories/exchange_rate_repository_impl.dart';
import 'features/converter/presentation/providers/converter_providers.dart';
import 'features/settings/data/repositories/settings_repository_impl.dart';
import 'features/settings/presentation/providers/settings_providers.dart';

/// Composition root — the one place allowed to wire a concrete Hive-backed
/// repository into a provider override (§18.8 only restricts the
/// *presentation* layer's own widgets from importing Hive directly).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  final settingsBox = await Hive.openBox<dynamic>(
    CacheConstants.appSettingsBoxName,
  );
  final settingsRepository = HiveSettingsRepository(settingsBox);

  final rateSnapshotBox = await Hive.openBox<dynamic>(
    CacheConstants.rateSnapshotBoxName,
  );
  final exchangeRateRepository = ExchangeRateRepositoryImpl(
    remoteDataSource: ExchangeRateRemoteDataSource(),
    localDataSource: ExchangeRateLocalDataSource(rateSnapshotBox),
  );

  final benchmarkBox = await Hive.openBox<dynamic>(
    CacheConstants.benchmarkBoxName,
  );
  final benchmarkRepository = HiveBenchmarkRepository(benchmarkBox);

  runApp(
    ProviderScope(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(settingsRepository),
        exchangeRateRepositoryProvider.overrideWithValue(
          exchangeRateRepository,
        ),
        benchmarkRepositoryProvider.overrideWithValue(benchmarkRepository),
      ],
      child: const RateifyApp(),
    ),
  );
}
