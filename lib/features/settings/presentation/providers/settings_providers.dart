import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/formatting/number_formatter.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';

/// Overridden in `main()` with a real [HiveSettingsRepository] once the
/// settings Hive box has been opened (§12.1 core-provider pattern).
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  throw UnimplementedError(
    'settingsRepositoryProvider must be overridden with a HiveSettingsRepository in main()',
  );
});

/// §12.1 — exact provider shape from the spec.
final appSettingsProvider =
    NotifierProvider<AppSettingsController, AppSettings>(
      AppSettingsController.new,
    );

class AppSettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.watch(settingsRepositoryProvider).loadSettings();

  void updateHomeCurrency(String currencyCode) {
    _persist(state.copyWith(homeCurrency: currencyCode));
  }

  void updateThemeMode(AppThemeMode themeMode) {
    _persist(state.copyWith(themeMode: themeMode));
  }

  void updateNumberFormatPreference(NumberFormatPreference preference) {
    _persist(state.copyWith(numberFormatPreference: preference));
  }

  void updateAlertCheckFrequency(Duration frequency) {
    _persist(state.copyWith(alertCheckFrequency: frequency));
  }

  /// Called by the converter feature after a reorder, add, or remove —
  /// §3.2's "currency order must persist across app sessions". Distinct
  /// from [completeOnboardingWithHomeCurrency]: this never touches
  /// `homeCurrency`, only the tile list itself.
  void updateSelectedConverterCurrencies(List<String> currencyCodes) {
    _persist(state.copyWith(selectedConverterCurrencies: currencyCodes));
  }

  /// Called only by onboarding: seeds the home currency and the initial
  /// tile pair together (§3.2a) in one persisted write. Never called from
  /// the Settings page — changing home currency later must not disturb an
  /// already-customized tile list.
  void completeOnboardingWithHomeCurrency(String currencyCode) {
    _persist(
      state.copyWith(
        homeCurrency: currencyCode,
        selectedConverterCurrencies: resolveDefaultConverterTiles(currencyCode),
      ),
    );
  }

  void _persist(AppSettings updated) {
    ref.read(settingsRepositoryProvider).saveSettings(updated);
    state = updated;
  }
}

/// Gates onboarding vs. the main navigation shell.
final onboardingCompletedProvider =
    NotifierProvider<OnboardingCompletedController, bool>(
      OnboardingCompletedController.new,
    );

class OnboardingCompletedController extends Notifier<bool> {
  @override
  bool build() => ref.watch(settingsRepositoryProvider).isOnboardingCompleted();

  void complete() {
    ref.read(settingsRepositoryProvider).completeOnboarding();
    state = true;
  }
}
