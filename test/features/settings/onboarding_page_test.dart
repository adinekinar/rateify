import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rateify/features/settings/presentation/pages/onboarding_page.dart';
import 'package:rateify/features/settings/presentation/providers/settings_providers.dart';

import '../../test_helpers/fake_settings_repository.dart';

void main() {
  testWidgets(
    'skipping onboarding defaults home currency to USD and seeds [USD, EUR]',
    (tester) async {
      final repository = FakeSettingsRepository(onboardingCompleted: false);
      final container = ProviderContainer(
        overrides: [settingsRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: OnboardingPage()),
        ),
      );

      await tester.tap(find.text('Skip (use USD)'));
      await tester.pumpAndSettle();

      final settings = container.read(appSettingsProvider);
      expect(settings.homeCurrency, 'USD');
      expect(settings.selectedConverterCurrencies, ['USD', 'EUR']);
      expect(container.read(onboardingCompletedProvider), isTrue);
    },
  );

  testWidgets(
    'picking a currency then continuing seeds that currency plus its fallback pair',
    (tester) async {
      final repository = FakeSettingsRepository(onboardingCompleted: false);
      final container = ProviderContainer(
        overrides: [settingsRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: OnboardingPage()),
        ),
      );

      await tester.tap(find.textContaining('USD —'));
      await tester.pumpAndSettle();
      // EUR is near the top of the (lazily built) list, so it's guaranteed
      // to already be on screen without needing to scroll to find it.
      await tester.tap(find.widgetWithText(ListTile, 'EUR'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      final settings = container.read(appSettingsProvider);
      expect(settings.homeCurrency, 'EUR');
      expect(settings.selectedConverterCurrencies, ['EUR', 'USD']);
    },
  );
}
