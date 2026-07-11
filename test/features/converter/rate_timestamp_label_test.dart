import 'package:flutter_test/flutter_test.dart';
import 'package:rateify/features/converter/data/models/rate_snapshot_model.dart';
import 'package:rateify/features/converter/presentation/widgets/rate_timestamp_label.dart';

void main() {
  final now = DateTime(2026, 7, 10, 12, 30);

  test(
    'freshRemote shows a relative "Updated X min ago" label (TC-CONV-024)',
    () {
      final snapshot = RateSnapshotModel(
        baseCurrency: 'USD',
        rates: const {'EUR': 0.8},
        fetchedAt: now.subtract(const Duration(minutes: 5)),
        sourceStatus: RateSourceStatus.freshRemote,
      );
      expect(
        rateTimestampLabelText(snapshot: snapshot, now: now),
        'Updated 5 min ago',
      );
    },
  );

  test(
    'cached shows "Offline — using cached rate from [timestamp]" (TC-CONV-025)',
    () {
      final snapshot = RateSnapshotModel(
        baseCurrency: 'USD',
        rates: const {'EUR': 0.8},
        fetchedAt: DateTime(2026, 7, 9, 22, 10),
        sourceStatus: RateSourceStatus.cached,
      );
      expect(
        rateTimestampLabelText(snapshot: snapshot, now: now),
        'Offline — using cached rate from 2026-07-09 22:10',
      );
    },
  );

  test(
    'unavailable shows the explanatory first-fetch message (TC-CONV-026)',
    () {
      final snapshot = RateSnapshotModel.unavailable(
        baseCurrency: 'USD',
        determinedAt: now,
      );
      final text = rateTimestampLabelText(
        snapshot: snapshot,
        errorMessage:
            'You need an internet connection for the first rate fetch.',
        now: now,
      );
      expect(text, contains('internet connection'));
    },
  );

  test('unavailable falls back to a default message when none is supplied', () {
    final snapshot = RateSnapshotModel.unavailable(
      baseCurrency: 'USD',
      determinedAt: now,
    );
    expect(rateTimestampLabelText(snapshot: snapshot, now: now), isNotEmpty);
  });

  test('never hides that cached/offline data is being shown (§20.3)', () {
    final snapshot = RateSnapshotModel(
      baseCurrency: 'USD',
      rates: const {'EUR': 0.8},
      fetchedAt: now.subtract(const Duration(hours: 2)),
      sourceStatus: RateSourceStatus.cached,
    );
    final text = rateTimestampLabelText(snapshot: snapshot, now: now);
    expect(text.toLowerCase(), contains('offline'));
    expect(text.toLowerCase(), contains('cached'));
  });
}
