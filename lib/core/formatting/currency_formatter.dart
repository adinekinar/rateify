import 'number_formatter.dart';

/// Formats a currency amount as `"<CODE> <formatted number>"`, e.g. `USD 1,500.00`.
///
/// Display is capped at [decimalDigits] (max 2 per §3.4) — callers must
/// always pass the full-precision raw amount, never a previously formatted
/// string (§20.2).
String formatCurrencyAmount({
  required double amount,
  required String currencyCode,
  required NumberFormatPreference numberFormatPreference,
  int decimalDigits = 2,
}) {
  final formattedNumber = formatNumber(
    amount,
    preference: numberFormatPreference,
    decimalDigits: decimalDigits,
  );
  return '$currencyCode $formattedNumber';
}
