import 'package:flutter_test/flutter_test.dart';
import 'package:rateify/core/formatting/number_formatter.dart';

void main() {
  group('formatNumber — commaDecimalDot', () {
    test('formats a large integer with comma grouping and dot decimal', () {
      expect(
        formatNumber(
          1500000,
          preference: NumberFormatPreference.commaDecimalDot,
        ),
        '1,500,000.00',
      );
    });

    test('formats a value under 1000 without a grouping separator', () {
      expect(
        formatNumber(42.5, preference: NumberFormatPreference.commaDecimalDot),
        '42.50',
      );
    });

    test('rounds to the requested decimal digits', () {
      expect(
        formatNumber(
          123.456789,
          preference: NumberFormatPreference.commaDecimalDot,
        ),
        '123.46',
      );
    });

    test('formats zero', () {
      expect(
        formatNumber(0, preference: NumberFormatPreference.commaDecimalDot),
        '0.00',
      );
    });

    test('formats negative values', () {
      expect(
        formatNumber(
          -1500.5,
          preference: NumberFormatPreference.commaDecimalDot,
        ),
        '-1,500.50',
      );
    });

    test('supports zero decimal digits', () {
      expect(
        formatNumber(
          1500000,
          preference: NumberFormatPreference.commaDecimalDot,
          decimalDigits: 0,
        ),
        '1,500,000',
      );
    });

    test('trims trailing zeros when requested', () {
      expect(
        formatNumber(
          3,
          preference: NumberFormatPreference.commaDecimalDot,
          trimTrailingZeros: true,
        ),
        '3',
      );
      expect(
        formatNumber(
          0.5,
          preference: NumberFormatPreference.commaDecimalDot,
          trimTrailingZeros: true,
        ),
        '0.5',
      );
    });
  });

  group('formatNumber — dotDecimalComma', () {
    test('formats a large integer with dot grouping and comma decimal', () {
      expect(
        formatNumber(
          1500000,
          preference: NumberFormatPreference.dotDecimalComma,
        ),
        '1.500.000,00',
      );
    });

    test('formats a value under 1000 without a grouping separator', () {
      expect(
        formatNumber(42.5, preference: NumberFormatPreference.dotDecimalComma),
        '42,50',
      );
    });

    test('formats negative values', () {
      expect(
        formatNumber(
          -1500.5,
          preference: NumberFormatPreference.dotDecimalComma,
        ),
        '-1.500,50',
      );
    });
  });

  group('NumberFormatPreference separators', () {
    test('commaDecimalDot exposes correct separators', () {
      expect(NumberFormatPreference.commaDecimalDot.thousandsSeparator, ',');
      expect(NumberFormatPreference.commaDecimalDot.decimalSeparator, '.');
    });

    test('dotDecimalComma exposes correct separators', () {
      expect(NumberFormatPreference.dotDecimalComma.thousandsSeparator, '.');
      expect(NumberFormatPreference.dotDecimalComma.decimalSeparator, ',');
    });
  });
}
