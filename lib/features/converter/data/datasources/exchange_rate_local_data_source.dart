import 'dart:convert';

import 'package:hive/hive.dart';

import '../../../../core/errors/cache_exception.dart';
import '../models/rate_snapshot_model.dart';

/// Hive-backed read/write of the cached rate snapshot (§9.2).
///
/// Same storage choice as the Batch 01 settings repository: a single JSON
/// string under one key in a plain `Box<dynamic>`, rather than a generated
/// Hive `TypeAdapter` — there's only ever one snapshot to store, so codegen
/// would add a build step for no real benefit.
class ExchangeRateLocalDataSource {
  ExchangeRateLocalDataSource(this._box);

  static const _snapshotKey = 'rate_snapshot';

  final Box<dynamic> _box;

  /// Returns the cached snapshot, or `null` if none has ever been written.
  /// Corrupted/unreadable cache data is treated the same as "no cache" —
  /// this never throws out to the repository.
  RateSnapshotModel? readSnapshot() {
    final raw = _box.get(_snapshotKey) as String?;
    if (raw == null) return null;
    try {
      return RateSnapshotModel.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  void writeSnapshot(RateSnapshotModel snapshot) {
    try {
      _box.put(_snapshotKey, jsonEncode(snapshot.toJson()));
    } catch (e) {
      throw CacheException.readWriteFailed(e.toString());
    }
  }
}
