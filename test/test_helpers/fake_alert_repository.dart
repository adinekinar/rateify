import 'package:rateify/features/alerts/domain/entities/alert_trigger_history.dart';
import 'package:rateify/features/alerts/domain/entities/rate_alert.dart';
import 'package:rateify/features/alerts/domain/repositories/alert_repository.dart';

/// In-memory [AlertRepository] fake for widget/controller/usecase tests
/// that don't care about actual Hive persistence — only about provider
/// wiring/behavior. Mirrors `FakeBenchmarkRepository`/`FakeTripRepository`.
class FakeAlertRepository implements AlertRepository {
  FakeAlertRepository({
    List<RateAlert>? initialAlerts,
    List<AlertTriggerHistory>? initialHistory,
  }) : _alerts = List.of(initialAlerts ?? const []),
       _history = List.of(initialHistory ?? const []);

  final List<RateAlert> _alerts;
  final List<AlertTriggerHistory> _history;
  int _idCounter = 0;

  @override
  List<RateAlert> getAllAlerts() => List.unmodifiable(_alerts);

  @override
  void createAlert({
    required String baseCurrency,
    required String quoteCurrency,
    required double targetRate,
    required AlertDirection direction,
  }) {
    final now = DateTime.now();
    _alerts.add(
      RateAlert(
        id: 'fake-alert-${_idCounter++}',
        baseCurrency: baseCurrency,
        quoteCurrency: quoteCurrency,
        targetRate: targetRate,
        direction: direction,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  @override
  void editAlert({
    required String id,
    required String baseCurrency,
    required String quoteCurrency,
    required double targetRate,
    required AlertDirection direction,
  }) {
    final index = _alerts.indexWhere((alert) => alert.id == id);
    if (index == -1) return;
    _alerts[index] = _alerts[index].copyWith(
      baseCurrency: baseCurrency,
      quoteCurrency: quoteCurrency,
      targetRate: targetRate,
      direction: direction,
      isArmed: true,
      updatedAt: DateTime.now(),
    );
  }

  @override
  void deleteAlert(String id) {
    _alerts.removeWhere((alert) => alert.id == id);
    _history.removeWhere((history) => history.alertId == id);
  }

  @override
  void activateAlert(String id) => _setActive(id, true);

  @override
  void deactivateAlert(String id) => _setActive(id, false);

  void _setActive(String id, bool isActive) {
    final index = _alerts.indexWhere((alert) => alert.id == id);
    if (index == -1) return;
    _alerts[index] = _alerts[index].copyWith(isActive: isActive);
  }

  @override
  void saveCheckedAlert(RateAlert alert) {
    final index = _alerts.indexWhere((a) => a.id == alert.id);
    if (index == -1) return;
    _alerts[index] = alert;
  }

  @override
  void addTriggerHistory(AlertTriggerHistory history) => _history.add(history);

  @override
  List<AlertTriggerHistory> getTriggerHistoryForAlert(String alertId) {
    final matches = _history
        .where((history) => history.alertId == alertId)
        .toList();
    matches.sort((a, b) => b.triggeredAt.compareTo(a.triggeredAt));
    return matches;
  }
}
