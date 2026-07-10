import '../../../../core/formatting/number_formatter.dart';
import '../../domain/entities/app_settings.dart';

/// JSON (de)serialization for [AppSettings], kept out of the domain entity
/// on purpose (clean separation between the pure domain model and its data
/// representation).
extension AppSettingsJsonMapper on AppSettings {
  Map<String, dynamic> toJson() => {
    'homeCurrency': homeCurrency,
    'themeMode': themeMode.name,
    'numberFormatPreference': numberFormatPreference.name,
    'alertCheckFrequencyMinutes': alertCheckFrequency.inMinutes,
    'selectedConverterCurrencies': selectedConverterCurrencies,
  };
}

AppSettings appSettingsFromJson(Map<String, dynamic> json) => AppSettings(
  homeCurrency: json['homeCurrency'] as String,
  themeMode: AppThemeMode.values.byName(json['themeMode'] as String),
  numberFormatPreference: NumberFormatPreference.values.byName(
    json['numberFormatPreference'] as String,
  ),
  alertCheckFrequency: Duration(
    minutes: json['alertCheckFrequencyMinutes'] as int,
  ),
  selectedConverterCurrencies: List<String>.from(
    json['selectedConverterCurrencies'] as List,
  ),
);
