import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../converter/presentation/providers/converter_providers.dart';
import '../../domain/entities/alert_trigger_history.dart';
import '../../domain/entities/rate_alert.dart';
import '../../domain/repositories/alert_repository.dart';
import '../../domain/services/alert_background_scheduler.dart';
import '../../domain/services/alert_notification_service.dart';
import '../../domain/usecases/check_active_alerts.dart';

/// §12.1 core provider. Overridden in `main()` with a real
/// [HiveAlertRepository] once the alert/alert-trigger-history Hive boxes
/// have been opened — same composition-root pattern as the other
/// repository providers.
final alertRepositoryProvider = Provider<AlertRepository>((ref) {
  throw UnimplementedError(
    'alertRepositoryProvider must be overridden with a HiveAlertRepository in main()',
  );
});

/// Overridden in `main()` with a real [LocalNotificationService], already
/// `initialize()`d there.
final alertNotificationServiceProvider = Provider<AlertNotificationService>((
  ref,
) {
  throw UnimplementedError(
    'alertNotificationServiceProvider must be overridden with a LocalNotificationService in main()',
  );
});

/// Overridden in `main()` with a real [WorkmanagerAlertBackgroundScheduler],
/// already `initialize()`d and registered there. The settings feature reads
/// this to reschedule (§6.3) whenever the user changes the alert-check
/// frequency.
final alertBackgroundSchedulerProvider = Provider<AlertBackgroundScheduler>((
  ref,
) {
  throw UnimplementedError(
    'alertBackgroundSchedulerProvider must be overridden with a WorkmanagerAlertBackgroundScheduler in main()',
  );
});

/// All alerts, in whatever order the repository returns them — filtering
/// (e.g. active-only) is the page's job, same as `tripListControllerProvider`/
/// `benchmarksProvider`.
///
/// Plain `Notifier`, not `AsyncNotifierProvider` as §12.3 sketches for
/// sibling controllers — Hive reads are synchronous, same deliberate
/// deviation `BenchmarksController`/`TripListController` already made.
final alertListControllerProvider =
    NotifierProvider<AlertListController, List<RateAlert>>(
      AlertListController.new,
    );

class AlertListController extends Notifier<List<RateAlert>> {
  @override
  List<RateAlert> build() => ref.watch(alertRepositoryProvider).getAllAlerts();

  void createAlert({
    required String baseCurrency,
    required String quoteCurrency,
    required double targetRate,
    required AlertDirection direction,
  }) {
    ref
        .read(alertRepositoryProvider)
        .createAlert(
          baseCurrency: baseCurrency,
          quoteCurrency: quoteCurrency,
          targetRate: targetRate,
          direction: direction,
        );
    _reload();
  }

  void editAlert({
    required String id,
    required String baseCurrency,
    required String quoteCurrency,
    required double targetRate,
    required AlertDirection direction,
  }) {
    ref
        .read(alertRepositoryProvider)
        .editAlert(
          id: id,
          baseCurrency: baseCurrency,
          quoteCurrency: quoteCurrency,
          targetRate: targetRate,
          direction: direction,
        );
    _reload();
  }

  void deleteAlert(String id) {
    ref.read(alertRepositoryProvider).deleteAlert(id);
    _reload();
  }

  void activateAlert(String id) {
    ref.read(alertRepositoryProvider).activateAlert(id);
    _reload();
  }

  void deactivateAlert(String id) {
    ref.read(alertRepositoryProvider).deactivateAlert(id);
    _reload();
  }

  List<AlertTriggerHistory> triggerHistoryFor(String alertId) =>
      ref.read(alertRepositoryProvider).getTriggerHistoryForAlert(alertId);

  void _reload() {
    state = ref.read(alertRepositoryProvider).getAllAlerts();
  }
}

final checkActiveAlertsUsecaseProvider = Provider<CheckActiveAlertsUsecase>((
  ref,
) {
  return CheckActiveAlertsUsecase(
    alertRepository: ref.read(alertRepositoryProvider),
    exchangeRateRepository: ref.read(exchangeRateRepositoryProvider),
    notificationService: ref.read(alertNotificationServiceProvider),
  );
});

/// §6.3/§20.5 — the reliable foreground check: runs once per app open,
/// independent of whatever state the best-effort background scheduler is
/// in. Meant to be triggered exactly once via `ref.read` (not `watch`) from
/// `RootShell`'s `initState`; a `FutureProvider` so the app doesn't need its
/// own `AsyncNotifier` scaffolding for a fire-and-forget action.
final foregroundAlertCheckProvider = FutureProvider<void>((ref) async {
  await ref.read(checkActiveAlertsUsecaseProvider)();
  // The alert list (and, transitively, the trigger-history sheet) may now
  // be stale if the user is already looking at the Alerts tab.
  ref.invalidate(alertListControllerProvider);
});
