import 'package:rateify/features/alerts/domain/services/alert_background_scheduler.dart';

/// In-memory [AlertBackgroundScheduler] fake — records calls instead of
/// touching the real `workmanager` platform channel, so tests can assert a
/// reschedule actually happened (TC-ALERT-011's automatable half; on-device
/// timing itself stays manual per the test plan).
class FakeAlertBackgroundScheduler implements AlertBackgroundScheduler {
  int initializeCallCount = 0;
  final List<Duration> registeredFrequencies = [];

  @override
  Future<void> initialize() async {
    initializeCallCount++;
  }

  @override
  Future<void> registerPeriodicTask(Duration frequency) async {
    registeredFrequencies.add(frequency);
  }
}
