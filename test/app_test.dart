import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rateify/app.dart';

void main() {
  testWidgets(
    'RateifyApp shows all 4 bottom nav tabs and starts on Converter',
    (tester) async {
      await tester.pumpWidget(const ProviderScope(child: RateifyApp()));

      expect(find.text('Converter'), findsWidgets);
      expect(find.text('Trip'), findsWidgets);
      expect(find.text('Alerts'), findsWidgets);
      expect(find.text('Settings'), findsWidgets);
    },
  );

  testWidgets('tapping a nav destination switches the selected index', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: RateifyApp()));

    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      0,
    );

    await tester.tap(find.widgetWithText(NavigationDestination, 'Settings'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      3,
    );
  });
}
