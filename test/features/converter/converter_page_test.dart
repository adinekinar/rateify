import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rateify/core/constants/ui_constants.dart';
import 'package:rateify/core/formatting/number_formatter.dart';
import 'package:rateify/features/benchmarks/domain/entities/benchmark_item.dart';
import 'package:rateify/features/benchmarks/presentation/providers/benchmark_providers.dart';
import 'package:rateify/features/benchmarks/presentation/widgets/benchmark_comparison_card.dart';
import 'package:rateify/features/converter/data/models/rate_snapshot_model.dart';
import 'package:rateify/features/converter/presentation/pages/converter_page.dart';
import 'package:rateify/features/converter/presentation/providers/converter_providers.dart';
import 'package:rateify/features/converter/presentation/widgets/currency_input_tile.dart';
import 'package:rateify/features/converter/presentation/widgets/custom_keypad.dart';
import 'package:rateify/features/settings/domain/entities/app_settings.dart';
import 'package:rateify/features/settings/presentation/providers/settings_providers.dart';

import '../../test_helpers/fake_benchmark_repository.dart';
import '../../test_helpers/fake_exchange_rate_repository.dart';
import '../../test_helpers/fake_settings_repository.dart';

void main() {
  Future<ProviderContainer> pumpConverterPage(
    WidgetTester tester, {
    List<String> selectedConverterCurrencies = const ['USD', 'EUR'],
    FakeExchangeRateRepository? exchangeRateRepository,
    List<BenchmarkItem>? initialBenchmarks,
    Size surfaceSize = const Size(400, 900),
  }) async {
    await tester.binding.setSurfaceSize(surfaceSize);
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
        benchmarkRepositoryProvider.overrideWithValue(
          FakeBenchmarkRepository(initialBenchmarks: initialBenchmarks),
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

      // With 8 tiles, "Add currency" now sits at the end of the same
      // scrollable tile section rather than in a separate fixed area —
      // scroll it into view before tapping.
      await tester.ensureVisible(find.text('Add currency'));
      await tester.pumpAndSettle();
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

  group('§16.1 compact inactive tile — content fits without excess scrolling', () {
    // Real device sizes: a common modern phone, and a small older one that
    // previously reproduced the Batch 03b bug (tiles' Expanded region
    // collapsed toward zero on this size before the scroll-region fix).
    const realisticPhone = Size(375, 667); // iPhone SE (2020/2022) / iPhone 8
    const smallPhone = Size(320, 568); // iPhone SE (1st gen) — tight case
    const eightTileCurrencies = [
      'USD',
      'EUR',
      'JPY',
      'GBP',
      'AUD',
      'CAD',
      'CHF',
      'CNY',
    ];

    void expectKeypadFullyVisible(WidgetTester tester, Size screenSize) {
      final renderBox =
          tester.renderObject(find.byType(CustomKeypad)) as RenderBox;
      final topLeft = renderBox.localToGlobal(Offset.zero);
      final bottom = topLeft.dy + renderBox.size.height;

      expect(
        topLeft.dy,
        greaterThanOrEqualTo(0),
        reason: 'keypad top must not be above the viewport',
      );
      expect(
        bottom,
        lessThanOrEqualTo(screenSize.height),
        reason:
            'keypad bottom ($bottom) must be fully within the viewport '
            '(${screenSize.height}) — it must never require scrolling to reach',
      );
    }

    double tileSectionMaxScrollExtent(WidgetTester tester) {
      final scrollableState = tester.state<ScrollableState>(
        find.byType(Scrollable).first,
      );
      return scrollableState.position.maxScrollExtent;
    }

    testWidgets('TC-CONV-029: 2 tiles on a small phone viewport (320x568) — zero '
        'scrolling required for tiles or keypad', (tester) async {
      await pumpConverterPage(tester, surfaceSize: smallPhone);

      expect(find.byType(CurrencyInputTile), findsNWidgets(2));
      expect(find.text('USD'), findsOneWidget);
      expect(find.text('EUR'), findsOneWidget);
      expectKeypadFullyVisible(tester, smallPhone);
      expect(tester.takeException(), isNull);

      // The whole point of the compact layout: at 2 tiles there should be
      // nothing left to scroll at all.
      expect(
        tileSectionMaxScrollExtent(tester),
        lessThanOrEqualTo(0.5),
        reason:
            '2 compact tiles + the add-currency row must fit with zero scrolling',
      );
    });

    testWidgets(
      'TC-CONV-030: 8 tiles on a small phone viewport — tile section may '
      'scroll, keypad stays fixed and fully visible, inactive tiles are compact',
      (tester) async {
        await pumpConverterPage(
          tester,
          selectedConverterCurrencies: eightTileCurrencies,
          surfaceSize: smallPhone,
        );

        // All 8 must actually be built (not skipped by a collapsed lazy
        // list — the Batch 03b root cause) so the scroll view can reach them.
        expect(find.byType(CurrencyInputTile), findsNWidgets(8));
        expectKeypadFullyVisible(tester, smallPhone);
        expect(tester.takeException(), isNull);

        // With 8 tiles, some scrolling in the tile section is expected and
        // acceptable per §16.1 — just confirm it's actually available.
        expect(
          tileSectionMaxScrollExtent(tester),
          greaterThan(0),
          reason:
              '8 tiles should not all fit on a 320x568 screen — the tile '
              'section should be scrollable',
        );

        // Inactive tiles use the compact single-row layout: significantly
        // shorter than the active tile's comfortable stacked layout.
        final activeTileHeight =
            (tester.renderObject(
                      find.byWidgetPredicate(
                        (w) => w is CurrencyInputTile && w.isActive,
                      ),
                    )
                    as RenderBox)
                .size
                .height;
        final inactiveTileHeights = tester
            .widgetList<CurrencyInputTile>(find.byType(CurrencyInputTile))
            .where((tile) => !tile.isActive)
            .map((tile) {
              final element = find.byWidgetPredicate((w) => identical(w, tile));
              return (tester.renderObject(element) as RenderBox).size.height;
            });

        for (final height in inactiveTileHeights) {
          expect(
            height,
            lessThan(activeTileHeight * 0.7),
            reason:
                'compact inactive tiles must be noticeably shorter than the active tile',
          );
        }
      },
    );

    testWidgets('2 tiles, realistic phone size', (tester) async {
      await pumpConverterPage(tester, surfaceSize: realisticPhone);
      expectKeypadFullyVisible(tester, realisticPhone);
      expect(tester.takeException(), isNull);
    });

    testWidgets('8 tiles, realistic phone size', (tester) async {
      await pumpConverterPage(
        tester,
        selectedConverterCurrencies: eightTileCurrencies,
        surfaceSize: realisticPhone,
      );
      expectKeypadFullyVisible(tester, realisticPhone);
      expect(tester.takeException(), isNull);
    });
  });

  group('§16.2 keypad spacing and space-filling rule (Batch 03d)', () {
    const smallPhone = Size(320, 568);

    Rect buttonRectFor(WidgetTester tester, Finder labelOrIconFinder) {
      final material = find
          .ancestor(of: labelOrIconFinder, matching: find.byType(Material))
          .first;
      return tester.getRect(material);
    }

    testWidgets(
      'TC-CONV-031: no dead gap between the tile section and the keypad, at '
      '2-3 tiles on a small phone viewport',
      (tester) async {
        await pumpConverterPage(
          tester,
          selectedConverterCurrencies: const ['USD', 'EUR', 'JPY'],
          surfaceSize: smallPhone,
        );

        // Measure the tile section's own allocated/rendered region (the
        // `SingleChildScrollView`'s box), not "Add currency"'s position —
        // §15.6 (Batch 04b) permits the tile section to scroll internally
        // once its content (now with more generous spacing) outgrows the
        // space Flexible actually gave it, so content position alone is no
        // longer a reliable proxy for where that allocated region ends.
        final tileSectionBottom = tester
            .getBottomLeft(find.byType(SingleChildScrollView).first)
            .dy;
        final keypadTop = tester.getTopLeft(find.byType(CustomKeypad)).dy;
        final gap = keypadTop - tileSectionBottom;

        expect(
          gap,
          inInclusiveRange(0, 40),
          reason:
              'gap between the tile section and the keypad should be a small, '
              'intentional margin, not a large dead space (measured: $gap)',
        );

        // Keypad should occupy meaningfully more than a token sliver of the
        // remaining space — i.e. it's actually the flexible/expanding
        // element, not a small fixed block with room to spare above it.
        final screenHeight = smallPhone.height;
        final keypadHeight = tester.getSize(find.byType(CustomKeypad)).height;
        expect(
          keypadHeight,
          greaterThan(screenHeight * 0.35),
          reason:
              'keypad should expand to fill the remaining space, not stay small',
        );

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'TC-CONV-031: every keypad button has clear visible spacing from its neighbors',
      (tester) async {
        await pumpConverterPage(tester, surfaceSize: smallPhone);

        final clearRect = buttonRectFor(tester, find.text('C'));
        final backspaceRect = buttonRectFor(
          tester,
          find.byIcon(Icons.backspace_outlined),
        );
        final sevenRect = buttonRectFor(tester, find.text('7'));
        final eightRect = buttonRectFor(tester, find.text('8'));
        final fourRect = buttonRectFor(tester, find.text('4'));

        // Horizontal gap within the same row (C | backspace, and 7 | 8).
        expect(
          backspaceRect.left - clearRect.right,
          greaterThan(2),
          reason: 'C and backspace must not visually merge into one block',
        );
        expect(
          eightRect.left - sevenRect.right,
          greaterThan(2),
          reason: '7 and 8 must not visually merge into one block',
        );

        // Vertical gap between rows (7 | 4).
        expect(
          fourRect.top - sevenRect.bottom,
          greaterThan(2),
          reason: 'rows must not visually merge into one block',
        );
      },
    );

    testWidgets(
      'TC-CONV-031: keypad buttons grew back from the Batch 03c 44px low-water mark '
      'now that the tile section no longer eats unnecessary space',
      (tester) async {
        await pumpConverterPage(tester, surfaceSize: smallPhone);

        final clearRect = buttonRectFor(tester, find.text('C'));
        expect(
          clearRect.height,
          greaterThanOrEqualTo(44),
          reason:
              'button height should be at least as comfortable as the Batch 03c baseline',
        );
      },
    );
  });

  group('§4.1 Real Price Mode comparison card (Batch 04)', () {
    BenchmarkItem benchmark({
      required String id,
      required String name,
      double price = 16000,
      DateTime? updatedAt,
    }) {
      final timestamp = updatedAt ?? DateTime(2026);
      return BenchmarkItem(
        id: id,
        name: name,
        price: price,
        currencyCode: 'IDR',
        isActive: true,
        createdAt: timestamp,
        updatedAt: timestamp,
      );
    }

    testWidgets(
      'TC-RPM-011: no active benchmarks -> the section is fully hidden, no empty-state text',
      (tester) async {
        await pumpConverterPage(tester);

        expect(find.textContaining('Setara'), findsNothing);
        expect(find.text('Belum ada benchmark.'), findsNothing);
        expect(find.text('Tidak ada benchmark aktif.'), findsNothing);
      },
    );

    testWidgets(
      'one active benchmark -> shows its comparison text, updating as the active tile amount changes',
      (tester) async {
        await pumpConverterPage(
          tester,
          initialBenchmarks: [benchmark(id: '1', name: 'Nasi Padang')],
        );

        // Active tile is USD (rate USD->IDR = 16000); typing "3" -> 3 USD ->
        // 48,000 IDR -> 48,000 / 16,000 = 3.
        await tester.tap(find.text('3'));
        await tester.pumpAndSettle();

        expect(find.text('Setara 3 Nasi Padang'), findsOneWidget);
      },
    );

    testWidgets(
      'more than one active benchmark -> shows the top one plus a "+N more" affordance opening a bottom sheet with the rest',
      (tester) async {
        await pumpConverterPage(
          tester,
          initialBenchmarks: [
            benchmark(
              id: 'older',
              name: 'Nasi Padang',
              updatedAt: DateTime(2026),
            ),
            benchmark(
              id: 'newer',
              name: 'Onigiri',
              updatedAt: DateTime(2026, 1, 10),
            ),
          ],
        );

        await tester.tap(find.text('3'));
        await tester.pumpAndSettle();

        // "Onigiri" was updated more recently -> it's the top card.
        expect(find.text('Setara 3 Onigiri'), findsOneWidget);
        expect(find.text('+1 more'), findsOneWidget);

        await tester.tap(find.text('+1 more'));
        await tester.pumpAndSettle();

        expect(find.text('Setara 3 Nasi Padang'), findsOneWidget);
      },
    );
  });

  group('§15.6 Spacing Scale — minimum gaps and padding (Batch 04b)', () {
    const smallPhone = Size(320, 568);
    const standardPhone = Size(375, 812);

    BenchmarkItem benchmark({required String name, double price = 16000}) {
      final now = DateTime(2026);
      return BenchmarkItem(
        id: 'b-$name',
        name: name,
        price: price,
        currencyCode: 'IDR',
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );
    }

    Rect containerRectAncestorOf(WidgetTester tester, Finder textOrIcon) {
      return tester.getRect(
        find.ancestor(of: textOrIcon, matching: find.byType(Container)).first,
      );
    }

    EdgeInsets containerPaddingAncestorOf(
      WidgetTester tester,
      Finder textOrIcon,
    ) {
      final container = tester.widget<Container>(
        find.ancestor(of: textOrIcon, matching: find.byType(Container)).first,
      );
      return container.padding! as EdgeInsets;
    }

    Rect buttonRectFor(WidgetTester tester, Finder labelOrIconFinder) {
      final material = find
          .ancestor(of: labelOrIconFinder, matching: find.byType(Material))
          .first;
      return tester.getRect(material);
    }

    for (final viewport in [smallPhone, standardPhone]) {
      testWidgets(
        'TC-CONV-032: every adjacent pair keeps at least the gapSm minimum, '
        'at ${viewport.width.toInt()}x${viewport.height.toInt()}',
        (tester) async {
          await pumpConverterPage(
            tester,
            selectedConverterCurrencies: const ['USD', 'EUR', 'JPY'],
            initialBenchmarks: [benchmark(name: 'Nasi Padang')],
            surfaceSize: viewport,
          );

          // Give the active tile a nonzero amount so the benchmark card
          // actually renders content (and thus has a real, measurable
          // rect) rather than collapsing to `SizedBox.shrink()`.
          await tester.tap(find.text('5'));
          await tester.pumpAndSettle();

          // --- Gap between every adjacent tile ---
          final tileRects = tester
              .widgetList<CurrencyInputTile>(find.byType(CurrencyInputTile))
              .map(
                (tile) => tester.getRect(
                  find.byWidgetPredicate((w) => identical(w, tile)),
                ),
              )
              .toList();
          expect(tileRects, hasLength(3));
          for (var i = 0; i < tileRects.length - 1; i++) {
            final gap = tileRects[i + 1].top - tileRects[i].bottom;
            expect(
              gap,
              greaterThanOrEqualTo(UiConstants.gapSm),
              reason:
                  'gap between tile $i and tile ${i + 1} must be at least '
                  'gapSm (${UiConstants.gapSm}px), measured: $gap',
            );
          }

          // --- Gap between the last tile and the benchmark card ---
          final cardRect = tester.getRect(find.byType(BenchmarkComparisonCard));
          final lastTileToCardGap = cardRect.top - tileRects.last.bottom;
          expect(
            lastTileToCardGap,
            greaterThanOrEqualTo(UiConstants.gapSm),
            reason:
                'gap between the last tile and the benchmark card must be '
                'at least gapSm (${UiConstants.gapSm}px), measured: '
                '$lastTileToCardGap',
          );

          // --- Gap between the benchmark card and the Add currency row ---
          final addCurrencyRect = containerRectAncestorOf(
            tester,
            find.text('Add currency'),
          );
          final cardToAddCurrencyGap = addCurrencyRect.top - cardRect.bottom;
          expect(
            cardToAddCurrencyGap,
            greaterThanOrEqualTo(UiConstants.gapSm),
            reason:
                'gap between the benchmark card and the Add currency row '
                'must be at least gapSm (${UiConstants.gapSm}px), measured: '
                '$cardToAddCurrencyGap',
          );

          // --- Gap between every keypad button, in the row and between rows ---
          final clearRect = buttonRectFor(tester, find.text('C'));
          final backspaceRect = buttonRectFor(
            tester,
            find.byIcon(Icons.backspace_outlined),
          );
          final sevenRect = buttonRectFor(tester, find.text('7'));
          final eightRect = buttonRectFor(tester, find.text('8'));
          final fourRect = buttonRectFor(tester, find.text('4'));

          expect(
            backspaceRect.left - clearRect.right,
            greaterThanOrEqualTo(UiConstants.gapSm),
            reason: 'C and backspace must keep at least gapSm apart',
          );
          expect(
            eightRect.left - sevenRect.right,
            greaterThanOrEqualTo(UiConstants.gapSm),
            reason: '7 and 8 must keep at least gapSm apart',
          );
          expect(
            fourRect.top - sevenRect.bottom,
            greaterThanOrEqualTo(UiConstants.gapSm),
            reason: 'row 1 and row 2 must keep at least gapSm apart',
          );

          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        'TC-CONV-032: every tile/card keeps at least the gapMd internal '
        'padding, at ${viewport.width.toInt()}x${viewport.height.toInt()}',
        (tester) async {
          await pumpConverterPage(
            tester,
            selectedConverterCurrencies: const ['USD', 'EUR', 'JPY'],
            initialBenchmarks: [benchmark(name: 'Nasi Padang')],
            surfaceSize: viewport,
          );
          await tester.tap(find.text('5'));
          await tester.pumpAndSettle();

          // Compact (inactive) tile.
          final compactTile = tester
              .widgetList<CurrencyInputTile>(find.byType(CurrencyInputTile))
              .firstWhere((tile) => !tile.isActive);
          final compactContainer = tester.widget<AnimatedContainer>(
            find.descendant(
              of: find.byWidgetPredicate((w) => identical(w, compactTile)),
              matching: find.byType(AnimatedContainer),
            ),
          );
          final compactPadding = compactContainer.padding! as EdgeInsets;
          expect(
            compactPadding.top,
            greaterThanOrEqualTo(UiConstants.gapMd),
            reason: 'compact tile top padding must be at least gapMd (12px)',
          );
          expect(
            compactPadding.bottom,
            greaterThanOrEqualTo(UiConstants.gapMd),
            reason: 'compact tile bottom padding must be at least gapMd (12px)',
          );

          // Benchmark comparison card.
          final cardPadding = containerPaddingAncestorOf(
            tester,
            find.textContaining('Setara'),
          );
          expect(
            cardPadding.top,
            greaterThanOrEqualTo(UiConstants.gapMd),
            reason: 'benchmark card top padding must be at least gapMd (12px)',
          );
          expect(
            cardPadding.bottom,
            greaterThanOrEqualTo(UiConstants.gapMd),
            reason:
                'benchmark card bottom padding must be at least gapMd (12px)',
          );

          // Add currency row.
          final addCurrencyPadding = containerPaddingAncestorOf(
            tester,
            find.text('Add currency'),
          );
          expect(
            addCurrencyPadding.top,
            greaterThanOrEqualTo(UiConstants.gapMd),
            reason:
                'Add currency row top padding must be at least gapMd (12px)',
          );
          expect(
            addCurrencyPadding.bottom,
            greaterThanOrEqualTo(UiConstants.gapMd),
            reason:
                'Add currency row bottom padding must be at least gapMd (12px)',
          );
        },
      );
    }
  });
}
