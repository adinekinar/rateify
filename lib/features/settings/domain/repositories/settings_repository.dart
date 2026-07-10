import '../entities/app_settings.dart';

/// All settings persistence goes through this repository — the presentation
/// layer never touches Hive directly (§18.8).
///
/// Methods are synchronous: by the time any provider reads this repository,
/// `main()` has already awaited opening the underlying Hive box, and Hive
/// box reads/writes on an already-open box are themselves synchronous.
abstract class SettingsRepository {
  /// Loads the persisted settings, or — on the very first ever call (no
  /// persisted record yet) — resolves the device locale once (§8.4),
  /// persists a bootstrap [AppSettings], and returns that.
  AppSettings loadSettings();

  void saveSettings(AppSettings settings);

  bool isOnboardingCompleted();

  void completeOnboarding();
}
