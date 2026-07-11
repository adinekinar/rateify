import 'package:flutter_test/flutter_test.dart';
import 'package:rateify/core/formatting/number_formatter.dart';
import 'package:rateify/features/benchmarks/domain/entities/benchmark_item.dart';
import 'package:rateify/features/benchmarks/domain/services/benchmark_calculator.dart';
import 'package:rateify/features/converter/data/models/rate_snapshot_model.dart';

void main() {
  final snapshot = RateSnapshotModel(
    baseCurrency: 'USD',
    rates: const {'IDR': 16000.0},
    fetchedAt: DateTime(2026, 7, 10, 12),
    sourceStatus: RateSourceStatus.freshRemote,
  );

  BenchmarkItem benchmark({
    String id = 'b1',
    String name = 'Nasi Padang',
    double price = 20000,
    String currencyCode = 'IDR',
    bool isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final created = createdAt ?? DateTime(2026);
    return BenchmarkItem(
      id: id,
      name: name,
      price: price,
      currencyCode: currencyCode,
      isActive: isActive,
      createdAt: created,
      updatedAt: updatedAt ?? created,
    );
  }

  group('compareOne (§4.3 TC-RPM-005/006)', () {
    test('Rp 60,000 vs Nasi Padang Rp 20,000 -> equivalent count 3', () {
      final result = BenchmarkCalculator.compareOne(
        benchmark: benchmark(),
        snapshot: snapshot,
        fromCurrency: 'IDR',
        fromAmount: 60000,
        numberFormatPreference: NumberFormatPreference.commaDecimalDot,
      );

      expect(result, isNotNull);
      expect(result!.equivalentCount, 3.0);
      expect(result.displayText, 'Setara 3 Nasi Padang');
    });

    test('result close to a whole number rounds to that whole number', () {
      // 1997 / 1000 = 1.997, within the 0.05 epsilon of 2.
      final result = BenchmarkCalculator.compareOne(
        benchmark: benchmark(price: 1000),
        snapshot: snapshot,
        fromCurrency: 'IDR',
        fromAmount: 1997,
        numberFormatPreference: NumberFormatPreference.commaDecimalDot,
      );

      expect(result!.equivalentCount, closeTo(1.997, 1e-9));
      expect(result.displayText, 'Setara 2 Nasi Padang');
    });

    test('small fractional result (< 1) shows up to 2 decimals', () {
      final result = BenchmarkCalculator.compareOne(
        benchmark: benchmark(name: 'Onigiri', price: 100),
        snapshot: snapshot,
        fromCurrency: 'IDR',
        fromAmount: 50,
        numberFormatPreference: NumberFormatPreference.commaDecimalDot,
      );

      expect(result!.displayText, 'Setara 0.5 Onigiri');
    });

    test(
      'fractional result >= 1 shows 1 decimal, never excessive decimals',
      () {
        final result = BenchmarkCalculator.compareOne(
          benchmark: benchmark(name: 'Coffee', price: 100),
          snapshot: snapshot,
          fromCurrency: 'IDR',
          fromAmount: 1240,
          numberFormatPreference: NumberFormatPreference.commaDecimalDot,
        );

        expect(result!.displayText, 'Setara 12.4 Coffee');
      },
    );

    test(
      'a value not close to a whole number, and >= 1, does not get rounded to that whole number',
      () {
        final result = BenchmarkCalculator.compareOne(
          benchmark: benchmark(price: 1000),
          snapshot: snapshot,
          fromCurrency: 'IDR',
          fromAmount: 1900,
          numberFormatPreference: NumberFormatPreference.commaDecimalDot,
        );

        expect(result!.displayText, 'Setara 1.9 Nasi Padang');
      },
    );

    test('a non-positive price is rejected rather than dividing by zero', () {
      final result = BenchmarkCalculator.compareOne(
        benchmark: benchmark(price: 0),
        snapshot: snapshot,
        fromCurrency: 'IDR',
        fromAmount: 100,
        numberFormatPreference: NumberFormatPreference.commaDecimalDot,
      );

      expect(result, isNull);
    });

    test('an unresolvable benchmark currency returns null, not a crash', () {
      final result = BenchmarkCalculator.compareOne(
        benchmark: benchmark(currencyCode: 'XXX'),
        snapshot: snapshot,
        fromCurrency: 'IDR',
        fromAmount: 100,
        numberFormatPreference: NumberFormatPreference.commaDecimalDot,
      );

      expect(result, isNull);
    });
  });

  group('orderActiveByRecency (§4.2 "top" ordering rule, TC-RPM-007/008)', () {
    test(
      'two active benchmarks with different updatedAt -> the more recently updated one is top',
      () {
        final older = benchmark(
          id: 'older',
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026, 1, 5),
        );
        final newer = benchmark(
          id: 'newer',
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026, 1, 10),
        );

        final ordered = BenchmarkCalculator.orderActiveByRecency([
          older,
          newer,
        ]);

        expect(ordered.map((b) => b.id).toList(), ['newer', 'older']);
      },
    );

    test(
      'two active benchmarks with identical updatedAt fall back to the more recent createdAt',
      () {
        final sameUpdatedAt = DateTime(2026, 2);
        final olderCreated = benchmark(
          id: 'older-created',
          createdAt: DateTime(2026),
          updatedAt: sameUpdatedAt,
        );
        final newerCreated = benchmark(
          id: 'newer-created',
          createdAt: DateTime(2026, 1, 15),
          updatedAt: sameUpdatedAt,
        );

        final ordered = BenchmarkCalculator.orderActiveByRecency([
          olderCreated,
          newerCreated,
        ]);

        expect(ordered.map((b) => b.id).toList(), [
          'newer-created',
          'older-created',
        ]);
      },
    );

    test('inactive benchmarks are excluded entirely', () {
      final active = benchmark(id: 'active');
      final inactive = benchmark(id: 'inactive', isActive: false);

      final ordered = BenchmarkCalculator.orderActiveByRecency([
        active,
        inactive,
      ]);

      expect(ordered.map((b) => b.id).toList(), ['active']);
    });
  });

  group('compareAll', () {
    test('orders by recency first, then computes each comparison', () {
      final older = benchmark(
        id: 'older',
        name: 'Older Item',
        price: 10000,
        updatedAt: DateTime(2026, 1, 5),
      );
      final newer = benchmark(
        id: 'newer',
        name: 'Newer Item',
        updatedAt: DateTime(2026, 1, 10),
      );

      final results = BenchmarkCalculator.compareAll(
        benchmarks: [older, newer],
        snapshot: snapshot,
        fromCurrency: 'IDR',
        fromAmount: 60000,
        numberFormatPreference: NumberFormatPreference.commaDecimalDot,
      );

      expect(results.map((r) => r.benchmarkId).toList(), ['newer', 'older']);
      expect(results.first.displayText, 'Setara 3 Newer Item');
    });

    test('an empty or all-inactive benchmark list produces no results', () {
      final results = BenchmarkCalculator.compareAll(
        benchmarks: [benchmark(isActive: false)],
        snapshot: snapshot,
        fromCurrency: 'IDR',
        fromAmount: 60000,
        numberFormatPreference: NumberFormatPreference.commaDecimalDot,
      );

      expect(results, isEmpty);
    });
  });
}
