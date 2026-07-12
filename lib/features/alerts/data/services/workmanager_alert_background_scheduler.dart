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
///
/// §6.3/§20.9 web note (Batch 06b — a real app-boot crash, not a
/// hypothetical): `workmanager` has no web implementation.
/// `Workmanager().initialize(...)` calls into `dart:ui`'s
/// `getCallbackHandle` internally, which throws `UnimplementedError` on
/// web. Every method here is guarded with `kIsWeb` and skips the plugin
/// entirely on web rather than calling into it — the app relies solely on
/// the foreground check-on-open path there (§6.3's own rule already
/// requires that path to work on every platform, so there is no
/// web-specific substitute to build).
class WorkmanagerAlertBackgroundScheduler implements AlertBackgroundScheduler {
  @override
  Future<void> initialize() async {
    if (kIsWeb) return;
    await Workmanager().initialize(
      alertBackgroundCallbackDispatcher,
      isInDebugMode: kDebugMode,
    );
  }

  @override
  Future<void> registerPeriodicTask(Duration frequency) async {
    if (kIsWeb) return;
    // `ExistingWorkPolicy.replace` is exactly "cancel the previous
    // registration and register this one" — the single call Settings needs
    // whenever the user changes the alert-check frequency, with no
    // separate cancel step.
    await Workmanager().registerPeriodicTask(
      alertBackgroundUniqueTaskName,
      alertBackgroundTaskName,
      frequency: frequency,
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
  }
}
