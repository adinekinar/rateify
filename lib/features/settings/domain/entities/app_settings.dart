import 'package:collection/collection.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/formatting/number_formatter.dart';

/// §8.3 Theme Rule.
enum AppThemeMode { light, dark, system }

/// §10.11 App Settings.
class AppSettings {
  const AppSettings({
    required this.homeCurrency,
    required this.themeMode,
    required this.numberFormatPreference,
    required this.alertCheckFrequency,
    required this.selectedConverterCurrencies,
  });

  /// Bootstrap defaults used the very first time the settings box is read,
  /// before onboarding has run. [numberFormatPreference] is the one field
  /// resolved from the device locale (§8.4) rather than hardcoded — callers
  /// pass in the already-resolved value.
  factory AppSettings.initial({
    required NumberFormatPreference numberFormatPreference,
  }) {
    return AppSettings(
      homeCurrency: AppConstants.defaultHomeCurrency,
      themeMode: AppThemeMode.system,
      numberFormatPreference: numberFormatPreference,
      alertCheckFrequency: AppConstants.defaultAlertCheckFrequency,
      selectedConverterCurrencies: resolveDefaultConverterTiles(
        AppConstants.defaultHomeCurrency,
      ),
    );
  }

  final String homeCurrency;
  final AppThemeMode themeMode;
  final NumberFormatPreference numberFormatPreference;
  final Duration alertCheckFrequency;
  final List<String> selectedConverterCurrencies;

  AppSettings copyWith({
    String? homeCurrency,
    AppThemeMode? themeMode,
    NumberFormatPreference? numberFormatPreference,
    Duration? alertCheckFrequency,
    List<String>? selectedConverterCurrencies,
  }) {
    return AppSettings(
      homeCurrency: homeCurrency ?? this.homeCurrency,
      themeMode: themeMode ?? this.themeMode,
      numberFormatPreference:
          numberFormatPreference ?? this.numberFormatPreference,
      alertCheckFrequency: alertCheckFrequency ?? this.alertCheckFrequency,
      selectedConverterCurrencies:
          selectedConverterCurrencies ?? this.selectedConverterCurrencies,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    const listEquals = ListEquality<String>();
    return other is AppSettings &&
        other.homeCurrency == homeCurrency &&
        other.themeMode == themeMode &&
        other.numberFormatPreference == numberFormatPreference &&
        other.alertCheckFrequency == alertCheckFrequency &&
        listEquals.equals(
          other.selectedConverterCurrencies,
          selectedConverterCurrencies,
        );
  }

  @override
  int get hashCode => Object.hash(
    homeCurrency,
    themeMode,
    numberFormatPreference,
    alertCheckFrequency,
    const ListEquality<String>().hash(selectedConverterCurrencies),
  );
}

/// §3.2a Default Tile Selection Rule (added in review pass).
///
/// Only ever applied by the onboarding flow when it seeds/reseeds the
/// initial tile pair for a chosen home currency — later home-currency
/// changes made from the Settings page do not re-run this (§8.2 says
/// changing home currency there only affects the converter's *source*
/// currency going forward, not the user's already-customized tile list).
List<String> resolveDefaultConverterTiles(String homeCurrency) {
  final secondary = homeCurrency == 'USD'
      ? AppConstants.fallbackSecondaryCurrencyForUsd
      : AppConstants.fallbackSecondaryCurrencyDefault;
  return [homeCurrency, secondary];
}
