import 'package:flutter_test/flutter_test.dart';
import 'package:rateify/core/formatting/currency_formatter.dart';
import 'package:rateify/core/formatting/number_formatter.dart';

void main() {
  test('formats a currency amount with the currency code prefixed', () {
    expect(
      formatCurrencyAmount(
        amount: 1500000,
        currencyCode: 'IDR',
        numberFormatPreference: NumberFormatPreference.commaDecimalDot,
      ),
      'IDR 1,500,000.00',
    );
  });

  test('respects dotDecimalComma preference', () {
    expect(
      formatCurrencyAmount(
        amount: 1500.5,
        currencyCode: 'EUR',
        numberFormatPreference: NumberFormatPreference.dotDecimalComma,
      ),
      'EUR 1.500,50',
    );
  });
}
