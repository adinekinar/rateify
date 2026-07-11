import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:rateify/features/benchmarks/data/repositories/benchmark_repository_impl.dart';

void main() {
  late Directory tempDir;
  late Box<dynamic> box;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('rateify_benchmark_test_');
    Hive.init(tempDir.path);
    box = await Hive.openBox<dynamic>('benchmark_test_box');
  });

  tearDown(() async {
    await box.deleteFromDisk();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test(
    'create persists a benchmark with correct name/price/currency/timestamps (TC-RPM-001)',
    () {
      final repository = HiveBenchmarkRepository(box);

      repository.create(name: 'Nasi Padang', price: 20000, currencyCode: 'IDR');

      final all = repository.getAll();
      expect(all, hasLength(1));
      final created = all.single;
      expect(created.name, 'Nasi Padang');
      expect(created.price, 20000);
      expect(created.currencyCode, 'IDR');
      expect(created.isActive, isTrue);
      expect(created.createdAt, created.updatedAt);

      // Fresh repository instance over the same box proves it was actually
      // persisted, not just held in memory.
      final reloaded = HiveBenchmarkRepository(box).getAll().single;
      expect(reloaded.name, 'Nasi Padang');
      expect(reloaded.price, 20000);
      expect(reloaded.currencyCode, 'IDR');
    },
  );

  test(
    'edit updates fields and bumps updatedAt, without disturbing createdAt (TC-RPM-002)',
    () async {
      final repository = HiveBenchmarkRepository(box);
      repository.create(name: 'Onigiri', price: 130, currencyCode: 'JPY');
      final original = repository.getAll().single;

      // Guarantee a measurable timestamp difference on fast test runs.
      await Future<void>.delayed(const Duration(milliseconds: 5));

      repository.edit(
        id: original.id,
        name: 'Onigiri Tuna',
        price: 150,
        currencyCode: 'JPY',
      );

      final edited = repository.getAll().single;
      expect(edited.name, 'Onigiri Tuna');
      expect(edited.price, 150);
      expect(edited.createdAt, original.createdAt);
      expect(edited.updatedAt.isAfter(original.updatedAt), isTrue);
    },
  );

  test(
    'delete removes the benchmark, with no orphan reference left behind (TC-RPM-003)',
    () {
      final repository = HiveBenchmarkRepository(box);
      repository.create(name: 'Coffee', price: 4, currencyCode: 'USD');
      final created = repository.getAll().single;

      repository.delete(created.id);

      expect(repository.getAll(), isEmpty);
      expect(HiveBenchmarkRepository(box).getAll(), isEmpty);
    },
  );

  test(
    'activate/deactivate toggles isActive and getActive() reflects it immediately (TC-RPM-004)',
    () {
      final repository = HiveBenchmarkRepository(box);
      repository.create(name: 'Coffee', price: 4, currencyCode: 'USD');
      final created = repository.getAll().single;
      expect(created.isActive, isTrue);

      repository.deactivate(created.id);
      expect(repository.getActive(), isEmpty);
      expect(repository.getAll().single.isActive, isFalse);

      repository.activate(created.id);
      expect(repository.getActive(), hasLength(1));
      expect(repository.getAll().single.isActive, isTrue);
    },
  );

  test(
    'activate/deactivate does not bump updatedAt (§4.2 ordering must not shift on toggle alone)',
    () async {
      final repository = HiveBenchmarkRepository(box);
      repository.create(name: 'Coffee', price: 4, currencyCode: 'USD');
      final original = repository.getAll().single;

      await Future<void>.delayed(const Duration(milliseconds: 5));
      repository.deactivate(original.id);

      final afterToggle = repository.getAll().single;
      expect(afterToggle.updatedAt, original.updatedAt);
    },
  );
}
