/// §6.2 direction rule.
enum AlertDirection { aboveTarget, belowTarget }

/// §10.8 Rate Alert.
class RateAlert {
  const RateAlert({
    required this.id,
    required this.baseCurrency,
    required this.quoteCurrency,
    required this.targetRate,
    required this.direction,
    required this.isActive,
    this.isArmed = true,
    this.lastCheckedAt,
    this.lastTriggeredAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String baseCurrency;
  final String quoteCurrency;
  final double targetRate;
  final AlertDirection direction;
  final bool isActive;

  /// §6.4/§10.8 (revised, Batch 06) — backs the edge-triggered notification
  /// model. `true` means "ready to fire on the next entry into the trigger
  /// zone"; set to `false` immediately after a trigger fires, and back to
  /// `true` once a later check finds the rate has left the zone. See
  /// `AlertChecker` for the state machine that owns these transitions.
  final bool isArmed;
  final DateTime? lastCheckedAt;
  final DateTime? lastTriggeredAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  RateAlert copyWith({
    String? baseCurrency,
    String? quoteCurrency,
    double? targetRate,
    AlertDirection? direction,
    bool? isActive,
    bool? isArmed,
    DateTime? lastCheckedAt,
    DateTime? lastTriggeredAt,
    DateTime? updatedAt,
  }) {
    return RateAlert(
      id: id,
      baseCurrency: baseCurrency ?? this.baseCurrency,
      quoteCurrency: quoteCurrency ?? this.quoteCurrency,
      targetRate: targetRate ?? this.targetRate,
      direction: direction ?? this.direction,
      isActive: isActive ?? this.isActive,
      isArmed: isArmed ?? this.isArmed,
      lastCheckedAt: lastCheckedAt ?? this.lastCheckedAt,
      lastTriggeredAt: lastTriggeredAt ?? this.lastTriggeredAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RateAlert &&
        other.id == id &&
        other.baseCurrency == baseCurrency &&
        other.quoteCurrency == quoteCurrency &&
        other.targetRate == targetRate &&
        other.direction == direction &&
        other.isActive == isActive &&
        other.isArmed == isArmed &&
        other.lastCheckedAt == lastCheckedAt &&
        other.lastTriggeredAt == lastTriggeredAt &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(
    id,
    baseCurrency,
    quoteCurrency,
    targetRate,
    direction,
    isActive,
    isArmed,
    lastCheckedAt,
    lastTriggeredAt,
    createdAt,
    updatedAt,
  );

  @override
  String toString() =>
      'RateAlert(id: $id, baseCurrency: $baseCurrency, quoteCurrency: $quoteCurrency, '
      'targetRate: $targetRate, direction: $direction, isActive: $isActive, '
      'isArmed: $isArmed, lastCheckedAt: $lastCheckedAt, '
      'lastTriggeredAt: $lastTriggeredAt, createdAt: $createdAt, updatedAt: $updatedAt)';
}
