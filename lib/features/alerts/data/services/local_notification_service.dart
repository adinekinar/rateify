import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../domain/entities/rate_alert.dart';
import '../../domain/services/alert_notification_service.dart';

/// §6.5 notification text — pure text computation, independently
/// unit-testable without pumping a plugin/platform channel, same discipline
/// as the converter feature's `rateTimestampLabelText`. Exact example
/// format: "USD/JPY reached 160.25" / "Your target was above 160.00."
({String title, String body}) alertTriggerNotificationText(
  RateAlert alert,
  double triggeredRate,
) {
  final directionWord = alert.direction == AlertDirection.aboveTarget
      ? 'above'
      : 'below';
  final title =
      '${alert.baseCurrency}/${alert.quoteCurrency} reached '
      '${triggeredRate.toStringAsFixed(2)}';
  final body =
      'Your target was $directionWord ${alert.targetRate.toStringAsFixed(2)}.';
  return (title: title, body: body);
}

/// [AlertNotificationService] backed by `flutter_local_notifications`.
///
/// Storage/init choice: a single reusable `FlutterLocalNotificationsPlugin`
/// instance, `initialize()`d once per process. Both the foreground app and
/// the Workmanager background isolate are separate processes/isolates and
/// each construct + initialize their own instance of this class — see
/// `main.dart` and `alert_background_dispatcher.dart` respectively.
class LocalNotificationService implements AlertNotificationService {
  LocalNotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const _channelId = 'rate_alert_channel';
  static const _channelName = 'Rate Alerts';
  static const _channelDescription =
      'Notifications for currency rate alerts reaching their target.';

  final FlutterLocalNotificationsPlugin _plugin;

  @override
  Future<void> initialize({bool requestPermissions = true}) async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    // §6.5 notifications don't need alarms/critical alerts — the default
    // Darwin request flags (alert/sound/badge) are exactly what's needed.
    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: requestPermissions,
      requestSoundPermission: requestPermissions,
      requestBadgePermission: requestPermissions,
    );
    await _plugin.initialize(
      InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    // Android 13+ (API 33) requires a separate runtime permission request —
    // Darwin's is already covered by the `initialize()` flags above.
    if (requestPermissions && defaultTargetPlatform == TargetPlatform.android) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    }
  }

  @override
  Future<void> showTrigger(RateAlert alert, double triggeredRate) async {
    final text = alertTriggerNotificationText(alert, triggeredRate);

    await _plugin.show(
      _notificationIdFor(alert.id),
      text.title,
      text.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  /// One notification id per alert (so a fresh trigger replaces the same
  /// alert's previous notification rather than piling up), derived from the
  /// alert's own id — `flutter_local_notifications` requires a 32-bit int.
  int _notificationIdFor(String alertId) => alertId.hashCode & 0x7fffffff;
}
