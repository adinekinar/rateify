import 'package:intl/intl.dart';

/// Supported large-number display formats (§8.4, §10.1).
///
/// There is no `auto` value — device-locale detection is a one-time
/// resolution performed during onboarding (see the settings feature in a
/// later batch), not a live formatting mode.
enum NumberFormatPreference {
  /// `1,500,000.00`
  commaDecimalDot,

  /// `1.500.000,00`
  dotDecimalComma;

  String get thousandsSeparator => switch (this) {
    NumberFormatPreference.commaDecimalDot => ',',
    NumberFormatPreference.dotDecimalComma => '.',
  };

  String get decimalSeparator => switch (this) {
    NumberFormatPreference.commaDecimalDot => '.',
    NumberFormatPreference.dotDecimalComma => ',',
  };
}

/// Formats [value] as a grouped, fixed-decimal string per [preference].
///
/// Internal calculation precision is untouched by this function — it only
/// affects the returned display string (§20.2: never parse this back into
/// a number for further calculation).
String formatNumber(
  double value, {
  required NumberFormatPreference preference,
  int decimalDigits = 2,
  bool trimTrailingZeros = false,
}) {
  assert(decimalDigits >= 0, 'decimalDigits must not be negative');

  final isNegative = value.isNegative && value != 0;
  final fixed = value.abs().toStringAsFixed(decimalDigits);
  final segments = fixed.split('.');
  final integerPart = segments[0];
  var fractionalPart = segments.length > 1 ? segments[1] : '';

  if (trimTrailingZeros && fractionalPart.isNotEmpty) {
    fractionalPart = fractionalPart.replaceFirst(RegExp(r'0+$'), '');
  }

  final groupedInteger = _groupThousands(
    integerPart,
    preference.thousandsSeparator,
  );

  final buffer = StringBuffer();
  if (isNegative) buffer.write('-');
  buffer.write(groupedInteger);
  if (fractionalPart.isNotEmpty) {
    buffer
      ..write(preference.decimalSeparator)
      ..write(fractionalPart);
  }
  return buffer.toString();
}

/// One-time device-locale resolution for the initial `NumberFormatPreference`
/// (§8.4, added in review pass). Only ever called on first launch — after
/// that, the persisted value (default or user-changed) always wins.
///
/// Uses `intl`'s own CLDR-backed [NumberFormat] to render a test number and
/// inspects which separator appears last (the decimal separator), rather
/// than hand-maintaining a country/locale list. Falls back to
/// [NumberFormatPreference.commaDecimalDot] per §8.4's stated fallback if
/// neither separator is present for the given locale.
NumberFormatPreference resolveNumberFormatPreferenceFromLocale(
  String localeName,
) {
  final formatted = NumberFormat.decimalPattern(localeName).format(1000.5);
  final lastComma = formatted.lastIndexOf(',');
  final lastDot = formatted.lastIndexOf('.');
  if (lastComma > lastDot) {
    return NumberFormatPreference.dotDecimalComma;
  }
  return NumberFormatPreference.commaDecimalDot;
}

String _groupThousands(String digits, String separator) {
  final reversedDigits = digits.split('').reversed;
  final groupedReversed = StringBuffer();
  var count = 0;
  for (final digit in reversedDigits) {
    if (count != 0 && count % 3 == 0) {
      groupedReversed.write(separator);
    }
    groupedReversed.write(digit);
    count++;
  }
  return groupedReversed.toString().split('').reversed.join();
}
