@TestOn('chrome')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:rateify/features/alerts/data/services/workmanager_alert_background_scheduler.dart';

/// §6.3/§20.9 regression check (Batch 06b): `workmanager` has no web
/// implementation — `Workmanager().initialize(...)` calls into `dart:ui`'s
/// `getCallbackHandle`, which throws `UnimplementedError` on web. This is
/// exactly the bug that took down the entire app boot on Chrome, so the
/// regression check has to actually run on web (`kIsWeb` is a compile-time
/// constant — a normal VM-run test would never see it as `true`), which is
/// why this file is pinned with `@TestOn('chrome')` and must be run via:
///
/// ```
/// flutter test --platform chrome test/features/alerts/workmanager_alert_background_scheduler_web_test.dart
/// ```
///
/// It is excluded from a plain `flutter test` run (the VM platform) by that
/// same annotation — this is intentional, not an oversight; a VM run can't
/// exercise the web code path this test exists to cover.
void main() {
  test('initialize() and registerPeriodicTask() are no-ops on web instead of '
      'throwing UnimplementedError from getCallbackHandle', () async {
    final scheduler = WorkmanagerAlertBackgroundScheduler();

    await scheduler.initialize();
    await scheduler.registerPeriodicTask(const Duration(hours: 6));

    // Reaching this line at all is the assertion — before the kIsWeb
    // guard, `initialize()` alone threw and never returned.
    expect(true, isTrue);
  });
}
