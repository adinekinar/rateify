import '../entities/rate_alert.dart';

/// Outcome of running [AlertChecker.checkOne] for a single alert on a
/// single check cycle.
class AlertCheckOutcome {
  const AlertCheckOutcome({
    required this.updatedAlert,
    required this.triggered,
    this.triggeredRate,
  });

  /// Always non-null: every check bumps `lastCheckedAt` at minimum, even
  /// when nothing else about the alert changes.
  final RateAlert updatedAlert;

  /// Whether this specific check is the one that should save trigger
  /// history and show a notification (§6.4 step 1-3). `false` covers both
  /// "condition not met" and "condition met but still disarmed from a
  /// previous trigger" — callers only need this one flag to decide whether
  /// to act.
  final bool triggered;

  /// Only set when [triggered] is `true`.
  final double? triggeredRate;
}

/// §6.4 Trigger Rule, revised for the edge-triggered model (§10.8): an
/// alert only notifies on the transition *into* its trigger zone, not on
/// every check while it remains there. No I/O, no Riverpod — pure state
/// transitions over already-known values, independently unit-testable.
///
/// The state machine, per alert, per check:
/// - condition met AND armed -> trigger, become disarmed.
/// - condition met AND disarmed -> no-op (still "inside the zone" from an
///   earlier trigger; wait for it to leave before it can fire again).
/// - condition not met AND disarmed -> silently re-arm, no notification.
/// - condition not met AND armed -> no-op (nothing has happened yet).
abstract final class AlertChecker {
  /// `currentRate >= targetRate` for [AlertDirection.aboveTarget], or
  /// `currentRate <= targetRate` for [AlertDirection.belowTarget] (§6.4).
  static bool satisfiesTrigger({
    required double currentRate,
    required double targetRate,
    required AlertDirection direction,
  }) => switch (direction) {
    AlertDirection.aboveTarget => currentRate >= targetRate,
    AlertDirection.belowTarget => currentRate <= targetRate,
  };

  /// [currentRate] is the latest base->quote rate for [alert]'s pair, or
  /// `null` if no rate could be resolved for it this cycle (e.g. an
  /// unavailable snapshot). An unresolved rate is treated as "condition not
  /// met" for triggering purposes, but — since it isn't real evidence the
  /// rate actually left the zone — it does *not* re-arm a disarmed alert;
  /// only an actually-resolved out-of-zone rate does that.
  static AlertCheckOutcome checkOne({
    required RateAlert alert,
    required double? currentRate,
    required DateTime checkedAt,
  }) {
    if (currentRate == null) {
      return AlertCheckOutcome(
        updatedAlert: alert.copyWith(lastCheckedAt: checkedAt),
        triggered: false,
      );
    }

    final satisfies = satisfiesTrigger(
      currentRate: currentRate,
      targetRate: alert.targetRate,
      direction: alert.direction,
    );

    if (satisfies && alert.isArmed) {
      return AlertCheckOutcome(
        updatedAlert: alert.copyWith(
          lastCheckedAt: checkedAt,
          lastTriggeredAt: checkedAt,
          isArmed: false,
        ),
        triggered: true,
        triggeredRate: currentRate,
      );
    }

    if (!satisfies && !alert.isArmed) {
      return AlertCheckOutcome(
        updatedAlert: alert.copyWith(lastCheckedAt: checkedAt, isArmed: true),
        triggered: false,
      );
    }

    // (satisfies && !isArmed): still inside the zone from an earlier
    // trigger, wait for it to leave. (!satisfies && isArmed): outside the
    // zone and already armed — nothing to do either way.
    return AlertCheckOutcome(
      updatedAlert: alert.copyWith(lastCheckedAt: checkedAt),
      triggered: false,
    );
  }
}
