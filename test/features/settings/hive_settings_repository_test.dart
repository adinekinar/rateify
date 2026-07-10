import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:rateify/core/formatting/number_formatter.dart';
import 'package:rateify/features/settings/data/repositories/settings_repository_impl.dart';

void main() {
  late Directory tempDir;
  late Box<dynamic> box;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('rateify_settings_test_');
    Hive.init(tempDir.path);
    box = await Hive.openBox<dynamic>('settings_test_box');
  });

  tearDown(() async {
    await box.deleteFromDisk();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test(
    'first-ever load resolves the device locale once and persists a bootstrap AppSettings',
    () {
      final repository = HiveSettingsRepository(
        box,
        deviceLocaleNameProvider: () => 'id_ID',
      );

      final settings = repository.loadSettings();

      expect(settings.homeCurrency, 'USD');
      expect(
        settings.numberFormatPreference,
        NumberFormatPreference.dotDecimalComma,
      );
      expect(settings.selectedConverterCurrencies, ['USD', 'EUR']);
    },
  );

  test(
    'subsequent loads do NOT re-resolve the locale, even if it changes (§8.4 TC-SET-006)',
    () {
      final firstRun = HiveSettingsRepository(
        box,
        deviceLocaleNameProvider: () => 'en_US',
      );
      final firstSettings = firstRun.loadSettings();
      expect(
        firstSettings.numberFormatPreference,
        NumberFormatPreference.commaDecimalDot,
      );

      // Simulate a relaunch with a *different* device locale and a fresh
      // repository instance pointed at the same (already-populated) box.
      final secondRun = HiveSettingsRepository(
        box,
        deviceLocaleNameProvider: () => 'id_ID',
      );
      final secondSettings = secondRun.loadSettings();

      expect(
        secondSettings.numberFormatPreference,
        NumberFormatPreference.commaDecimalDot,
      );
    },
  );

  test('saveSettings then loadSettings round-trips every field', () {
    final repository = HiveSettingsRepository(
      box,
      deviceLocaleNameProvider: () => 'en_US',
    );
    final initial = repository.loadSettings();

    final updated = initial.copyWith(
      homeCurrency: 'IDR',
      numberFormatPreference: NumberFormatPreference.dotDecimalComma,
      alertCheckFrequency: const Duration(hours: 12),
      selectedConverterCurrencies: ['IDR', 'USD', 'JPY'],
    );
    repository.saveSettings(updated);

    // Fresh repository instance over the same box — proves it was actually
    // persisted, not just held in memory.
    final reloaded = HiveSettingsRepository(box).loadSettings();

    expect(reloaded.homeCurrency, 'IDR');
    expect(
      reloaded.numberFormatPreference,
      NumberFormatPreference.dotDecimalComma,
    );
    expect(reloaded.alertCheckFrequency, const Duration(hours: 12));
    expect(reloaded.selectedConverterCurrencies, ['IDR', 'USD', 'JPY']);
  });

  test(
    'onboarding-completed flag defaults false and persists once completed',
    () {
      final repository = HiveSettingsRepository(
        box,
        deviceLocaleNameProvider: () => 'en_US',
      );
      expect(repository.isOnboardingCompleted(), isFalse);

      repository.completeOnboarding();

      expect(repository.isOnboardingCompleted(), isTrue);
      expect(HiveSettingsRepository(box).isOnboardingCompleted(), isTrue);
    },
  );
}
