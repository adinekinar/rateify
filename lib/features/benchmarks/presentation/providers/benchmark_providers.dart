import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/benchmark_item.dart';
import '../../domain/repositories/benchmark_repository.dart';

/// §12.1 core provider. Overridden in `main()` with a real
/// [HiveBenchmarkRepository] once the benchmark Hive box has been opened —
/// same composition-root pattern as `settingsRepositoryProvider` and
/// `exchangeRateRepositoryProvider`.
final benchmarkRepositoryProvider = Provider<BenchmarkRepository>((ref) {
  throw UnimplementedError(
    'benchmarkRepositoryProvider must be overridden with a HiveBenchmarkRepository in main()',
  );
});

/// All benchmarks, in whatever order the repository returns them —
/// consumed by the management page (which needs to show inactive ones
/// too) and, filtered/ordered, by the converter feature's comparison card.
final benchmarksProvider =
    NotifierProvider<BenchmarksController, List<BenchmarkItem>>(
      BenchmarksController.new,
    );

class BenchmarksController extends Notifier<List<BenchmarkItem>> {
  @override
  List<BenchmarkItem> build() =>
      ref.watch(benchmarkRepositoryProvider).getAll();

  void create({
    required String name,
    required double price,
    required String currencyCode,
  }) {
    ref
        .read(benchmarkRepositoryProvider)
        .create(name: name, price: price, currencyCode: currencyCode);
    _reload();
  }

  void edit({
    required String id,
    required String name,
    required double price,
    required String currencyCode,
  }) {
    ref
        .read(benchmarkRepositoryProvider)
        .edit(id: id, name: name, price: price, currencyCode: currencyCode);
    _reload();
  }

  void delete(String id) {
    ref.read(benchmarkRepositoryProvider).delete(id);
    _reload();
  }

  void activate(String id) {
    ref.read(benchmarkRepositoryProvider).activate(id);
    _reload();
  }

  void deactivate(String id) {
    ref.read(benchmarkRepositoryProvider).deactivate(id);
    _reload();
  }

  void _reload() {
    state = ref.read(benchmarkRepositoryProvider).getAll();
  }
}
