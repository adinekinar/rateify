import '../entities/rate_alert.dart';

/// Domain-layer contract over the local-notification plugin — mirrors how
/// [ExchangeRateRepository]/[TripRepository] keep their concrete
/// infrastructure (Dio/Hive) out of anything that isn't `data/`. The
/// concrete implementation wraps `flutter_local_notifications`.
abstract class AlertNotificationService {
  /// Platform setup (channel creation, permission requests). Called once
  /// per process — both the foreground app and the Workmanager background
  /// isolate are separate processes/isolates that each need their own call
  /// before [showTrigger] will work. [requestPermissions] is `false` for
  /// the background isolate, where prompting the user is not appropriate;
  /// the foreground call is what actually asks.
  Future<void> initialize({bool requestPermissions = true});

  /// Shows the §6.5 notification for a freshly-fired trigger.
  /// [triggeredRate] is the rate that satisfied the alert's condition on
  /// this check.
  Future<void> showTrigger(RateAlert alert, double triggeredRate);
}
