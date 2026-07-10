import 'package:flutter_test/flutter_test.dart';
import 'package:rateify/features/settings/domain/entities/app_settings.dart';

void main() {
  group('resolveDefaultConverterTiles — §3.2a', () {
    test('home = USD seeds [USD, EUR]', () {
      expect(resolveDefaultConverterTiles('USD'), ['USD', 'EUR']);
    });

    test('home = IDR (non-USD) seeds [IDR, USD]', () {
      expect(resolveDefaultConverterTiles('IDR'), ['IDR', 'USD']);
    });

    test('home = EUR (non-USD) seeds [EUR, USD]', () {
      expect(resolveDefaultConverterTiles('EUR'), ['EUR', 'USD']);
    });
  });
}
