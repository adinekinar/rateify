import 'package:rateify/features/alerts/domain/entities/rate_alert.dart';
import 'package:rateify/features/alerts/domain/services/alert_notification_service.dart';

class ShownNotification {
  ShownNotification(this.alert, this.triggeredRate);

  final RateAlert alert;
  final double triggeredRate;
}

/// In-memory [AlertNotificationService] fake — records every call instead
/// of touching a real plugin, so tests can assert exactly what would have
/// been shown (TC-ALERT-009) without a platform channel.
class FakeAlertNotificationService implements AlertNotificationService {
  final List<ShownNotification> shownNotifications = [];
  int initializeCallCount = 0;

  @override
  Future<void> initialize({bool requestPermissions = true}) async {
    initializeCallCount++;
  }

  @override
  Future<void> showTrigger(RateAlert alert, double triggeredRate) async {
    shownNotifications.add(ShownNotification(alert, triggeredRate));
  }
}
