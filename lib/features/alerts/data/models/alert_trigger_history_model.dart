import '../../domain/entities/alert_trigger_history.dart';

/// JSON (de)serialization for [AlertTriggerHistory] — same plain-JSON
/// storage choice as [RateAlertJsonMapper].
extension AlertTriggerHistoryJsonMapper on AlertTriggerHistory {
  Map<String, dynamic> toJson() => {
    'id': id,
    'alertId': alertId,
    'triggeredRate': triggeredRate,
    'triggeredAt': triggeredAt.toIso8601String(),
  };
}

AlertTriggerHistory alertTriggerHistoryFromJson(Map<String, dynamic> json) =>
    AlertTriggerHistory(
      id: json['id'] as String,
      alertId: json['alertId'] as String,
      triggeredRate: (json['triggeredRate'] as num).toDouble(),
      triggeredAt: DateTime.parse(json['triggeredAt'] as String),
    );
