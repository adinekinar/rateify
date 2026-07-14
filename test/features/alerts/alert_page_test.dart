import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rateify/features/alerts/domain/entities/alert_trigger_history.dart';
import 'package:rateify/features/alerts/domain/entities/rate_alert.dart';
import 'package:rateify/features/alerts/presentation/pages/alert_page.dart';
import 'package:rateify/features/alerts/presentation/providers/alert_providers.dart';

import '../../test_helpers/fake_alert_repository.dart';

void main() {
  RateAlert alert({
    String id = 'alert-1',
    String baseCurrency = 'USD',
    String quoteCurrency = 'JPY',
    double targetRate = 160,
    AlertDirection direction = AlertDirection.aboveTarget,
    bool isActive = true,
    bool isArmed = true,
    DateTime? lastTriggeredAt,
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
      lastTriggeredAt: lastTriggeredAt,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<ProviderContainer> pumpAlertPage(
    WidgetTester tester, {
    List<RateAlert>? initialAlerts,
    List<AlertTriggerHistory>? initialHistory,
  }) async {
    final container = ProviderContainer(
      overrides: [
        alertRepositoryProvider.overrideWithValue(
          FakeAlertRepository(
            initialAlerts: initialAlerts,
            initialHistory: initialHistory,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: AlertPage()),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  group('§6.6 empty state', () {
    testWidgets('TC-ALERT-012: no alerts exist -> the empty state is shown', (
      tester,
    ) async {
      await pumpAlertPage(tester, initialAlerts: []);

      expect(find.text('Belum ada rate alert.'), findsOneWidget);
      expect(
        find.text(
          'Tambahkan alert untuk diberi tahu saat rate mencapai target.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('an alert exists -> no empty state text, alert is listed', (
      tester,
    ) async {
      await pumpAlertPage(tester, initialAlerts: [alert()]);

      expect(find.text('Belum ada rate alert.'), findsNothing);
      expect(find.text('USD/JPY'), findsOneWidget);
    });
  });

  testWidgets(
    'creating an alert via the form sheet adds it to the list (TC-ALERT-001)',
    (tester) async {
      await pumpAlertPage(tester, initialAlerts: []);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Target rate (USD/EUR)'),
        '1.10',
      );
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(find.text('Belum ada rate alert.'), findsNothing);
      expect(find.text('USD/EUR'), findsOneWidget);
      expect(find.text('Notify above 1.10'), findsOneWidget);
    },
  );

  testWidgets(
    'TC-ALERT-002: toggling the switch activates/deactivates the alert',
    (tester) async {
      final container = await pumpAlertPage(tester, initialAlerts: [alert()]);

      expect(find.text('Armed'), findsOneWidget);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(
        container.read(alertListControllerProvider).single.isActive,
        isFalse,
      );
      expect(find.text('Inactive'), findsOneWidget);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(
        container.read(alertListControllerProvider).single.isActive,
        isTrue,
      );
    },
  );

  testWidgets('a disarmed alert shows the "Waiting to reset" status hint', (
    tester,
  ) async {
    await pumpAlertPage(tester, initialAlerts: [alert(isArmed: false)]);

    expect(find.text('Waiting to reset'), findsOneWidget);
    expect(find.text('Armed'), findsNothing);
  });

  testWidgets(
    'TC-ALERT-014 (Widget): deleting an alert requires confirmation before it disappears',
    (tester) async {
      await pumpAlertPage(tester, initialAlerts: [alert()]);

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.text('Delete alert?'), findsOneWidget);
      expect(find.text('USD/JPY'), findsWidgets);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('USD/JPY'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Belum ada rate alert.'), findsOneWidget);
    },
  );

  testWidgets(
    'viewing trigger history shows past triggers, most recent first',
    (tester) async {
      await pumpAlertPage(
        tester,
        initialAlerts: [alert()],
        initialHistory: [
          AlertTriggerHistory(
            id: 'h1',
            alertId: 'alert-1',
            triggeredRate: 160.5,
            triggeredAt: DateTime(2026, 7),
          ),
          AlertTriggerHistory(
            id: 'h2',
            alertId: 'alert-1',
            triggeredRate: 161.2,
            triggeredAt: DateTime(2026, 7, 3),
          ),
        ],
      );

      await tester.tap(find.byIcon(Icons.history));
      await tester.pumpAndSettle();

      expect(find.text('USD/JPY trigger history'), findsOneWidget);
      expect(find.textContaining('161.20'), findsOneWidget);
      expect(find.textContaining('160.50'), findsOneWidget);
    },
  );

  testWidgets('an alert with no trigger history shows "No triggers yet."', (
    tester,
  ) async {
    await pumpAlertPage(tester, initialAlerts: [alert()]);

    await tester.tap(find.byIcon(Icons.history));
    await tester.pumpAndSettle();

    expect(find.text('No triggers yet.'), findsOneWidget);
  });
}
