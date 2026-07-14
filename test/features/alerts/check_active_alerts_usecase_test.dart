import 'package:flutter_test/flutter_test.dart';
import 'package:rateify/features/alerts/domain/entities/rate_alert.dart';
import 'package:rateify/features/alerts/domain/usecases/check_active_alerts.dart';
import 'package:rateify/features/converter/data/models/rate_snapshot_model.dart';

import '../../test_helpers/fake_alert_notification_service.dart';
import '../../test_helpers/fake_alert_repository.dart';
import '../../test_helpers/fake_exchange_rate_repository.dart';

void main() {
  RateAlert alert({
    String id = 'alert-1',
    String baseCurrency = 'USD',
    String quoteCurrency = 'JPY',
    double targetRate = 160,
    AlertDirection direction = AlertDirection.aboveTarget,
    bool isActive = true,
    bool isArmed = true,
  }) {
    final now = DateTime(2026, 7);
    return RateAlert(
      id: id,
      baseCurrency: baseCurrency,
      quoteCurrency: quoteCurrency,
      targetRate: targetRate,
      direction: direction,
      isActive: isActive,
      isArmed: isArmed,
      createdAt: now,
      updatedAt: now,
    );
  }

  ({
    FakeAlertRepository repository,
    FakeExchangeRateRepository exchangeRate,
    FakeAlertNotificationService notifications,
    CheckActiveAlertsUsecase usecase,
  })
  buildHarness({List<RateAlert>? initialAlerts, DateTime Function()? now}) {
    final repository = FakeAlertRepository(initialAlerts: initialAlerts);
    final exchangeRate = FakeExchangeRateRepository();
    final notifications = FakeAlertNotificationService();
    final usecase = CheckActiveAlertsUsecase(
      alertRepository: repository,
      exchangeRateRepository: exchangeRate,
      notificationService: notifications,
      now: now,
    );
    return (
      repository: repository,
      exchangeRate: exchangeRate,
      notifications: notifications,
      usecase: usecase,
    );
  }

  test(
    'a fresh trigger saves history, updates lastTriggeredAt, disarms, and '
    'shows a notification with §6.5 short/actionable text (TC-ALERT-006/009)',
    () async {
      final h = buildHarness(initialAlerts: [alert(targetRate: 150)]);

      await h.usecase();

      final updated = h.repository.getAllAlerts().single;
      expect(updated.isArmed, isFalse);
      expect(updated.lastTriggeredAt, isNotNull);
      expect(updated.lastCheckedAt, isNotNull);

      expect(h.repository.getTriggerHistoryForAlert('alert-1'), hasLength(1));
      expect(
        h.repository.getTriggerHistoryForAlert('alert-1').single.triggeredRate,
        160, // USD/JPY from the fake snapshot's default rates
      );

      expect(h.notifications.shownNotifications, hasLength(1));
      final shown = h.notifications.shownNotifications.single;
      expect(shown.alert.id, 'alert-1');
      expect(shown.triggeredRate, 160);
    },
  );

  test(
    'inactive alerts are skipped entirely by the checker (TC-ALERT-002)',
    () async {
      final h = buildHarness(
        initialAlerts: [alert(targetRate: 1, isActive: false)],
      );

      await h.usecase();

      // Never even checked — isArmed/lastCheckedAt stay exactly as created.
      final unchanged = h.repository.getAllAlerts().single;
      expect(unchanged.lastCheckedAt, isNull);
      expect(h.notifications.shownNotifications, isEmpty);
    },
  );

  test(
    'works for a currency pair that has nothing to do with converter tiles, '
    'via the same anchor-base cross-rate math as ConversionCalculator',
    () async {
      // JPY/IDR: neither is the snapshot's own anchor base (USD) — this
      // only resolves if the usecase genuinely reuses the cross-rate
      // approach rather than assuming one side is already the base.
      final h = buildHarness(
        initialAlerts: [
          alert(baseCurrency: 'JPY', quoteCurrency: 'IDR', targetRate: 90),
        ],
      );

      await h.usecase();

      // rate(JPY->IDR) = rateFromBase(IDR)/rateFromBase(JPY) = 16000/160 = 100
      expect(h.notifications.shownNotifications, hasLength(1));
      expect(h.notifications.shownNotifications.single.triggeredRate, 100);
    },
  );

  test('edge-triggered rearm sequence end-to-end through the usecase '
      '(TC-ALERT-007/008/013/014): trigger once, stay silent across several '
      'in-zone cycles, go quiet on leaving the zone, then trigger again on '
      're-entry', () async {
    var currentTime = DateTime(2026, 7);
    final h = buildHarness(
      initialAlerts: [alert(targetRate: 150)], // fake snapshot has 160
      now: () => currentTime,
    );

    // Cycle 1: rate (160) already satisfies -> first trigger.
    await h.usecase();
    expect(h.notifications.shownNotifications, hasLength(1));
    expect(h.repository.getAllAlerts().single.isArmed, isFalse);

    // Cycles 2-6: still in-zone (rate never changes in the fake), five
    // separate subsequent check cycles — must stay completely silent.
    for (var i = 0; i < 5; i++) {
      currentTime = currentTime.add(const Duration(hours: 6));
      await h.usecase();
    }
    expect(
      h.notifications.shownNotifications,
      hasLength(1),
      reason: 'no re-trigger while still parked inside the trigger zone',
    );
    expect(h.repository.getAllAlerts().single.isArmed, isFalse);

    // The rate leaves the zone -> silent re-arm, no notification.
    h.exchangeRate.setSnapshot(
      RateSnapshotModel(
        baseCurrency: 'USD',
        rates: const {'JPY': 140.0},
        fetchedAt: currentTime,
        sourceStatus: RateSourceStatus.freshRemote,
      ),
    );
    currentTime = currentTime.add(const Duration(hours: 6));
    await h.usecase();
    expect(h.notifications.shownNotifications, hasLength(1));
    expect(h.repository.getAllAlerts().single.isArmed, isTrue);

    // Stays outside the zone for a couple more cycles — still silent.
    for (var i = 0; i < 2; i++) {
      currentTime = currentTime.add(const Duration(hours: 6));
      await h.usecase();
    }
    expect(h.notifications.shownNotifications, hasLength(1));
    expect(h.repository.getAllAlerts().single.isArmed, isTrue);

    // Re-enters the zone -> triggers again. This is the only way a
    // second notification can happen for the same alert.
    h.exchangeRate.setSnapshot(
      RateSnapshotModel(
        baseCurrency: 'USD',
        rates: const {'JPY': 165.0},
        fetchedAt: currentTime,
        sourceStatus: RateSourceStatus.freshRemote,
      ),
    );
    currentTime = currentTime.add(const Duration(hours: 6));
    await h.usecase();

    expect(h.notifications.shownNotifications, hasLength(2));
    expect(h.notifications.shownNotifications.last.triggeredRate, 165);
    expect(h.repository.getAllAlerts().single.isArmed, isFalse);
  });
}
