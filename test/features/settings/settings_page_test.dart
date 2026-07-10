import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rateify/core/formatting/number_formatter.dart';
import 'package:rateify/features/settings/domain/entities/app_settings.dart';
import 'package:rateify/features/settings/presentation/pages/settings_page.dart';
import 'package:rateify/features/settings/presentation/providers/settings_providers.dart';

import '../../test_helpers/fake_settings_repository.dart';

void main() {
  testWidgets(
    'changing theme mode in the UI updates and persists the setting',
    (tester) async {
      final repository = FakeSettingsRepository();
      final container = ProviderContainer(
        overrides: [settingsRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: SettingsPage()),
        ),
      );

      expect(
        container.read(appSettingsProvider).themeMode,
        AppThemeMode.system,
      );

      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      expect(container.read(appSettingsProvider).themeMode, AppThemeMode.dark);
      // Confirms it was actually persisted through the repository, not just
      // held in provider state.
      expect(repository.loadSettings().themeMode, AppThemeMode.dark);
    },
  );

  testWidgets(
    'changing home currency via the picker persists without touching tile list',
    (tester) async {
      final initial = AppSettings.initial(
        numberFormatPreference: NumberFormatPreference.commaDecimalDot,
      );
      final repository = FakeSettingsRepository(initialSettings: initial);
      final container = ProviderContainer(
        overrides: [settingsRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: SettingsPage()),
        ),
      );

      await tester.tap(find.text('USD — US Dollar'));
      await tester.pumpAndSettle();
      // EUR is near the top of the (lazily built) list, so it's guaranteed
      // to already be on screen without needing to scroll to find it.
      await tester.tap(find.widgetWithText(ListTile, 'EUR'));
      await tester.pumpAndSettle();

      final settings = container.read(appSettingsProvider);
      expect(settings.homeCurrency, 'EUR');
      expect(settings.selectedConverterCurrencies, ['USD', 'EUR']);
    },
  );
}
