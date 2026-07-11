import 'package:flutter_test/flutter_test.dart';
import 'package:rateify/features/converter/domain/services/keypad_input_parser.dart';

void main() {
  group('appendDigit — leading zero (TC-CONV-008)', () {
    test('0 then 5 replaces, does not append (becomes 5, not 05)', () {
      expect(KeypadInputParser.appendDigit('0', '5'), '5');
    });

    test('0 then 0 stays 0', () {
      expect(KeypadInputParser.appendDigit('0', '0'), '0');
    });

    test('digit after 0. appends normally (0. then 5 -> 0.5)', () {
      expect(KeypadInputParser.appendDigit('0.', '5'), '0.5');
    });

    test('digit appends normally once input is no longer a bare leading 0', () {
      expect(KeypadInputParser.appendDigit('12', '3'), '123');
    });
  });

  group('appendDecimalSeparator (TC-CONV-009, TC-CONV-010)', () {
    test('0 then . produces 0.', () {
      expect(KeypadInputParser.appendDecimalSeparator('0'), '0.');
    });

    test('pressing decimal twice is a no-op', () {
      final once = KeypadInputParser.appendDecimalSeparator('12');
      expect(once, '12.');
      final twice = KeypadInputParser.appendDecimalSeparator(once);
      expect(twice, '12.');
    });

    test('decimal after fractional digits already exist is still a no-op', () {
      expect(KeypadInputParser.appendDecimalSeparator('12.34'), '12.34');
    });
  });

  group('appendDigit — max length (TC-CONV-011, TC-CONV-012)', () {
    test('15 integer digits is the cap; the 16th is ignored', () {
      final fifteenNines = '9' * 15;
      expect(fifteenNines.length, 15);
      final result = KeypadInputParser.appendDigit(fifteenNines, '9');
      expect(result, fifteenNines); // unchanged
      expect(result.length, 15);
    });

    test('digits under the integer cap are still accepted', () {
      final fourteenNines = '9' * 14;
      final result = KeypadInputParser.appendDigit(fourteenNines, '9');
      expect(result.length, 15);
    });

    test('6 fractional digits is the cap; the 7th is ignored', () {
      const sixFractional = '1.123456';
      final result = KeypadInputParser.appendDigit(sixFractional, '7');
      expect(result, sixFractional); // unchanged
    });

    test('fractional digits under the cap are still accepted', () {
      const fiveFractional = '1.12345';
      final result = KeypadInputParser.appendDigit(fiveFractional, '6');
      expect(result, '1.123456');
    });

    test('integer cap and fractional cap are independent', () {
      final maxIntegerWithFraction = '${'9' * 15}.123456';
      final result = KeypadInputParser.appendDigit(maxIntegerWithFraction, '7');
      expect(result, maxIntegerWithFraction); // fractional cap blocks it
    });
  });

  group('backspace (TC-CONV-013)', () {
    test('on "0" is a no-op', () {
      expect(KeypadInputParser.backspace('0'), '0');
    });

    test('on empty string does not crash and returns "0"', () {
      expect(KeypadInputParser.backspace(''), '0');
    });

    test('removes the last character for longer input', () {
      expect(KeypadInputParser.backspace('123'), '12');
    });

    test(
      'removing the second-to-last digit down to one char resets to "0"',
      () {
        expect(KeypadInputParser.backspace('5'), '0');
      },
    );

    test('removes a trailing decimal separator', () {
      expect(KeypadInputParser.backspace('12.'), '12');
    });
  });

  group('clear (TC-CONV-014)', () {
    test('always resets to "0", never empty string', () {
      expect(KeypadInputParser.clear(), '0');
      expect(KeypadInputParser.clear(), isNot(''));
    });
  });
}
