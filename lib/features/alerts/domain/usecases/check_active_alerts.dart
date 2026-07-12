import '../../../../core/utils/id_generator.dart';
import '../../../converter/domain/repositories/exchange_rate_repository.dart';
import '../../../converter/domain/services/conversion_calculator.dart';
import '../entities/alert_trigger_history.dart';
import '../repositories/alert_repository.dart';
import '../services/alert_checker.dart';
import '../services/alert_notification_service.dart';

/// The one place §6.3/§6.4/§20.5 come together: fetch the latest rate
/// snapshot once, run [AlertChecker] over every active alert, persist the
/// outcome, and notify for any fresh trigger.
///
/// Deliberately I/O-through-interfaces only (repository/exchange-rate/
/// notification abstractions, no Hive/Dio/plugin specifics) so this exact
/// class can run from two very different call sites unchanged: the
/// Riverpod-wired foreground check (§20.5 — runs when the app opens,
/// regardless of background scheduler state) and the standalone Workmanager
/// background isolate, which has no Riverpod `ProviderContainer` and
/// constructs its dependencies directly instead — see
/// `alert_background_dispatcher.dart`.
class CheckActiveAlertsUsecase {
  CheckActiveAlertsUsecase({
    required this.alertRepository,
    required this.exchangeRateRepository,
    required this.notificationService,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final AlertRepository alertRepository;
  final ExchangeRateRepository exchangeRateRepository;
  final AlertNotificationService notificationService;
  final DateTime Function() _now;

  Future<void> call() async {
    final activeAlerts = alertRepository
        .getAllAlerts()
        .where((alert) => alert.isActive)
        .toList();
    if (activeAlerts.isEmpty) return;

    final snapshot = await exchangeRateRepository.getSnapshot();
    final checkedAt = _now();

    for (final alert in activeAlerts) {
      final currentRate = ConversionCalculator.rateBetween(
        snapshot: snapshot,
        fromCurrency: alert.baseCurrency,
        toCurrency: alert.quoteCurrency,
      );
      final outcome = AlertChecker.checkOne(
        alert: alert,
        currentRate: currentRate,
        checkedAt: checkedAt,
      );
      alertRepository.saveCheckedAlert(outcome.updatedAlert);

      if (outcome.triggered) {
        alertRepository.addTriggerHistory(
          AlertTriggerHistory(
            id: IdGenerator.generate(),
            alertId: alert.id,
            triggeredRate: outcome.triggeredRate!,
            triggeredAt: checkedAt,
          ),
        );
        await notificationService.showTrigger(
          outcome.updatedAlert,
          outcome.triggeredRate!,
        );
      }
    }
  }
}
