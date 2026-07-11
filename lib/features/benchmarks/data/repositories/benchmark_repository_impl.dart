import 'dart:convert';

import 'package:hive/hive.dart';

import '../../../../core/errors/cache_exception.dart';
import '../../../../core/utils/id_generator.dart';
import '../../domain/entities/benchmark_item.dart';
import '../../domain/repositories/benchmark_repository.dart';
import '../models/benchmark_model.dart';

/// Hive-backed [BenchmarkRepository]. Each benchmark is stored as its own
/// JSON string, keyed by its `id`, in a plain `Box<dynamic>` — unlike the
/// single-record settings/rate-snapshot boxes, this box naturally holds
/// many records, so per-id keys give create/edit/delete/get-all for free
/// via ordinary box operations, with no extra index to maintain.
class HiveBenchmarkRepository implements BenchmarkRepository {
  HiveBenchmarkRepository(this._box);

  final Box<dynamic> _box;

  @override
  List<BenchmarkItem> getAll() {
    return _box.values
        .map(
          (raw) => benchmarkItemFromJson(
            jsonDecode(raw as String) as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  @override
  List<BenchmarkItem> getActive() =>
      getAll().where((benchmark) => benchmark.isActive).toList();

  @override
  void create({
    required String name,
    required double price,
    required String currencyCode,
  }) {
    final now = DateTime.now();
    _put(
      BenchmarkItem(
        id: IdGenerator.generate(),
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
    final existing = _find(id);
    if (existing == null) return;
    _put(
      existing.copyWith(
        name: name,
        price: price,
        currencyCode: currencyCode,
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  void delete(String id) => _box.delete(id);

  @override
  void activate(String id) => _setActive(id, true);

  @override
  void deactivate(String id) => _setActive(id, false);

  void _setActive(String id, bool isActive) {
    final existing = _find(id);
    if (existing == null) return;
    // isActive alone, deliberately not updatedAt — see BenchmarkItem's own
    // copyWith doc: activation must not disturb §4.2's recency ordering.
    _put(existing.copyWith(isActive: isActive));
  }

  BenchmarkItem? _find(String id) {
    final raw = _box.get(id) as String?;
    if (raw == null) return null;
    return benchmarkItemFromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  void _put(BenchmarkItem item) {
    try {
      _box.put(item.id, jsonEncode(item.toJson()));
    } catch (e) {
      throw CacheException.readWriteFailed(e.toString());
    }
  }
}
