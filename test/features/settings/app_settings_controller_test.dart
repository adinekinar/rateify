import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rateify/core/formatting/number_formatter.dart';
import 'package:rateify/features/settings/domain/entities/app_settings.dart';
import 'package:rateify/features/settings/presentation/providers/settings_providers.dart';

import '../../test_helpers/fake_settings_repository.dart';

void main() {
  ProviderContainer buildContainer({AppSettings? initialSettings}) {
    final container = ProviderContainer(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(
          FakeSettingsRepository(initialSettings: initialSettings),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test(
    'onboarding skip (defaults to USD) seeds home currency and the USD tile pair (§3.2a)',
    () {
      final container = buildContainer();
      container.read(appSettingsProvider); // initialize

      container
          .read(appSettingsProvider.notifier)
          .completeOnboardingWithHomeCurrency('USD');

      final settings = container.read(appSettingsProvider);
      expect(settings.homeCurrency, 'USD');
      expect(settings.selectedConverterCurrencies, ['USD', 'EUR']);
    },
  );

  test('onboarding with a non-USD home currency seeds [home, USD] (§3.2a)', () {
    final container = buildContainer();
    container.read(appSettingsProvider);

    container
        .read(appSettingsProvider.notifier)
        .completeOnboardingWithHomeCurrency('IDR');

    final settings = container.read(appSettingsProvider);
    expect(settings.homeCurrency, 'IDR');
    expect(settings.selectedConverterCurrencies, ['IDR', 'USD']);
  });

  test(
    'changing home currency from the Settings page does NOT reseed the tile list',
    () {
      final initial = AppSettings.initial(
        numberFormatPreference: NumberFormatPreference.commaDecimalDot,
      ).copyWith(selectedConverterCurrencies: ['USD', 'EUR', 'JPY', 'GBP']);
      final container = buildContainer(initialSettings: initial);
      container.read(appSettingsProvider);

      container.read(appSettingsProvider.notifier).updateHomeCurrency('IDR');

      final settings = container.read(appSettingsProvider);
      expect(settings.homeCurrency, 'IDR');
      // Untouched — only onboarding re-seeds the tile pair.
      expect(settings.selectedConverterCurrencies, [
        'USD',
        'EUR',
        'JPY',
        'GBP',
      ]);
    },
  );

  test(
    'theme mode, number format, and alert frequency updates persist independently',
    () {
      final container = buildContainer();
      container.read(appSettingsProvider);
      final notifier = container.read(appSettingsProvider.notifier);

      notifier.updateThemeMode(AppThemeMode.dark);
      notifier.updateNumberFormatPreference(
        NumberFormatPreference.dotDecimalComma,
      );
      notifier.updateAlertCheckFrequency(const Duration(hours: 1));

      final settings = container.read(appSettingsProvider);
      expect(settings.themeMode, AppThemeMode.dark);
      expect(
        settings.numberFormatPreference,
        NumberFormatPreference.dotDecimalComma,
      );
      expect(settings.alertCheckFrequency, const Duration(hours: 1));
    },
  );
}
