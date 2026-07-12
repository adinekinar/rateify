import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/constants/cache_constants.dart';
import 'features/alerts/data/repositories/alert_repository_impl.dart';
import 'features/alerts/data/services/local_notification_service.dart';
import 'features/alerts/data/services/workmanager_alert_background_scheduler.dart';
import 'features/alerts/presentation/providers/alert_providers.dart';
import 'features/benchmarks/data/repositories/benchmark_repository_impl.dart';
import 'features/benchmarks/presentation/providers/benchmark_providers.dart';
import 'features/converter/data/datasources/exchange_rate_local_data_source.dart';
import 'features/converter/data/datasources/exchange_rate_remote_data_source.dart';
import 'features/converter/data/repositories/exchange_rate_repository_impl.dart';
import 'features/converter/presentation/providers/converter_providers.dart';
import 'features/settings/data/repositories/settings_repository_impl.dart';
import 'features/settings/presentation/providers/settings_providers.dart';
import 'features/trips/data/repositories/trip_repository_impl.dart';
import 'features/trips/presentation/providers/trip_providers.dart';

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

  final tripBox = await Hive.openBox<dynamic>(CacheConstants.tripBoxName);
  final tripExpenseBox = await Hive.openBox<dynamic>(
    CacheConstants.tripExpenseBoxName,
  );
  final tripRepository = HiveTripRepository(tripBox, tripExpenseBox);

  final alertBox = await Hive.openBox<dynamic>(CacheConstants.alertBoxName);
  final alertTriggerHistoryBox = await Hive.openBox<dynamic>(
    CacheConstants.alertTriggerHistoryBoxName,
  );
  final alertRepository = HiveAlertRepository(alertBox, alertTriggerHistoryBox);

  final notificationService = LocalNotificationService();
  await notificationService.initialize();

  // §6.3 — the background scheduler is initialized and given its first
  // registration here, seeded from whatever frequency is already
  // persisted; `AppSettingsController.updateAlertCheckFrequency` handles
  // every reschedule after this point.
  final backgroundScheduler = WorkmanagerAlertBackgroundScheduler();
  await backgroundScheduler.initialize();
  await backgroundScheduler.registerPeriodicTask(
    settingsRepository.loadSettings().alertCheckFrequency,
  );

  runApp(
    ProviderScope(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(settingsRepository),
        exchangeRateRepositoryProvider.overrideWithValue(
          exchangeRateRepository,
        ),
        benchmarkRepositoryProvider.overrideWithValue(benchmarkRepository),
        tripRepositoryProvider.overrideWithValue(tripRepository),
        alertRepositoryProvider.overrideWithValue(alertRepository),
        alertNotificationServiceProvider.overrideWithValue(notificationService),
        alertBackgroundSchedulerProvider.overrideWithValue(backgroundScheduler),
      ],
      child: const RateifyApp(),
    ),
  );
}
