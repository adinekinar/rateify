import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rateify/app.dart';
import 'package:rateify/features/settings/presentation/providers/settings_providers.dart';

import 'test_helpers/fake_settings_repository.dart';

void main() {
  Widget buildApp({required bool onboardingCompleted}) {
    return ProviderScope(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(
          FakeSettingsRepository(onboardingCompleted: onboardingCompleted),
        ),
      ],
      child: const RateifyApp(),
    );
  }

  testWidgets('shows onboarding when it has not been completed yet', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp(onboardingCompleted: false));

    expect(find.text('Welcome to Rateify'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets(
    'RateifyApp shows all 4 bottom nav tabs once onboarding is complete',
    (tester) async {
      await tester.pumpWidget(buildApp(onboardingCompleted: true));

      expect(find.text('Converter'), findsWidgets);
      expect(find.text('Trip'), findsWidgets);
      expect(find.text('Alerts'), findsWidgets);
      expect(find.text('Settings'), findsWidgets);
    },
  );

  testWidgets('tapping a nav destination switches the selected index', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp(onboardingCompleted: true));

    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      0,
    );

    await tester.tap(find.widgetWithText(NavigationDestination, 'Settings'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      3,
    );
  });
}
