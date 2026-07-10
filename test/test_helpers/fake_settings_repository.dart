import 'package:rateify/core/formatting/number_formatter.dart';
import 'package:rateify/features/settings/domain/entities/app_settings.dart';
import 'package:rateify/features/settings/domain/repositories/settings_repository.dart';

/// In-memory [SettingsRepository] fake for widget tests that don't care
/// about actual Hive persistence — only about provider wiring/behavior.
class FakeSettingsRepository implements SettingsRepository {
  FakeSettingsRepository({
    AppSettings? initialSettings,
    bool onboardingCompleted = true,
  }) : _settings =
           initialSettings ??
           AppSettings.initial(
             numberFormatPreference: NumberFormatPreference.commaDecimalDot,
           ),
       _onboardingCompleted = onboardingCompleted;

  AppSettings _settings;
  bool _onboardingCompleted;

  @override
  AppSettings loadSettings() => _settings;

  @override
  void saveSettings(AppSettings settings) => _settings = settings;

  @override
  bool isOnboardingCompleted() => _onboardingCompleted;

  @override
  void completeOnboarding() => _onboardingCompleted = true;
}
