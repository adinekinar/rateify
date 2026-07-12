import 'package:hive_flutter/hive_flutter.dart';
import 'package:workmanager/workmanager.dart';

import '../../../../core/constants/cache_constants.dart';
import '../../../converter/data/datasources/exchange_rate_local_data_source.dart';
import '../../../converter/data/datasources/exchange_rate_remote_data_source.dart';
import '../../../converter/data/repositories/exchange_rate_repository_impl.dart';
import '../../domain/usecases/check_active_alerts.dart';
import '../repositories/alert_repository_impl.dart';
import '../services/local_notification_service.dart';

/// The Workmanager entry point (§6.3). Runs in a standalone background
/// isolate with no Flutter widget tree and no Riverpod `ProviderContainer`
/// carried over from the foreground app, so — like `main()` — it composes
/// its own dependencies directly from Hive boxes rather than reading
/// providers. Must stay a top-level function (not a class method) and keep
/// this exact annotation so the Dart compiler doesn't tree-shake it away as
/// unreferenced; `Workmanager().initialize()` resolves it by callback
/// handle, not by any Dart-level reference.
@pragma('vm:entry-point')
void alertBackgroundCallbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    await Hive.initFlutter();

    final rateSnapshotBox = await Hive.openBox<dynamic>(
      CacheConstants.rateSnapshotBoxName,
    );
    final alertBox = await Hive.openBox<dynamic>(CacheConstants.alertBoxName);
    final alertTriggerHistoryBox = await Hive.openBox<dynamic>(
      CacheConstants.alertTriggerHistoryBoxName,
    );

    final exchangeRateRepository = ExchangeRateRepositoryImpl(
      remoteDataSource: ExchangeRateRemoteDataSource(),
      localDataSource: ExchangeRateLocalDataSource(rateSnapshotBox),
    );
    final alertRepository = HiveAlertRepository(alertBox, alertTriggerHistoryBox);
    final notificationService = LocalNotificationService();
    // Never prompts from the background isolate (§20.5) — permission is
    // only ever requested from the foreground app in `main()`.
    await notificationService.initialize(requestPermissions: false);

    final usecase = CheckActiveAlertsUsecase(
      alertRepository: alertRepository,
      exchangeRateRepository: exchangeRateRepository,
      notificationService: notificationService,
    );
    await usecase();

    return true;
  });
}
