import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rateify/core/formatting/number_formatter.dart';
import 'package:rateify/features/benchmarks/domain/entities/benchmark_item.dart';
import 'package:rateify/features/benchmarks/presentation/providers/benchmark_providers.dart';
import 'package:rateify/features/converter/data/models/rate_snapshot_model.dart';
import 'package:rateify/features/converter/domain/usecases/reorder_currency_tiles.dart';
import 'package:rateify/features/converter/presentation/providers/converter_controller.dart';
import 'package:rateify/features/converter/presentation/providers/converter_providers.dart';
import 'package:rateify/features/settings/domain/entities/app_settings.dart';
import 'package:rateify/features/settings/presentation/providers/settings_providers.dart';

import '../../test_helpers/fake_benchmark_repository.dart';
import '../../test_helpers/fake_exchange_rate_repository.dart';
import '../../test_helpers/fake_settings_repository.dart';

void main() {
  ProviderContainer buildContainer({
    List<String> selectedConverterCurrencies = const ['USD', 'EUR'],
    FakeExchangeRateRepository? exchangeRateRepository,
    List<BenchmarkItem>? initialBenchmarks,
  }) {
    final settings = AppSettings.initial(
      numberFormatPreference: NumberFormatPreference.commaDecimalDot,
    ).copyWith(selectedConverterCurrencies: selectedConverterCurrencies);

    final container = ProviderContainer(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(
          FakeSettingsRepository(initialSettings: settings),
        ),
        exchangeRateRepositoryProvider.overrideWithValue(
          exchangeRateRepository ?? FakeExchangeRateRepository(),
        ),
        benchmarkRepositoryProvider.overrideWithValue(
          FakeBenchmarkRepository(initialBenchmarks: initialBenchmarks),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test(
    'default tile seeding: home=USD -> Tile1=USD, Tile2=EUR (TC-CONV-002)',
    () async {
      final container = buildContainer();
      final state = await container.read(converterControllerProvider.future);

      expect(state.tiles.length, 2);
      expect(state.tiles[0].currencyCode, 'USD');
      expect(state.tiles[1].currencyCode, 'EUR');
      // §10.4 session-restore rule: first currency in the persisted list is
      // always the active tile.
      expect(state.tiles[0].isActiveInput, isTrue);
      expect(state.activeTileId, state.tiles[0].id);
    },
  );

  test(
    'default tile seeding: home=IDR -> Tile1=IDR, Tile2=USD (TC-CONV-003)',
    () async {
      final container = buildContainer(
        selectedConverterCurrencies: const ['IDR', 'USD'],
      );
      final state = await container.read(converterControllerProvider.future);

      expect(state.tiles[0].currencyCode, 'IDR');
      expect(state.tiles[1].currencyCode, 'USD');
      expect(state.tiles[0].isActiveInput, isTrue);
    },
  );

  test('exactly 2 tiles by default (TC-CONV-001)', () async {
    final container = buildContainer();
    final state = await container.read(converterControllerProvider.future);
    expect(state.tiles.length, 2);
  });

  test(
    'typing digits updates the active tile raw input and converts others',
    () async {
      final container = buildContainer();
      await container.read(converterControllerProvider.future);
      final notifier = container.read(converterControllerProvider.notifier);

      notifier.appendDigit('1');
      notifier.appendDigit('0');
      notifier.appendDigit('0');

      final state = container.read(converterControllerProvider).value!;
      final usdTile = state.tiles.firstWhere((t) => t.currencyCode == 'USD');
      final eurTile = state.tiles.firstWhere((t) => t.currencyCode == 'EUR');
      expect(usdTile.rawInput, '100');
      expect(eurTile.convertedAmount, 80.0); // 100 * 0.8
    },
  );

  test(
    'tapping an inactive tile makes it active and resets its input (TC-CONV-007)',
    () async {
      final container = buildContainer();
      await container.read(converterControllerProvider.future);
      final notifier = container.read(converterControllerProvider.notifier);

      notifier.appendDigit('5');
      final beforeState = container.read(converterControllerProvider).value!;
      final eurId = beforeState.tiles
          .firstWhere((t) => t.currencyCode == 'EUR')
          .id;

      notifier.selectTile(eurId);

      final afterState = container.read(converterControllerProvider).value!;
      expect(afterState.activeTileId, eurId);
      final eurTile = afterState.tiles.firstWhere((t) => t.id == eurId);
      expect(eurTile.isActiveInput, isTrue);
      expect(eurTile.rawInput, '0');
    },
  );

  test(
    'adding a 9th currency is blocked with maxTilesReached (TC-CONV-004)',
    () async {
      final container = buildContainer(
        selectedConverterCurrencies: const [
          'USD',
          'EUR',
          'JPY',
          'GBP',
          'AUD',
          'CAD',
          'CHF',
          'CNY',
        ],
      );
      await container.read(converterControllerProvider.future);
      final notifier = container.read(converterControllerProvider.notifier);

      final failure = notifier.addCurrency('IDR');

      expect(failure, TileListMutationFailure.maxTilesReached);
      final state = container.read(converterControllerProvider).value!;
      expect(state.tiles.length, 8);
    },
  );

  test(
    'removing down to 1 tile is blocked with minTilesRequired (TC-CONV-005)',
    () async {
      final container = buildContainer();
      await container.read(converterControllerProvider.future);
      final notifier = container.read(converterControllerProvider.notifier);
      final state = container.read(converterControllerProvider).value!;

      final failure = notifier.removeCurrency(state.tiles.first.id);

      expect(failure, TileListMutationFailure.minTilesRequired);
      expect(
        container.read(converterControllerProvider).value!.tiles.length,
        2,
      );
    },
  );

  test(
    'adding a currency already present is blocked with duplicateCurrency (TC-CONV-006)',
    () async {
      final container = buildContainer();
      await container.read(converterControllerProvider.future);
      final notifier = container.read(converterControllerProvider.notifier);

      final failure = notifier.addCurrency('EUR');

      expect(failure, TileListMutationFailure.duplicateCurrency);
      expect(
        container.read(converterControllerProvider).value!.tiles.length,
        2,
      );
    },
  );

  test(
    'reorder persists the new currency order and does not touch the active amount or refetch (TC-CONV-022)',
    () async {
      final fakeRepo = FakeExchangeRateRepository();
      final container = buildContainer(
        selectedConverterCurrencies: const ['USD', 'EUR', 'JPY'],
        exchangeRateRepository: fakeRepo,
      );
      await container.read(converterControllerProvider.future);
      final notifier = container.read(converterControllerProvider.notifier);

      notifier.appendDigit('7');
      final callsBeforeReorder = fakeRepo.getSnapshotCallCount;

      notifier.reorder(0, 2); // move USD (index 0) to the end

      final state = container.read(converterControllerProvider).value!;
      expect(state.tiles.map((t) => t.currencyCode).toList(), [
        'EUR',
        'JPY',
        'USD',
      ]);
      // The active tile (USD) keeps its typed amount.
      final usdTile = state.tiles.firstWhere((t) => t.currencyCode == 'USD');
      expect(usdTile.rawInput, '7');
      // Reordering must not itself trigger a rate refetch.
      expect(fakeRepo.getSnapshotCallCount, callsBeforeReorder);
      expect(fakeRepo.refreshCallCount, 0);

      // Persisted to settings in the new order.
      final persisted = container
          .read(appSettingsProvider)
          .selectedConverterCurrencies;
      expect(persisted, ['EUR', 'JPY', 'USD']);
    },
  );

  test(
    'offline with a cached snapshot reports isOffline and preserves rates (TC-CONV-018 path)',
    () async {
      final cachedSnapshot = RateSnapshotModel(
        baseCurrency: 'USD',
        rates: const {'EUR': 0.8},
        fetchedAt: DateTime(2026, 7, 9),
        sourceStatus: RateSourceStatus.cached,
      );
      final container = buildContainer(
        exchangeRateRepository: FakeExchangeRateRepository(
          initialSnapshot: cachedSnapshot,
        ),
      );
      final state = await container.read(converterControllerProvider.future);

      expect(state.isOffline, isTrue);
      expect(state.errorMessage, isNull);
    },
  );

  test(
    'unavailable snapshot (no cache) surfaces an explanatory error message (TC-CONV-019, TC-CONV-026)',
    () async {
      final unavailable = RateSnapshotModel.unavailable(
        baseCurrency: 'USD',
        determinedAt: DateTime(2026, 7, 10),
      );
      final container = buildContainer(
        exchangeRateRepository: FakeExchangeRateRepository(
          initialSnapshot: unavailable,
        ),
      );
      final state = await container.read(converterControllerProvider.future);

      expect(state.isOffline, isTrue);
      expect(state.errorMessage, isNotNull);
      expect(state.errorMessage, contains('internet connection'));
      // No crash, and inactive tile shows no fabricated converted amount.
      final eurTile = state.tiles.firstWhere((t) => t.currencyCode == 'EUR');
      expect(eurTile.convertedAmount, isNull);
    },
  );

  test(
    'after reordering and a simulated restart, the new first currency in the persisted '
    'list becomes the active tile (TC-CONV-027)',
    () async {
      final firstSessionContainer = buildContainer(
        selectedConverterCurrencies: const ['USD', 'EUR', 'JPY'],
      );
      final firstSessionState = await firstSessionContainer.read(
        converterControllerProvider.future,
      );
      final originalEurTileId = firstSessionState.tiles
          .firstWhere((t) => t.currencyCode == 'EUR')
          .id;
      firstSessionContainer
          .read(converterControllerProvider.notifier)
          .reorder(0, 2);

      final persistedOrder = firstSessionContainer
          .read(appSettingsProvider)
          .selectedConverterCurrencies;
      expect(persistedOrder, ['EUR', 'JPY', 'USD']);
      firstSessionContainer.dispose();

      // Simulated app restart — a brand-new container/session reading
      // whatever ended up persisted from the first session.
      final secondSessionContainer = buildContainer(
        selectedConverterCurrencies: persistedOrder,
      );
      final restoredState = await secondSessionContainer.read(
        converterControllerProvider.future,
      );

      expect(restoredState.tiles.first.currencyCode, 'EUR');
      expect(restoredState.tiles.first.isActiveInput, isTrue);
      expect(restoredState.activeTileId, restoredState.tiles.first.id);
      // Session-scoped ids (§10.4/§20.8) are regenerated fresh, never reused
      // across a "restart" — same EUR currency, different id.
      expect(restoredState.tiles.first.id, isNot(equals(originalEurTileId)));
    },
  );
}
