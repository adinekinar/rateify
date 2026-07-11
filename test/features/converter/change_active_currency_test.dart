import 'package:flutter_test/flutter_test.dart';
import 'package:rateify/features/converter/domain/entities/currency_tile_state.dart';
import 'package:rateify/features/converter/domain/usecases/change_active_currency.dart';

void main() {
  test(
    'newly active tile resets rawInput to "0" and clears convertedAmount (§20.1)',
    () {
      final tiles = [
        const CurrencyTileState(
          id: 'a',
          currencyCode: 'USD',
          isActiveInput: true,
          rawInput: '1234.5',
          convertedAmount: null,
          sortOrder: 0,
        ),
        const CurrencyTileState(
          id: 'b',
          currencyCode: 'EUR',
          isActiveInput: false,
          rawInput: '0',
          convertedAmount: 987.65,
          sortOrder: 1,
        ),
      ];

      final result = const ChangeActiveCurrencyUsecase().call(
        tiles: tiles,
        newActiveTileId: 'b',
      );

      final newActive = result.firstWhere((t) => t.id == 'b');
      expect(newActive.isActiveInput, isTrue);
      expect(newActive.rawInput, '0');
      expect(newActive.convertedAmount, isNull);

      final formerlyActive = result.firstWhere((t) => t.id == 'a');
      expect(formerlyActive.isActiveInput, isFalse);
    },
  );

  test('only one tile is ever active at a time', () {
    final tiles = [
      const CurrencyTileState(
        id: 'a',
        currencyCode: 'USD',
        isActiveInput: true,
        rawInput: '5',
        convertedAmount: null,
        sortOrder: 0,
      ),
      const CurrencyTileState(
        id: 'b',
        currencyCode: 'EUR',
        isActiveInput: false,
        rawInput: '0',
        convertedAmount: null,
        sortOrder: 1,
      ),
      const CurrencyTileState(
        id: 'c',
        currencyCode: 'JPY',
        isActiveInput: false,
        rawInput: '0',
        convertedAmount: null,
        sortOrder: 2,
      ),
    ];

    final result = const ChangeActiveCurrencyUsecase().call(
      tiles: tiles,
      newActiveTileId: 'c',
    );

    expect(result.where((t) => t.isActiveInput).length, 1);
    expect(result.firstWhere((t) => t.isActiveInput).id, 'c');
  });
}
