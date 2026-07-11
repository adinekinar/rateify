import 'package:rateify/features/benchmarks/domain/entities/benchmark_item.dart';
import 'package:rateify/features/benchmarks/domain/repositories/benchmark_repository.dart';

/// In-memory [BenchmarkRepository] fake for widget/controller tests that
/// don't care about actual Hive persistence — only about provider
/// wiring/behavior. Mirrors `FakeSettingsRepository`'s shape.
class FakeBenchmarkRepository implements BenchmarkRepository {
  FakeBenchmarkRepository({List<BenchmarkItem>? initialBenchmarks})
    : _benchmarks = List.of(initialBenchmarks ?? const []);

  final List<BenchmarkItem> _benchmarks;
  int _idCounter = 0;

  @override
  List<BenchmarkItem> getAll() => List.unmodifiable(_benchmarks);

  @override
  List<BenchmarkItem> getActive() =>
      _benchmarks.where((b) => b.isActive).toList();

  @override
  void create({
    required String name,
    required double price,
    required String currencyCode,
  }) {
    final now = DateTime.now();
    _benchmarks.add(
      BenchmarkItem(
        id: 'fake-benchmark-${_idCounter++}',
        name: name,
        price: price,
        currencyCode: currencyCode,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  @override
  void edit({
    required String id,
    required String name,
    required double price,
    required String currencyCode,
  }) {
    final index = _benchmarks.indexWhere((b) => b.id == id);
    if (index == -1) return;
    _benchmarks[index] = _benchmarks[index].copyWith(
      name: name,
      price: price,
      currencyCode: currencyCode,
      updatedAt: DateTime.now(),
    );
  }

  @override
  void delete(String id) => _benchmarks.removeWhere((b) => b.id == id);

  @override
  void activate(String id) => _setActive(id, true);

  @override
  void deactivate(String id) => _setActive(id, false);

  void _setActive(String id, bool isActive) {
    final index = _benchmarks.indexWhere((b) => b.id == id);
    if (index == -1) return;
    _benchmarks[index] = _benchmarks[index].copyWith(isActive: isActive);
  }
}
