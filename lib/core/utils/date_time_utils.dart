/// Small, generic `DateTime` helpers shared across features.
///
/// Feature-specific formatting (e.g. the converter's "Updated 5 min ago"
/// label from §3.7) belongs in that feature's own presentation layer, not
/// here — this file only holds primitives every feature can reuse.
abstract final class DateTimeUtils {
  /// Whether [dateTime] is older than [threshold] relative to [now]
  /// (defaults to `DateTime.now()`).
  ///
  /// Used by the converter's staleness check (§9.3) against
  /// `CacheConstants.staleRateThreshold`.
  static bool isOlderThan(
    DateTime dateTime,
    Duration threshold, {
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    return reference.difference(dateTime) > threshold;
  }
}
