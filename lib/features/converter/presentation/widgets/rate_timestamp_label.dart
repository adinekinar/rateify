import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/models/rate_snapshot_model.dart';

/// Pure text computation for the three §3.7 states, independently
/// unit-testable without pumping a widget:
///
/// - `freshRemote` → relative time ("Updated 5 min ago")
/// - `cached` → "Offline — using cached rate from [timestamp]" (§20.3 — never
///   hides that cached data is being shown)
/// - `unavailable` → an explanatory message about needing a first fetch
String rateTimestampLabelText({
  required RateSnapshotModel snapshot,
  String? errorMessage,
  DateTime? now,
}) {
  switch (snapshot.sourceStatus) {
    case RateSourceStatus.freshRemote:
      return 'Updated ${_relativeTime(snapshot.fetchedAt, now)}';
    case RateSourceStatus.cached:
      return 'Offline — using cached rate from ${_absoluteTime(snapshot.fetchedAt)}';
    case RateSourceStatus.unavailable:
      return errorMessage ??
          'You need an internet connection for the first rate fetch.';
  }
}

String _relativeTime(DateTime fetchedAt, DateTime? now) {
  final reference = now ?? DateTime.now();
  final diff = reference.difference(fetchedAt);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} hr ago';
  return 'on ${_absoluteTime(fetchedAt)}';
}

String _absoluteTime(DateTime dateTime) {
  final y = dateTime.year.toString().padLeft(4, '0');
  final mo = dateTime.month.toString().padLeft(2, '0');
  final d = dateTime.day.toString().padLeft(2, '0');
  final h = dateTime.hour.toString().padLeft(2, '0');
  final mi = dateTime.minute.toString().padLeft(2, '0');
  return '$y-$mo-$d $h:$mi';
}

/// §3.7 Rate Timestamp — always visible, never hides that cached/offline
/// data is in use (§20.3).
class RateTimestampLabel extends StatelessWidget {
  const RateTimestampLabel({
    super.key,
    required this.snapshot,
    this.errorMessage,
    this.now,
  });

  final RateSnapshotModel snapshot;
  final String? errorMessage;

  /// Injectable "current time" for deterministic relative-time tests.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUnavailable = snapshot.sourceStatus == RateSourceStatus.unavailable;

    return Text(
      rateTimestampLabelText(
        snapshot: snapshot,
        errorMessage: errorMessage,
        now: now,
      ),
      style: AppTypography.caption(
        color: isUnavailable
            ? AppColors.danger
            : theme.colorScheme.onSurface.withValues(alpha: 0.6),
      ),
      textAlign: TextAlign.center,
    );
  }
}
