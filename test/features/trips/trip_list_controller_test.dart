import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rateify/core/formatting/number_formatter.dart';
import 'package:rateify/features/settings/domain/entities/app_settings.dart';
import 'package:rateify/features/settings/presentation/providers/settings_providers.dart';
import 'package:rateify/features/trips/presentation/providers/trip_providers.dart';

import '../../test_helpers/fake_settings_repository.dart';
import '../../test_helpers/fake_trip_repository.dart';

void main() {
  ProviderContainer buildContainer({String homeCurrency = 'USD'}) {
    final settings = AppSettings.initial(
      numberFormatPreference: NumberFormatPreference.commaDecimalDot,
    ).copyWith(homeCurrency: homeCurrency);

    final container = ProviderContainer(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(
          FakeSettingsRepository(initialSettings: settings),
        ),
        tripRepositoryProvider.overrideWithValue(FakeTripRepository()),
      ],
    );
    return container;
  }

  test(
    'TC-TRIP-009: changing the global home currency after trip creation '
    'leaves the existing trip\'s homeCurrency snapshot unchanged',
    () {
      final container = buildContainer();
      addTearDown(container.dispose);

      container
          .read(tripListControllerProvider.notifier)
          .createTrip(name: 'Tokyo Trip', localCurrency: 'JPY', totalBudget: 100000);
      final createdTrip = container.read(tripListControllerProvider).single;
      expect(createdTrip.homeCurrency, 'USD');

      // The user now changes their global home currency in Settings.
      container
          .read(appSettingsProvider.notifier)
          .updateHomeCurrency('EUR');
      expect(container.read(appSettingsProvider).homeCurrency, 'EUR');

      // The existing trip must be completely unaffected.
      final tripAfterGlobalChange = container
          .read(tripListControllerProvider)
          .single;
      expect(tripAfterGlobalChange.id, createdTrip.id);
      expect(tripAfterGlobalChange.homeCurrency, 'USD');
    },
  );

  test(
    'TC-TRIP-011: a new trip created after the global home currency change '
    'snapshots the *new* global home currency',
    () {
      final container = buildContainer();
      addTearDown(container.dispose);

      container
          .read(tripListControllerProvider.notifier)
          .createTrip(
            name: 'Trip Before',
            localCurrency: 'JPY',
            totalBudget: 100000,
          );

      container.read(appSettingsProvider.notifier).updateHomeCurrency('EUR');

      container
          .read(tripListControllerProvider.notifier)
          .createTrip(
            name: 'Trip After',
            localCurrency: 'THB',
            totalBudget: 5000,
          );

      final trips = container.read(tripListControllerProvider);
      final tripBefore = trips.firstWhere((t) => t.name == 'Trip Before');
      final tripAfter = trips.firstWhere((t) => t.name == 'Trip After');

      expect(tripBefore.homeCurrency, 'USD');
      expect(tripAfter.homeCurrency, 'EUR');
    },
  );

  test('editTrip never changes homeCurrency, even implicitly', () {
    final container = buildContainer();
    addTearDown(container.dispose);

    container
        .read(tripListControllerProvider.notifier)
        .createTrip(name: 'Trip', localCurrency: 'JPY', totalBudget: 1000);
    final created = container.read(tripListControllerProvider).single;

    container.read(appSettingsProvider.notifier).updateHomeCurrency('EUR');
    container
        .read(tripListControllerProvider.notifier)
        .editTrip(
          id: created.id,
          name: 'Trip Renamed',
          localCurrency: 'THB',
          totalBudget: 2000,
        );

    final edited = container.read(tripListControllerProvider).single;
    expect(edited.name, 'Trip Renamed');
    expect(edited.localCurrency, 'THB');
    expect(edited.homeCurrency, 'USD');
  });

  test('archiveTrip and deleteTrip update the list state', () {
    final container = buildContainer();
    addTearDown(container.dispose);

    container
        .read(tripListControllerProvider.notifier)
        .createTrip(name: 'Trip', localCurrency: 'JPY', totalBudget: 1000);
    final trip = container.read(tripListControllerProvider).single;

    container.read(tripListControllerProvider.notifier).archiveTrip(trip.id);
    expect(container.read(tripListControllerProvider).single.isArchived, isTrue);

    container.read(tripListControllerProvider.notifier).deleteTrip(trip.id);
    expect(container.read(tripListControllerProvider), isEmpty);
  });
}
