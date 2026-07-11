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

  /// §9 API and Data Source (design decision, added in Batch 02 — the spec
  /// doesn't pin the cached rate snapshot to a specific base).
  ///
  /// The Hive-cached [RateSnapshot] is always anchored to this single fixed
  /// base currency, fetched in one call covering every currency Frankfurter
  /// supports. This is deliberately independent of [defaultHomeCurrency] /
  /// the user's changeable home-currency setting: re-anchoring the cache
  /// every time the user (or the active converter tile) changes currency
  /// would mean constant refetching and would defeat §9.3's staleness rule.
  /// Any tile-to-tile conversion is derived from this one snapshot via
  /// cross-rate math (rate_A→B = rate_USD→B / rate_USD→A) in a later batch.
  static const String rateSnapshotAnchorCurrency = 'USD';

  /// §3.2a Default Tile Selection Rule
  static const String fallbackSecondaryCurrencyForUsd = 'EUR';
  static const String fallbackSecondaryCurrencyDefault = 'USD';

  /// §6.3 Background Check Rule
  static const Duration defaultAlertCheckFrequency = Duration(hours: 6);
}
