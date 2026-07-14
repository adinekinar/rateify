import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:rateify/features/alerts/data/repositories/alert_repository_impl.dart';
import 'package:rateify/features/alerts/domain/entities/alert_trigger_history.dart';
import 'package:rateify/features/alerts/domain/entities/rate_alert.dart';

void main() {
  late Directory tempDir;
  late Box<dynamic> alertBox;
  late Box<dynamic> historyBox;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('rateify_alert_test_');
    Hive.init(tempDir.path);
    alertBox = await Hive.openBox<dynamic>('alert_test_box');
    historyBox = await Hive.openBox<dynamic>('alert_history_test_box');
  });

  tearDown(() async {
    await alertBox.deleteFromDisk();
    await historyBox.deleteFromDisk();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test(
    'createAlert persists base/quote/target/direction correctly (TC-ALERT-001)',
    () {
      final repository = HiveAlertRepository(alertBox, historyBox);

      repository.createAlert(
        baseCurrency: 'USD',
        quoteCurrency: 'JPY',
        targetRate: 160,
        direction: AlertDirection.aboveTarget,
      );

      final all = repository.getAllAlerts();
      expect(all, hasLength(1));
      final created = all.single;
      expect(created.baseCurrency, 'USD');
      expect(created.quoteCurrency, 'JPY');
      expect(created.targetRate, 160);
      expect(created.direction, AlertDirection.aboveTarget);
      expect(created.isActive, isTrue);
      expect(created.isArmed, isTrue);

      final reloaded = HiveAlertRepository(
        alertBox,
        historyBox,
      ).getAllAlerts().single;
      expect(reloaded.baseCurrency, 'USD');
      expect(reloaded.targetRate, 160);
    },
  );

  test('editAlert updates fields and re-arms (TC-ALERT-001)', () {
    final repository = HiveAlertRepository(alertBox, historyBox);
    repository.createAlert(
      baseCurrency: 'USD',
      quoteCurrency: 'JPY',
      targetRate: 160,
      direction: AlertDirection.aboveTarget,
    );
    final original = repository.getAllAlerts().single;
    // Simulate a fired-and-disarmed alert before the edit.
    repository.saveCheckedAlert(original.copyWith(isArmed: false));

    repository.editAlert(
      id: original.id,
      baseCurrency: 'USD',
      quoteCurrency: 'IDR',
      targetRate: 16000,
      direction: AlertDirection.belowTarget,
    );

    final edited = repository.getAllAlerts().single;
    expect(edited.quoteCurrency, 'IDR');
    expect(edited.targetRate, 16000);
    expect(edited.direction, AlertDirection.belowTarget);
    expect(edited.isArmed, isTrue);
  });

  test(
    'deleteAlert removes it, cascading to its trigger history (TC-ALERT-001)',
    () {
      final repository = HiveAlertRepository(alertBox, historyBox);
      repository.createAlert(
        baseCurrency: 'USD',
        quoteCurrency: 'JPY',
        targetRate: 160,
        direction: AlertDirection.aboveTarget,
      );
      final alert = repository.getAllAlerts().single;
      repository.addTriggerHistory(
        AlertTriggerHistory(
          id: 'h1',
          alertId: alert.id,
          triggeredRate: 161,
          triggeredAt: DateTime(2026, 7),
        ),
      );
      expect(repository.getTriggerHistoryForAlert(alert.id), hasLength(1));

      repository.deleteAlert(alert.id);

      expect(repository.getAllAlerts(), isEmpty);
      expect(repository.getTriggerHistoryForAlert(alert.id), isEmpty);
    },
  );

  test(
    'activateAlert/deactivateAlert toggles isActive without disturbing other fields (TC-ALERT-002)',
    () {
      final repository = HiveAlertRepository(alertBox, historyBox);
      repository.createAlert(
        baseCurrency: 'USD',
        quoteCurrency: 'JPY',
        targetRate: 160,
        direction: AlertDirection.aboveTarget,
      );
      final alert = repository.getAllAlerts().single;
      expect(alert.isActive, isTrue);

      repository.deactivateAlert(alert.id);
      expect(repository.getAllAlerts().single.isActive, isFalse);

      repository.activateAlert(alert.id);
      expect(repository.getAllAlerts().single.isActive, isTrue);
    },
  );

  test(
    'getTriggerHistoryForAlert returns only that alert\'s rows, most recent first',
    () {
      final repository = HiveAlertRepository(alertBox, historyBox);
      repository.createAlert(
        baseCurrency: 'USD',
        quoteCurrency: 'JPY',
        targetRate: 160,
        direction: AlertDirection.aboveTarget,
      );
      repository.createAlert(
        baseCurrency: 'USD',
        quoteCurrency: 'IDR',
        targetRate: 16000,
        direction: AlertDirection.aboveTarget,
      );
      final alerts = repository.getAllAlerts();
      final jpyAlert = alerts.firstWhere((a) => a.quoteCurrency == 'JPY');
      final idrAlert = alerts.firstWhere((a) => a.quoteCurrency == 'IDR');

      repository.addTriggerHistory(
        AlertTriggerHistory(
          id: 'h1',
          alertId: jpyAlert.id,
          triggeredRate: 161,
          triggeredAt: DateTime(2026, 7),
        ),
      );
      repository.addTriggerHistory(
        AlertTriggerHistory(
          id: 'h2',
          alertId: jpyAlert.id,
          triggeredRate: 162,
          triggeredAt: DateTime(2026, 7, 3),
        ),
      );
      repository.addTriggerHistory(
        AlertTriggerHistory(
          id: 'h3',
          alertId: idrAlert.id,
          triggeredRate: 16001,
          triggeredAt: DateTime(2026, 7, 2),
        ),
      );

      final jpyHistory = repository.getTriggerHistoryForAlert(jpyAlert.id);
      expect(jpyHistory, hasLength(2));
      expect(jpyHistory.first.id, 'h2'); // most recent first
      expect(jpyHistory.last.id, 'h1');
    },
  );
}
