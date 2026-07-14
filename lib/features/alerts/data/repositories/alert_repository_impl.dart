import 'dart:convert';

import 'package:hive/hive.dart';

import '../../../../core/errors/cache_exception.dart';
import '../../../../core/utils/id_generator.dart';
import '../../domain/entities/alert_trigger_history.dart';
import '../../domain/entities/rate_alert.dart';
import '../../domain/repositories/alert_repository.dart';
import '../models/alert_trigger_history_model.dart';
import '../models/rate_alert_model.dart';

/// Hive-backed [AlertRepository]. Alerts and trigger-history rows each live
/// in their own `Box<dynamic>`, one JSON string per record keyed by its own
/// `id` — same storage pattern as `HiveBenchmarkRepository`/
/// `HiveTripRepository`.
class HiveAlertRepository implements AlertRepository {
  HiveAlertRepository(this._alertBox, this._historyBox);

  final Box<dynamic> _alertBox;
  final Box<dynamic> _historyBox;

  @override
  List<RateAlert> getAllAlerts() {
    return _alertBox.values
        .map(
          (raw) => rateAlertFromJson(
            jsonDecode(raw as String) as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  @override
  void createAlert({
    required String baseCurrency,
    required String quoteCurrency,
    required double targetRate,
    required AlertDirection direction,
  }) {
    final now = DateTime.now();
    _putAlert(
      RateAlert(
        id: IdGenerator.generate(),
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
    final existing = _findAlert(id);
    if (existing == null) return;
    _putAlert(
      existing.copyWith(
        baseCurrency: baseCurrency,
        quoteCurrency: quoteCurrency,
        targetRate: targetRate,
        direction: direction,
        // Editing redefines what "the trigger zone" is — see the
        // repository interface doc comment.
        isArmed: true,
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  void deleteAlert(String id) {
    _alertBox.delete(id);
    // An alert's trigger history can't outlive it — same cascade-delete
    // reasoning as `HiveTripRepository.deleteTrip`.
    final orphanedKeys = _historyBox.keys.where((key) {
      final history = _decodeHistory(_historyBox.get(key) as String?);
      return history?.alertId == id;
    }).toList();
    _historyBox.deleteAll(orphanedKeys);
  }

  @override
  void activateAlert(String id) => _setActive(id, true);

  @override
  void deactivateAlert(String id) => _setActive(id, false);

  void _setActive(String id, bool isActive) {
    final existing = _findAlert(id);
    if (existing == null) return;
    // isActive alone, deliberately not updatedAt — mirrors
    // `HiveBenchmarkRepository`'s activate/deactivate, which also leaves
    // updatedAt untouched for a pure status flip.
    _putAlert(existing.copyWith(isActive: isActive));
  }

  @override
  void saveCheckedAlert(RateAlert alert) => _putAlert(alert);

  @override
  void addTriggerHistory(AlertTriggerHistory history) {
    try {
      _historyBox.put(history.id, jsonEncode(history.toJson()));
    } catch (e) {
      throw CacheException.readWriteFailed(e.toString());
    }
  }

  @override
  List<AlertTriggerHistory> getTriggerHistoryForAlert(String alertId) {
    final all = _historyBox.values
        .map(
          (raw) => alertTriggerHistoryFromJson(
            jsonDecode(raw as String) as Map<String, dynamic>,
          ),
        )
        .where((history) => history.alertId == alertId)
        .toList();
    all.sort((a, b) => b.triggeredAt.compareTo(a.triggeredAt));
    return all;
  }

  RateAlert? _findAlert(String id) {
    final raw = _alertBox.get(id) as String?;
    if (raw == null) return null;
    return rateAlertFromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  AlertTriggerHistory? _decodeHistory(String? raw) {
    if (raw == null) return null;
    return alertTriggerHistoryFromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  void _putAlert(RateAlert alert) {
    try {
      _alertBox.put(alert.id, jsonEncode(alert.toJson()));
    } catch (e) {
      throw CacheException.readWriteFailed(e.toString());
    }
  }
}
