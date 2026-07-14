import 'package:flutter_test/flutter_test.dart';
import 'package:rateify/features/alerts/domain/entities/rate_alert.dart';
import 'package:rateify/features/alerts/domain/services/alert_checker.dart';

void main() {
  RateAlert alert({
    AlertDirection direction = AlertDirection.aboveTarget,
    double targetRate = 160,
    bool isArmed = true,
    DateTime? lastCheckedAt,
    DateTime? lastTriggeredAt,
  }) {
    final now = DateTime(2026, 7);
    return RateAlert(
      id: 'alert-1',
      baseCurrency: 'USD',
      quoteCurrency: 'JPY',
      targetRate: targetRate,
      direction: direction,
      isActive: true,
      isArmed: isArmed,
      lastCheckedAt: lastCheckedAt,
      lastTriggeredAt: lastTriggeredAt,
      createdAt: now,
      updatedAt: now,
    );
  }

  group('satisfiesTrigger (TC-ALERT-003/004/005)', () {
    test(
      'aboveTarget: current rate equal to target triggers (TC-ALERT-003)',
      () {
        expect(
          AlertChecker.satisfiesTrigger(
            currentRate: 160,
            targetRate: 160,
            direction: AlertDirection.aboveTarget,
          ),
          isTrue,
        );
      },
    );

    test(
      'belowTarget: current rate equal to target triggers (TC-ALERT-004)',
      () {
        expect(
          AlertChecker.satisfiesTrigger(
            currentRate: 105,
            targetRate: 105,
            direction: AlertDirection.belowTarget,
          ),
          isTrue,
        );
      },
    );

    test(
      'aboveTarget: current rate just below target does not trigger (TC-ALERT-005)',
      () {
        expect(
          AlertChecker.satisfiesTrigger(
            currentRate: 159.99,
            targetRate: 160,
            direction: AlertDirection.aboveTarget,
          ),
          isFalse,
        );
      },
    );

    test('belowTarget: current rate just above target does not trigger', () {
      expect(
        AlertChecker.satisfiesTrigger(
          currentRate: 105.01,
          targetRate: 105,
          direction: AlertDirection.belowTarget,
        ),
        isFalse,
      );
    });
  });

  group('checkOne — trigger and history bookkeeping (TC-ALERT-006)', () {
    test(
      'armed alert whose condition is met triggers, disarms, and stamps lastTriggeredAt',
      () {
        final checkedAt = DateTime(2026, 7, 1, 12);
        final outcome = AlertChecker.checkOne(
          alert: alert(),
          currentRate: 161,
          checkedAt: checkedAt,
        );

        expect(outcome.triggered, isTrue);
        expect(outcome.triggeredRate, 161);
        expect(outcome.updatedAlert.isArmed, isFalse);
        expect(outcome.updatedAlert.lastTriggeredAt, checkedAt);
        expect(outcome.updatedAlert.lastCheckedAt, checkedAt);
      },
    );

    test('an alert whose condition is not met never triggers', () {
      final outcome = AlertChecker.checkOne(
        alert: alert(),
        currentRate: 150,
        checkedAt: DateTime(2026, 7),
      );

      expect(outcome.triggered, isFalse);
      expect(outcome.updatedAlert.isArmed, isTrue);
      expect(outcome.updatedAlert.lastTriggeredAt, isNull);
    });

    test(
      'an unresolved rate (null) never triggers and only bumps lastCheckedAt',
      () {
        final checkedAt = DateTime(2026, 7);
        final original = alert(isArmed: false);

        final outcome = AlertChecker.checkOne(
          alert: original,
          currentRate: null,
          checkedAt: checkedAt,
        );

        expect(outcome.triggered, isFalse);
        // Not real evidence the rate left the zone, so isArmed is left as-is.
        expect(outcome.updatedAlert.isArmed, isFalse);
        expect(outcome.updatedAlert.lastCheckedAt, checkedAt);
      },
    );
  });

  group('edge-triggered rearm sequence (TC-ALERT-007/008/013/014) — the full '
      'lifecycle across many separate check cycles', () {
    test('TC-ALERT-007: staying in-zone across the very next check (same '
        'cycle shape) does not trigger again', () {
      final firstCheck = AlertChecker.checkOne(
        alert: alert(),
        currentRate: 161,
        checkedAt: DateTime(2026, 7),
      );
      expect(firstCheck.triggered, isTrue);

      final secondCheck = AlertChecker.checkOne(
        alert: firstCheck.updatedAlert,
        currentRate: 161,
        checkedAt: DateTime(2026, 7, 1, 1),
      );
      expect(secondCheck.triggered, isFalse);
      expect(secondCheck.updatedAlert.isArmed, isFalse);
    });

    test('TC-ALERT-008: condition stays true across many separate subsequent '
        'check cycles — no further trigger no matter how many cycles pass', () {
      var current = alert();

      final first = AlertChecker.checkOne(
        alert: current,
        currentRate: 165,
        checkedAt: DateTime(2026, 7),
      );
      expect(first.triggered, isTrue);
      current = first.updatedAlert;

      // Ten more separate check cycles, rate still parked well inside
      // the trigger zone every single time.
      for (var hour = 1; hour <= 10; hour++) {
        final outcome = AlertChecker.checkOne(
          alert: current,
          currentRate: 165,
          checkedAt: DateTime(2026, 7, 1, hour),
        );
        expect(
          outcome.triggered,
          isFalse,
          reason: 'cycle $hour must not re-trigger while still in-zone',
        );
        expect(outcome.updatedAlert.isArmed, isFalse);
        // lastTriggeredAt must stay pinned to the original trigger —
        // it is never touched by a no-op cycle.
        expect(
          outcome.updatedAlert.lastTriggeredAt,
          first.updatedAlert.lastTriggeredAt,
        );
        current = outcome.updatedAlert;
      }
    });

    test('TC-ALERT-013: the rate moving back outside the zone re-arms with '
        'no notification on that check itself', () {
      final triggered = AlertChecker.checkOne(
        alert: alert(),
        currentRate: 165,
        checkedAt: DateTime(2026, 7),
      );
      expect(triggered.updatedAlert.isArmed, isFalse);

      final leftZone = AlertChecker.checkOne(
        alert: triggered.updatedAlert,
        currentRate: 155,
        checkedAt: DateTime(2026, 7, 1, 1),
      );

      expect(leftZone.triggered, isFalse);
      expect(leftZone.updatedAlert.isArmed, isTrue);
    });

    test('TC-ALERT-014: re-entering the zone after having left it and '
        're-armed triggers again — the only way a second notification '
        'happens for the same alert', () {
      var current = alert();

      final firstTrigger = AlertChecker.checkOne(
        alert: current,
        currentRate: 165,
        checkedAt: DateTime(2026, 7),
      );
      expect(firstTrigger.triggered, isTrue);
      current = firstTrigger.updatedAlert;

      // Stays in-zone for a few more cycles — must stay quiet.
      for (var hour = 1; hour <= 3; hour++) {
        final outcome = AlertChecker.checkOne(
          alert: current,
          currentRate: 165,
          checkedAt: DateTime(2026, 7, 1, hour),
        );
        expect(outcome.triggered, isFalse);
        current = outcome.updatedAlert;
      }

      // Leaves the zone — silent re-arm.
      final rearmed = AlertChecker.checkOne(
        alert: current,
        currentRate: 150,
        checkedAt: DateTime(2026, 7, 1, 4),
      );
      expect(rearmed.triggered, isFalse);
      expect(rearmed.updatedAlert.isArmed, isTrue);
      current = rearmed.updatedAlert;

      // Stays outside the zone for a couple more cycles — still silent,
      // still armed, no double re-arm side effects.
      for (var hour = 5; hour <= 6; hour++) {
        final outcome = AlertChecker.checkOne(
          alert: current,
          currentRate: 148,
          checkedAt: DateTime(2026, 7, 1, hour),
        );
        expect(outcome.triggered, isFalse);
        expect(outcome.updatedAlert.isArmed, isTrue);
        current = outcome.updatedAlert;
      }

      // Re-enters the zone — this is the only way a second notification
      // can happen for the same alert.
      final secondTrigger = AlertChecker.checkOne(
        alert: current,
        currentRate: 170,
        checkedAt: DateTime(2026, 7, 1, 7),
      );
      expect(secondTrigger.triggered, isTrue);
      expect(secondTrigger.triggeredRate, 170);
      expect(secondTrigger.updatedAlert.isArmed, isFalse);
      expect(
        secondTrigger.updatedAlert.lastTriggeredAt,
        DateTime(2026, 7, 1, 7),
      );
    });
  });
}
