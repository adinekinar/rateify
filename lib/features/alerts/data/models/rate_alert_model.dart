import '../../domain/entities/rate_alert.dart';

/// JSON (de)serialization for [RateAlert] — same plain-JSON-per-id-key
/// storage choice as the trips/benchmarks features (see
/// `TripJsonMapper`'s doc comment for the full reasoning).
extension RateAlertJsonMapper on RateAlert {
  Map<String, dynamic> toJson() => {
    'id': id,
    'baseCurrency': baseCurrency,
    'quoteCurrency': quoteCurrency,
    'targetRate': targetRate,
    'direction': direction.name,
    'isActive': isActive,
    'isArmed': isArmed,
    'lastCheckedAt': lastCheckedAt?.toIso8601String(),
    'lastTriggeredAt': lastTriggeredAt?.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}

RateAlert rateAlertFromJson(Map<String, dynamic> json) => RateAlert(
  id: json['id'] as String,
  baseCurrency: json['baseCurrency'] as String,
  quoteCurrency: json['quoteCurrency'] as String,
  targetRate: (json['targetRate'] as num).toDouble(),
  direction: AlertDirection.values.byName(json['direction'] as String),
  isActive: json['isActive'] as bool,
  isArmed: json['isArmed'] as bool,
  lastCheckedAt: (json['lastCheckedAt'] as String?) == null
      ? null
      : DateTime.parse(json['lastCheckedAt'] as String),
  lastTriggeredAt: (json['lastTriggeredAt'] as String?) == null
      ? null
      : DateTime.parse(json['lastTriggeredAt'] as String),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);
