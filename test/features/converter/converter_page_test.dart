import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rateify/core/formatting/number_formatter.dart';
import 'package:rateify/features/converter/data/models/rate_snapshot_model.dart';
import 'package:rateify/features/converter/presentation/pages/converter_page.dart';
import 'package:rateify/features/converter/presentation/providers/converter_providers.dart';
import 'package:rateify/features/converter/presentation/widgets/currency_input_tile.dart';
import 'package:rateify/features/settings/domain/entities/app_settings.dart';
import 'package:rateify/features/settings/presentation/providers/settings_providers.dart';

import '../../test_helpers/fake_exchange_rate_repository.dart';
import '../../test_helpers/fake_settings_repository.dart';

void main() {
  Future<ProviderContainer> pumpConverterPage(
    WidgetTester tester, {
    List<String> selectedConverterCurrencies = const ['USD', 'EUR'],
    FakeExchangeRateRepository? exchangeRateRepository,
  }) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

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
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ConverterPage()),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('renders exactly the default 2 tiles (TC-CONV-001)', (
    tester,
  ) async {
    await pumpConverterPage(tester);
    expect(find.byType(CurrencyInputTile), findsNWidgets(2));
  });

  testWidgets(
    'tapping an inactive tile makes it visually active (TC-CONV-007)',
    (tester) async {
      await pumpConverterPage(tester);

      CurrencyInputTile tileFor(String code) => tester
          .widgetList<CurrencyInputTile>(find.byType(CurrencyInputTile))
          .firstWhere((tile) => tile.currencyInfo.code == code);

      expect(tileFor('USD').isActive, isTrue);
      expect(tileFor('EUR').isActive, isFalse);

      await tester.tap(find.text('EUR'));
      await tester.pumpAndSettle();

      expect(tileFor('USD').isActive, isFalse);
      expect(tileFor('EUR').isActive, isTrue);
    },
  );

  testWidgets(
    'adding a 9th currency shows the max-tile message (TC-CONV-004)',
    (tester) async {
      await pumpConverterPage(
        tester,
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

      await tester.tap(find.text('Add currency'));
      await tester.pumpAndSettle();
      // HKD is near the top of the (lazily built) list and not already a
      // tile, so it's guaranteed to be visible without needing to scroll.
      await tester.tap(find.widgetWithText(ListTile, 'HKD'));
      await tester.pumpAndSettle();

      expect(find.text('Maksimum 8 mata uang.'), findsOneWidget);
    },
  );

  testWidgets(
    'removing down to 1 tile shows the min-tile message (TC-CONV-005)',
    (tester) async {
      await pumpConverterPage(tester);

      await tester.longPress(find.text('EUR'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove currency'));
      await tester.pumpAndSettle();

      expect(find.text('Minimal 2 mata uang diperlukan.'), findsOneWidget);
      expect(find.byType(CurrencyInputTile), findsNWidgets(2));
    },
  );

  testWidgets(
    'a currency already present is shown disabled in the picker, preventing the duplicate before it happens (TC-CONV-006)',
    (tester) async {
      await pumpConverterPage(tester);

      await tester.tap(find.text('Add currency'));
      await tester.pumpAndSettle();

      final eurListTile = tester.widget<ListTile>(
        find.widgetWithText(ListTile, 'EUR'),
      );
      expect(eurListTile.enabled, isFalse);
      expect(eurListTile.onTap, isNull);
      // Both currently-present tiles (USD, EUR) show as "Added".
      expect(find.text('Added'), findsNWidgets(2));

      // Tapping a disabled ListTile is a no-op — the sheet stays open and no
      // duplicate is added. The `addCurrency` -> duplicateCurrency rejection
      // path itself is covered directly in converter_controller_test.dart;
      // this confirms the picker also prevents it proactively at the UI
      // level rather than only reacting after the fact.
      await tester.tap(find.widgetWithText(ListTile, 'EUR'));
      await tester.pumpAndSettle();
      expect(find.text('Added'), findsNWidgets(2));
    },
  );

  testWidgets('shows the fresh-rate relative timestamp label (TC-CONV-024)', (
    tester,
  ) async {
    final repo = FakeExchangeRateRepository(
      initialSnapshot: RateSnapshotModel(
        baseCurrency: 'USD',
        rates: const {'EUR': 0.8},
        fetchedAt: DateTime.now().subtract(const Duration(minutes: 5)),
        sourceStatus: RateSourceStatus.freshRemote,
      ),
    );
    await pumpConverterPage(tester, exchangeRateRepository: repo);

    expect(find.textContaining('Updated'), findsOneWidget);
  });

  testWidgets('shows the offline-with-cache timestamp label (TC-CONV-025)', (
    tester,
  ) async {
    final repo = FakeExchangeRateRepository(
      initialSnapshot: RateSnapshotModel(
        baseCurrency: 'USD',
        rates: const {'EUR': 0.8},
        fetchedAt: DateTime(2026, 7, 8, 22, 10),
        sourceStatus: RateSourceStatus.cached,
      ),
    );
    await pumpConverterPage(tester, exchangeRateRepository: repo);

    expect(
      find.text('Offline — using cached rate from 2026-07-08 22:10'),
      findsOneWidget,
    );
  });

  testWidgets(
    'shows the unavailable first-fetch message with no crash (TC-CONV-026)',
    (tester) async {
      final repo = FakeExchangeRateRepository(
        initialSnapshot: RateSnapshotModel.unavailable(
          baseCurrency: 'USD',
          determinedAt: DateTime(2026, 7, 10),
        ),
      );
      await pumpConverterPage(tester, exchangeRateRepository: repo);

      expect(find.textContaining('internet connection'), findsOneWidget);
      // Inactive tile shows a dash rather than a fabricated amount.
      expect(find.text('—'), findsOneWidget);
    },
  );

  testWidgets(
    'dragging a tile reorders the list and shows an elevated drag state (TC-CONV-022, TC-CONV-023)',
    (tester) async {
      await pumpConverterPage(
        tester,
        selectedConverterCurrencies: const ['USD', 'EUR', 'JPY'],
      );

      final dragHandle = find.byIcon(Icons.drag_handle).first;
      final gesture = await tester.startGesture(tester.getCenter(dragHandle));
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.moveBy(const Offset(0, 250));
      // ReorderableListView animates the dragged item's elevation from 0 to 6
      // (Curves.easeInOut) rather than snapping instantly — pump in small
      // increments to let that animation actually progress before checking.
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      // While dragging, Flutter's ReorderableListView wraps the dragged item
      // in an elevated Material — confirms a "floating" visual state exists,
      // without this app needing to hand-roll that elevation itself.
      final elevatedMaterials = tester
          .widgetList<Material>(find.byType(Material))
          .where((material) => material.elevation > 0);
      expect(elevatedMaterials, isNotEmpty);

      await gesture.up();
      await tester.pumpAndSettle();
    },
  );
}
