/// Pure raw-input parsing for the custom keypad (§3.3, §3.3a). No widget,
/// no Riverpod — every rule here is independently unit-testable and the
/// keypad widget must call into this rather than parsing anything itself
/// (§16.2).
///
/// All methods operate on and return the tile's `rawInput` string; the
/// caller (converter controller) is responsible for persisting the result
/// back onto the active tile (§20.1 — only the active tile ever holds
/// input state).
abstract final class KeypadInputParser {
  /// §3.3a max length: raw input is capped at 15 integer digits and 6
  /// fractional digits.
  static const int maxIntegerDigits = 15;
  static const int maxFractionalDigits = 6;

  /// Appends [digit] (a single character `0`-`9`) to [currentRaw].
  ///
  /// - A single leading `0` is replaced by the next digit (`0` then `5` →
  ///   `5`), not appended (`05`).
  /// - Digits beyond the integer/fractional digit cap are ignored (no-op),
  ///   never truncated destructively.
  static String appendDigit(String currentRaw, String digit) {
    assert(
      digit.length == 1 && '0123456789'.contains(digit),
      'digit must be a single 0-9 character',
    );

    if (currentRaw == '0') {
      return digit;
    }

    final dotIndex = currentRaw.indexOf('.');
    if (dotIndex == -1) {
      if (currentRaw.length >= maxIntegerDigits) return currentRaw;
      return currentRaw + digit;
    }

    final fractionalDigitCount = currentRaw.length - dotIndex - 1;
    if (fractionalDigitCount >= maxFractionalDigits) return currentRaw;
    return currentRaw + digit;
  }

  /// Appends the decimal separator.
  ///
  /// - A no-op if [currentRaw] already contains one (does not duplicate,
  ///   does not error).
  /// - `0` then `.` produces `0.`, not a replaced digit — the one
  ///   exception to the leading-zero-replacement rule.
  static String appendDecimalSeparator(String currentRaw) {
    if (currentRaw.contains('.')) return currentRaw;
    return '$currentRaw.';
  }

  /// Removes the last character. A no-op on empty or single-character input
  /// (including the `"0"` placeholder) — always leaves `"0"`, never a
  /// negative-length or empty string.
  static String backspace(String currentRaw) {
    if (currentRaw.length <= 1) return '0';
    return currentRaw.substring(0, currentRaw.length - 1);
  }

  /// Always resets to `"0"`, never `""`, so the tile always has a valid
  /// renderable value.
  static String clear() => '0';
}
