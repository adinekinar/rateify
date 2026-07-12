import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import '../../domain/services/alert_background_scheduler.dart';
import '../background/alert_background_dispatcher.dart';

/// Task identifiers shared with `alert_background_dispatcher.dart` — the
/// dispatcher only needs [alertBackgroundTaskName] (to switch on it inside
/// `executeTask`), while this scheduler needs both to register/replace the
/// task.
const String alertBackgroundUniqueTaskName = 'rateify_alert_check_unique';
const String alertBackgroundTaskName = 'rateify_alert_check';

/// [AlertBackgroundScheduler] backed by `workmanager` (§6.3).
class WorkmanagerAlertBackgroundScheduler implements AlertBackgroundScheduler {
  @override
  Future<void> initialize() {
    return Workmanager().initialize(
      alertBackgroundCallbackDispatcher,
      isInDebugMode: kDebugMode,
    );
  }

  @override
  Future<void> registerPeriodicTask(Duration frequency) {
    // `ExistingWorkPolicy.replace` is exactly "cancel the previous
    // registration and register this one" — the single call Settings needs
    // whenever the user changes the alert-check frequency, with no
    // separate cancel step.
    return Workmanager().registerPeriodicTask(
      alertBackgroundUniqueTaskName,
      alertBackgroundTaskName,
      frequency: frequency,
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
  }
}
