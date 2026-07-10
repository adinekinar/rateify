/// A single bundled currency's display info.
class CurrencyInfo {
  const CurrencyInfo({required this.code, required this.displayName});

  /// Uppercase 3-letter ISO 4217 code (§10.2), e.g. `USD`.
  final String code;

  final String displayName;
}

/// Curated, bundled list of common ISO 4217 currencies for the onboarding
/// and settings currency pickers.
///
/// This is a static reference list, not fetched from any API — the
/// exchange-rate data source (Batch 02) may later reconcile against it.
abstract final class CurrencyReference {
  static const List<CurrencyInfo> all = [
    CurrencyInfo(code: 'USD', displayName: 'US Dollar'),
    CurrencyInfo(code: 'EUR', displayName: 'Euro'),
    CurrencyInfo(code: 'JPY', displayName: 'Japanese Yen'),
    CurrencyInfo(code: 'GBP', displayName: 'British Pound'),
    CurrencyInfo(code: 'AUD', displayName: 'Australian Dollar'),
    CurrencyInfo(code: 'CAD', displayName: 'Canadian Dollar'),
    CurrencyInfo(code: 'CHF', displayName: 'Swiss Franc'),
    CurrencyInfo(code: 'CNY', displayName: 'Chinese Yuan'),
    CurrencyInfo(code: 'HKD', displayName: 'Hong Kong Dollar'),
    CurrencyInfo(code: 'NZD', displayName: 'New Zealand Dollar'),
    CurrencyInfo(code: 'SEK', displayName: 'Swedish Krona'),
    CurrencyInfo(code: 'KRW', displayName: 'South Korean Won'),
    CurrencyInfo(code: 'SGD', displayName: 'Singapore Dollar'),
    CurrencyInfo(code: 'NOK', displayName: 'Norwegian Krone'),
    CurrencyInfo(code: 'MXN', displayName: 'Mexican Peso'),
    CurrencyInfo(code: 'INR', displayName: 'Indian Rupee'),
    CurrencyInfo(code: 'RUB', displayName: 'Russian Ruble'),
    CurrencyInfo(code: 'ZAR', displayName: 'South African Rand'),
    CurrencyInfo(code: 'TRY', displayName: 'Turkish Lira'),
    CurrencyInfo(code: 'BRL', displayName: 'Brazilian Real'),
    CurrencyInfo(code: 'TWD', displayName: 'New Taiwan Dollar'),
    CurrencyInfo(code: 'DKK', displayName: 'Danish Krone'),
    CurrencyInfo(code: 'PLN', displayName: 'Polish Zloty'),
    CurrencyInfo(code: 'THB', displayName: 'Thai Baht'),
    CurrencyInfo(code: 'IDR', displayName: 'Indonesian Rupiah'),
    CurrencyInfo(code: 'HUF', displayName: 'Hungarian Forint'),
    CurrencyInfo(code: 'CZK', displayName: 'Czech Koruna'),
    CurrencyInfo(code: 'ILS', displayName: 'Israeli New Shekel'),
    CurrencyInfo(code: 'CLP', displayName: 'Chilean Peso'),
    CurrencyInfo(code: 'PHP', displayName: 'Philippine Peso'),
    CurrencyInfo(code: 'AED', displayName: 'UAE Dirham'),
    CurrencyInfo(code: 'SAR', displayName: 'Saudi Riyal'),
    CurrencyInfo(code: 'MYR', displayName: 'Malaysian Ringgit'),
    CurrencyInfo(code: 'RON', displayName: 'Romanian Leu'),
    CurrencyInfo(code: 'VND', displayName: 'Vietnamese Dong'),
    CurrencyInfo(code: 'PKR', displayName: 'Pakistani Rupee'),
    CurrencyInfo(code: 'BDT', displayName: 'Bangladeshi Taka'),
    CurrencyInfo(code: 'NGN', displayName: 'Nigerian Naira'),
    CurrencyInfo(code: 'EGP', displayName: 'Egyptian Pound'),
    CurrencyInfo(code: 'KES', displayName: 'Kenyan Shilling'),
    CurrencyInfo(code: 'COP', displayName: 'Colombian Peso'),
  ];
}
