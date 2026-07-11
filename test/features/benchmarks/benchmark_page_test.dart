import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rateify/features/benchmarks/domain/entities/benchmark_item.dart';
import 'package:rateify/features/benchmarks/presentation/pages/benchmark_page.dart';
import 'package:rateify/features/benchmarks/presentation/providers/benchmark_providers.dart';

import '../../test_helpers/fake_benchmark_repository.dart';

void main() {
  BenchmarkItem item({
    required String id,
    required String name,
    bool isActive = true,
  }) {
    final now = DateTime(2026);
    return BenchmarkItem(
      id: id,
      name: name,
      price: 10000,
      currencyCode: 'IDR',
      isActive: isActive,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<void> pumpBenchmarkPage(
    WidgetTester tester, {
    List<BenchmarkItem>? initialBenchmarks,
  }) async {
    final container = ProviderContainer(
      overrides: [
        benchmarkRepositoryProvider.overrideWithValue(
          FakeBenchmarkRepository(initialBenchmarks: initialBenchmarks),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: BenchmarkPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('§4.4 empty states on the management page', () {
    testWidgets(
      'TC-RPM-009: zero benchmarks exist -> the "no benchmarks" empty state is shown',
      (tester) async {
        await pumpBenchmarkPage(tester, initialBenchmarks: []);

        expect(find.text('Belum ada benchmark.'), findsOneWidget);
        expect(
          find.text(
            'Tambahkan barang yang familiar supaya harga lebih mudah dibandingkan.',
          ),
          findsOneWidget,
        );
        // No stray "none active" message either.
        expect(find.text('Tidak ada benchmark aktif.'), findsNothing);
      },
    );

    testWidgets(
      'TC-RPM-010: benchmarks exist but none active -> the "no active benchmark" empty state is shown',
      (tester) async {
        await pumpBenchmarkPage(
          tester,
          initialBenchmarks: [
            item(id: '1', name: 'Nasi Padang', isActive: false),
            item(id: '2', name: 'Onigiri', isActive: false),
          ],
        );

        expect(find.text('Tidak ada benchmark aktif.'), findsOneWidget);
        expect(
          find.text(
            'Aktifkan benchmark untuk melihat perbandingan harga nyata.',
          ),
          findsOneWidget,
        );
        // The zero-benchmarks message must not also appear — these are two
        // distinct empty states, never conflated.
        expect(find.text('Belum ada benchmark.'), findsNothing);
        // The list itself (with its toggle) must still be visible so the
        // user can act on the notice.
        expect(find.text('Nasi Padang'), findsOneWidget);
        expect(find.text('Onigiri'), findsOneWidget);
      },
    );

    testWidgets(
      'benchmarks exist and at least one is active -> no empty state text at all',
      (tester) async {
        await pumpBenchmarkPage(
          tester,
          initialBenchmarks: [item(id: '1', name: 'Nasi Padang')],
        );

        expect(find.text('Belum ada benchmark.'), findsNothing);
        expect(find.text('Tidak ada benchmark aktif.'), findsNothing);
        expect(find.text('Nasi Padang'), findsOneWidget);
      },
    );
  });
}
