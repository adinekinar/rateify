import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rateify/features/converter/presentation/providers/converter_providers.dart';
import 'package:rateify/features/settings/presentation/providers/settings_providers.dart';
import 'package:rateify/features/trips/domain/entities/trip.dart';
import 'package:rateify/features/trips/domain/entities/trip_expense.dart';
import 'package:rateify/features/trips/presentation/pages/trip_detail_page.dart';
import 'package:rateify/features/trips/presentation/providers/trip_providers.dart';

import '../../test_helpers/fake_exchange_rate_repository.dart';
import '../../test_helpers/fake_settings_repository.dart';
import '../../test_helpers/fake_trip_repository.dart';

void main() {
  Trip trip({
    String id = 'trip-1',
    String name = 'Tokyo Trip',
    double totalBudget = 100000,
  }) {
    final now = DateTime(2026, 7);
    return Trip(
      id: id,
      name: name,
      localCurrency: 'JPY',
      homeCurrency: 'USD',
      totalBudget: totalBudget,
      isArchived: false,
      createdAt: now,
      updatedAt: now,
    );
  }

  TripExpense expense({
    String id = 'expense-1',
    String tripId = 'trip-1',
    double amountLocal = 1000,
  }) {
    final now = DateTime(2026, 7);
    return TripExpense(
      id: id,
      tripId: tripId,
      title: 'Ramen',
      amountLocal: amountLocal,
      category: ExpenseCategory.food,
      spentAt: now,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<ProviderContainer> pumpTripDetailPage(
    WidgetTester tester, {
    required Trip forTrip,
    List<TripExpense>? initialExpenses,
  }) async {
    final container = ProviderContainer(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(FakeSettingsRepository()),
        exchangeRateRepositoryProvider.overrideWithValue(
          FakeExchangeRateRepository(),
        ),
        tripRepositoryProvider.overrideWithValue(
          FakeTripRepository(
            initialTrips: [forTrip],
            initialExpenses: initialExpenses,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: TripDetailPage(tripId: forTrip.id)),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets(
    'TC-TRIP-013: trip exists with zero expenses -> "no expenses yet" empty state',
    (tester) async {
      await pumpTripDetailPage(tester, forTrip: trip());

      expect(find.text('Belum ada pengeluaran.'), findsOneWidget);
      expect(
        find.text('Tambahkan expense pertama untuk melihat progress budget.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('adding an expense removes the empty state and shows it in the list', (
    tester,
  ) async {
    await pumpTripDetailPage(tester, forTrip: trip());

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Title'), 'Ramen');
    await tester.enterText(
      find.widgetWithText(TextField, 'Amount (JPY)'),
      '1200',
    );
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(find.text('Belum ada pengeluaran.'), findsNothing);
    expect(find.text('Ramen'), findsOneWidget);
  });

  testWidgets(
    'TC-TRIP-014: deleting an expense requires confirmation before it disappears',
    (tester) async {
      await pumpTripDetailPage(
        tester,
        forTrip: trip(),
        initialExpenses: [expense()],
      );

      expect(find.text('Ramen'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.text('Delete expense?'), findsOneWidget);
      expect(find.text('Ramen'), findsWidgets);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Ramen'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Belum ada pengeluaran.'), findsOneWidget);
    },
  );

  testWidgets(
    'TC-TRIP-014: deleting the trip itself requires confirmation and pops the page',
    (tester) async {
      await pumpTripDetailPage(tester, forTrip: trip());

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete trip'));
      await tester.pumpAndSettle();

      expect(find.text('Delete trip?'), findsOneWidget);

      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();

      // The detail page (with its "Tokyo Trip" title) is gone.
      expect(find.byType(TripDetailPage), findsNothing);
    },
  );

  testWidgets('progress bar reflects danger state when over budget', (
    tester,
  ) async {
    await pumpTripDetailPage(
      tester,
      forTrip: trip(totalBudget: 1000),
      initialExpenses: [expense(amountLocal: 1500)],
    );

    expect(find.textContaining('Over budget by'), findsOneWidget);
    final progressBar = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect((progressBar.valueColor as AlwaysStoppedAnimation<Color>).value, isNotNull);
  });
}
