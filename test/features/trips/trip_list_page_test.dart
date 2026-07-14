import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rateify/features/converter/presentation/providers/converter_providers.dart';
import 'package:rateify/features/settings/presentation/providers/settings_providers.dart';
import 'package:rateify/features/trips/domain/entities/trip.dart';
import 'package:rateify/features/trips/presentation/pages/trip_list_page.dart';
import 'package:rateify/features/trips/presentation/providers/trip_providers.dart';

import '../../test_helpers/fake_exchange_rate_repository.dart';
import '../../test_helpers/fake_settings_repository.dart';
import '../../test_helpers/fake_trip_repository.dart';

void main() {
  Trip trip({
    required String id,
    required String name,
    bool isArchived = false,
  }) {
    final now = DateTime(2026, 7);
    return Trip(
      id: id,
      name: name,
      localCurrency: 'JPY',
      homeCurrency: 'USD',
      totalBudget: 100000,
      isArchived: isArchived,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<void> pumpTripListPage(
    WidgetTester tester, {
    List<Trip>? initialTrips,
  }) async {
    final container = ProviderContainer(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(FakeSettingsRepository()),
        exchangeRateRepositoryProvider.overrideWithValue(
          FakeExchangeRateRepository(),
        ),
        tripRepositoryProvider.overrideWithValue(
          FakeTripRepository(initialTrips: initialTrips),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: TripListPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('§5.5 empty states', () {
    testWidgets(
      'TC-TRIP-012: no trips exist -> the "no trip yet" empty state is shown',
      (tester) async {
        await pumpTripListPage(tester, initialTrips: []);

        expect(find.text('Belum ada trip.'), findsOneWidget);
        expect(
          find.text(
            'Buat trip pertama untuk mulai mengontrol budget perjalanan.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'TC-TRIP-012: archived-only trips are treated the same as no trips',
      (tester) async {
        await pumpTripListPage(
          tester,
          initialTrips: [trip(id: '1', name: 'Old Trip', isArchived: true)],
        );

        expect(find.text('Belum ada trip.'), findsOneWidget);
        expect(find.text('Old Trip'), findsNothing);
      },
    );

    testWidgets('a trip exists -> no empty state text, trip is listed', (
      tester,
    ) async {
      await pumpTripListPage(
        tester,
        initialTrips: [trip(id: '1', name: 'Tokyo Trip')],
      );

      expect(find.text('Belum ada trip.'), findsNothing);
      expect(find.text('Tokyo Trip'), findsOneWidget);
    });
  });

  testWidgets('creating a trip via the form sheet adds it to the list', (
    tester,
  ) async {
    await pumpTripListPage(tester, initialTrips: []);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Trip name'),
      'Bali Trip',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Total budget'),
      '5000',
    );
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(find.text('Belum ada trip.'), findsNothing);
    expect(find.text('Bali Trip'), findsOneWidget);
  });

  testWidgets(
    'TC-TRIP-014: deleting a trip from the list requires confirmation before it disappears',
    (tester) async {
      await pumpTripListPage(
        tester,
        initialTrips: [trip(id: '1', name: 'Tokyo Trip')],
      );

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Confirmation dialog is shown; the trip is still in the list.
      expect(find.text('Delete trip?'), findsOneWidget);
      expect(find.text('Tokyo Trip'), findsWidgets);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Tokyo Trip'), findsOneWidget);

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();

      expect(find.text('Belum ada trip.'), findsOneWidget);
    },
  );

  testWidgets('archiving a trip removes it from the active list', (
    tester,
  ) async {
    await pumpTripListPage(
      tester,
      initialTrips: [trip(id: '1', name: 'Tokyo Trip')],
    );

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Archive'));
    await tester.pumpAndSettle();

    expect(find.text('Belum ada trip.'), findsOneWidget);
  });
}
