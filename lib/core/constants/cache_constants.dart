/// Local cache (Hive) related constants (§9.2, §9.3).
abstract final class CacheConstants {
  /// §9.3 Rate Freshness Rule — default value added in review pass.
  ///
  /// Conversion uses the in-memory rate snapshot without refetching as long
  /// as it is younger than this threshold. This is a constant, not a
  /// user-facing setting, for MVP.
  static const Duration staleRateThreshold = Duration(minutes: 15);

  static const String rateSnapshotBoxName = 'rate_snapshot_box';
  static const String rateHistoryBoxName = 'rate_history_box';
  static const String benchmarkBoxName = 'benchmark_box';
  static const String tripBoxName = 'trip_box';
  static const String tripExpenseBoxName = 'trip_expense_box';
  static const String alertBoxName = 'alert_box';
  static const String alertTriggerHistoryBoxName = 'alert_trigger_history_box';
  static const String appSettingsBoxName = 'app_settings_box';
}
