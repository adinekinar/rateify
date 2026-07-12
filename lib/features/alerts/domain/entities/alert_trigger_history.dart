/// §10.9 Alert Trigger History — one row per fired trigger (never per
/// check), so its row count directly reflects how many times an alert has
/// actually notified the user, not how many background/foreground checks
/// ran.
class AlertTriggerHistory {
  const AlertTriggerHistory({
    required this.id,
    required this.alertId,
    required this.triggeredRate,
    required this.triggeredAt,
  });

  final String id;
  final String alertId;
  final double triggeredRate;
  final DateTime triggeredAt;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AlertTriggerHistory &&
        other.id == id &&
        other.alertId == alertId &&
        other.triggeredRate == triggeredRate &&
        other.triggeredAt == triggeredAt;
  }

  @override
  int get hashCode => Object.hash(id, alertId, triggeredRate, triggeredAt);

  @override
  String toString() =>
      'AlertTriggerHistory(id: $id, alertId: $alertId, '
      'triggeredRate: $triggeredRate, triggeredAt: $triggeredAt)';
}
