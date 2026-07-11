import 'package:flutter_test/flutter_test.dart';
import 'package:rateify/features/converter/domain/entities/currency_tile_state.dart';
import 'package:rateify/features/converter/domain/usecases/reorder_currency_tiles.dart';

void main() {
  List<CurrencyTileState> tilesOf(List<String> codes, {int activeIndex = 0}) {
    return [
      for (var i = 0; i < codes.length; i++)
        CurrencyTileState(
          id: 'id-$i',
          currencyCode: codes[i],
          isActiveInput: i == activeIndex,
          rawInput: '0',
          convertedAmount: null,
          sortOrder: i,
        ),
    ];
  }

  group('reorder', () {
    test(
      'moves a tile and reassigns sortOrder without touching active/rawInput',
      () {
        final tiles = tilesOf(['USD', 'EUR', 'JPY']);
        final result = ReorderCurrencyTilesUsecase.reorder(tiles, 0, 2);

        expect(result.map((t) => t.currencyCode).toList(), [
          'EUR',
          'JPY',
          'USD',
        ]);
        expect(result.map((t) => t.sortOrder).toList(), [0, 1, 2]);
        // Active tile identity (USD, originally index 0) is preserved.
        final usdTile = result.firstWhere((t) => t.currencyCode == 'USD');
        expect(usdTile.isActiveInput, isTrue);
        expect(usdTile.rawInput, '0');
      },
    );
  });

  group('addTile (TC-CONV-004, TC-CONV-006)', () {
    test('adding while under the max succeeds', () {
      final tiles = tilesOf(['USD', 'EUR']);
      const newTile = CurrencyTileState(
        id: 'new',
        currencyCode: 'JPY',
        isActiveInput: false,
        rawInput: '0',
        convertedAmount: null,
        sortOrder: 0,
      );
      final result = ReorderCurrencyTilesUsecase.addTile(
        tiles: tiles,
        newTile: newTile,
      );

      expect(result.isSuccess, isTrue);
      expect(result.tiles!.length, 3);
      expect(result.tiles!.last.sortOrder, 2);
    });

    test(
      'adding at 8 tiles is rejected with maxTilesReached (TC-CONV-004)',
      () {
        final tiles = tilesOf([
          'USD',
          'EUR',
          'JPY',
          'GBP',
          'AUD',
          'CAD',
          'CHF',
          'CNY',
        ]);
        expect(tiles.length, 8);
        const newTile = CurrencyTileState(
          id: 'new',
          currencyCode: 'HKD',
          isActiveInput: false,
          rawInput: '0',
          convertedAmount: null,
          sortOrder: 0,
        );
        final result = ReorderCurrencyTilesUsecase.addTile(
          tiles: tiles,
          newTile: newTile,
        );

        expect(result.isSuccess, isFalse);
        expect(result.failure, TileListMutationFailure.maxTilesReached);
        expect(result.tiles, isNull);
      },
    );

    test(
      'adding a currency already present is rejected with duplicateCurrency (TC-CONV-006)',
      () {
        final tiles = tilesOf(['USD', 'EUR']);
        const duplicateTile = CurrencyTileState(
          id: 'new',
          currencyCode: 'EUR',
          isActiveInput: false,
          rawInput: '0',
          convertedAmount: null,
          sortOrder: 0,
        );
        final result = ReorderCurrencyTilesUsecase.addTile(
          tiles: tiles,
          newTile: duplicateTile,
        );

        expect(result.isSuccess, isFalse);
        expect(result.failure, TileListMutationFailure.duplicateCurrency);
      },
    );
  });

  group('removeTile (TC-CONV-005)', () {
    test('removing while above the min succeeds', () {
      final tiles = tilesOf(['USD', 'EUR', 'JPY']);
      final result = ReorderCurrencyTilesUsecase.removeTile(
        tiles: tiles,
        tileId: 'id-1',
      );

      expect(result.isSuccess, isTrue);
      expect(result.tiles!.map((t) => t.currencyCode).toList(), ['USD', 'JPY']);
      expect(result.tiles!.map((t) => t.sortOrder).toList(), [0, 1]);
    });

    test(
      'removing at 2 tiles is rejected with minTilesRequired (TC-CONV-005)',
      () {
        final tiles = tilesOf(['USD', 'EUR']);
        final result = ReorderCurrencyTilesUsecase.removeTile(
          tiles: tiles,
          tileId: 'id-0',
        );

        expect(result.isSuccess, isFalse);
        expect(result.failure, TileListMutationFailure.minTilesRequired);
        expect(result.tiles, isNull);
      },
    );

    test('removing the active tile promotes the new first tile to active', () {
      final tiles = tilesOf(['USD', 'EUR', 'JPY']);
      final result = ReorderCurrencyTilesUsecase.removeTile(
        tiles: tiles,
        tileId: 'id-0',
      );

      expect(result.isSuccess, isTrue);
      expect(result.tiles!.first.isActiveInput, isTrue);
      expect(result.tiles!.first.currencyCode, 'EUR');
    });
  });
}
