/// API endpoint constants for the Frankfurter exchange-rate provider (§9.1).
///
/// No HTTP calls are made from `core/` — these constants are consumed by
/// `features/converter/data/datasources/exchange_rate_remote_data_source.dart`
/// in a later batch.
abstract final class ApiConstants {
  static const String frankfurterBaseUrl = 'https://api.frankfurter.dev/v1';

  static const String latestRatesPath = '/latest';

  /// Historical/date-range rates are fetched via `/{date}` or `/{start}..{end}`.
  static const String historicalRatesPathPrefix = '/';

  static const Duration requestTimeout = Duration(seconds: 15);
}
