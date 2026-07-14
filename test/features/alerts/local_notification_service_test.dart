import 'package:flutter_test/flutter_test.dart';
import 'package:rateify/features/alerts/data/services/local_notification_service.dart';
import 'package:rateify/features/alerts/domain/entities/rate_alert.dart';

void main() {
  RateAlert alert({
    required AlertDirection direction,
    required double targetRate,
  }) {
    final now = DateTime(2026, 7);
    return RateAlert(
      id: 'alert-1',
      baseCurrency: 'USD',
      quoteCurrency: 'JPY',
      targetRate: targetRate,
      direction: direction,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );
  }

  group('alertTriggerNotificationText (TC-ALERT-009, §6.5)', () {
    test('aboveTarget matches the exact §6.5 example format', () {
      final text = alertTriggerNotificationText(
        alert(direction: AlertDirection.aboveTarget, targetRate: 160),
        160.25,
      );

      expect(text.title, 'USD/JPY reached 160.25');
      expect(text.body, 'Your target was above 160.00.');
    });

    test(
      'belowTarget uses "below" and formats the triggered rate to 2 decimals',
      () {
        final text = alertTriggerNotificationText(
          alert(direction: AlertDirection.belowTarget, targetRate: 105),
          104.999,
        );

        expect(text.title, 'USD/JPY reached 105.00');
        expect(text.body, 'Your target was below 105.00.');
      },
    );
  });
}
