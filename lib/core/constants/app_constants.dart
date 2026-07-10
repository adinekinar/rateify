/// App-wide constants that are not specific to any single feature.
///
/// Values sourced from the Rateify requirement spec (see docs/rateify_requirement_spec_v2.md).
abstract final class AppConstants {
  static const String appName = 'Rateify';

  /// §3.2 Currency Tile Rules
  static const int defaultConverterTileCount = 2;
  static const int minConverterTileCount = 2;
  static const int maxConverterTileCount = 8;

  /// §8.2 Home Currency Rule
  static const String defaultHomeCurrency = 'USD';

  /// §3.2a Default Tile Selection Rule
  static const String fallbackSecondaryCurrencyForUsd = 'EUR';
  static const String fallbackSecondaryCurrencyDefault = 'USD';

  /// §6.3 Background Check Rule
  static const Duration defaultAlertCheckFrequency = Duration(hours: 6);
}
