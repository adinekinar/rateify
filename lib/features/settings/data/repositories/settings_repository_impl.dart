import 'dart:convert';
import 'dart:ui' as ui;

import 'package:hive/hive.dart';

import '../../../../core/formatting/number_formatter.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../models/app_settings_model.dart';

/// Hive-backed [SettingsRepository].
///
/// Storage choice: rather than generating a Hive `TypeAdapter` (which would
/// need `hive_generator` + a build_runner step just for one small, stable
/// entity), [AppSettings] is stored as a single JSON string under one key in
/// a plain `Box<dynamic>`, with a second key for the onboarding-completed
/// flag. This keeps the batch self-contained with no codegen dependency;
/// later batches with larger/more numerous entities (rates, trips, etc.)
/// are free to use generated adapters instead.
class HiveSettingsRepository implements SettingsRepository {
  HiveSettingsRepository(
    this._box, {
    String Function()? deviceLocaleNameProvider,
  }) : _deviceLocaleNameProvider =
           deviceLocaleNameProvider ?? _defaultDeviceLocaleName;

  static const _settingsKey = 'app_settings';
  static const _onboardingCompletedKey = 'onboarding_completed';

  final Box<dynamic> _box;

  /// Injectable so tests can simulate a specific device locale without
  /// depending on `dart:ui`'s `PlatformDispatcher`.
  final String Function() _deviceLocaleNameProvider;

  @override
  AppSettings loadSettings() {
    final raw = _box.get(_settingsKey) as String?;
    if (raw == null) {
      // First ever launch — no persisted record yet. Resolve the device
      // locale exactly once (§8.4) and persist the bootstrap settings.
      final resolvedFormat = resolveNumberFormatPreferenceFromLocale(
        _deviceLocaleNameProvider(),
      );
      final initial = AppSettings.initial(
        numberFormatPreference: resolvedFormat,
      );
      saveSettings(initial);
      return initial;
    }
    return appSettingsFromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  void saveSettings(AppSettings settings) {
    _box.put(_settingsKey, jsonEncode(settings.toJson()));
  }

  @override
  bool isOnboardingCompleted() =>
      (_box.get(_onboardingCompletedKey) as bool?) ?? false;

  @override
  void completeOnboarding() {
    _box.put(_onboardingCompletedKey, true);
  }

  static String _defaultDeviceLocaleName() {
    final locale = ui.PlatformDispatcher.instance.locale;
    final country = locale.countryCode;
    return (country == null || country.isEmpty)
        ? locale.languageCode
        : '${locale.languageCode}_$country';
  }
}
