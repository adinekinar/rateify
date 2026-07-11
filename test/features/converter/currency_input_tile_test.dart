import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rateify/core/constants/currency_reference.dart';
import 'package:rateify/features/converter/presentation/widgets/currency_input_tile.dart';

void main() {
  const usd = CurrencyInfo(code: 'USD', displayName: 'US Dollar');

  Widget buildTile({
    required bool isActive,
    String displayAmount = '1,234.00',
  }) {
    return MaterialApp(
      home: Scaffold(
        body: CurrencyInputTile(
          currencyInfo: usd,
          displayAmount: displayAmount,
          isActive: isActive,
          onTap: () {},
          onLongPress: () {},
        ),
      ),
    );
  }

  group('§16.1 compact inactive tile rule', () {
    testWidgets(
      'shows currency code, label, and amount regardless of active state',
      (tester) async {
        await tester.pumpWidget(buildTile(isActive: false));
        expect(find.text('USD'), findsOneWidget);
        expect(find.text('US Dollar'), findsOneWidget);
        expect(find.text('1,234.00'), findsOneWidget);
      },
    );

    testWidgets(
      'the inactive tile is meaningfully shorter than the active tile',
      (tester) async {
        await tester.pumpWidget(buildTile(isActive: true));
        final activeHeight = tester
            .getSize(find.byType(CurrencyInputTile))
            .height;

        await tester.pumpWidget(buildTile(isActive: false));
        final inactiveHeight = tester
            .getSize(find.byType(CurrencyInputTile))
            .height;

        expect(
          inactiveHeight,
          lessThan(activeHeight * 0.7),
          reason:
              'compact inactive tile must be noticeably shorter than the active tile',
        );
      },
    );

    testWidgets(
      'active tile keeps its comfortable stacked layout (code+label above amount)',
      (tester) async {
        await tester.pumpWidget(buildTile(isActive: true));

        final codeCenter = tester.getCenter(find.text('USD'));
        final amountCenter = tester.getCenter(find.text('1,234.00'));

        // Stacked layout: the amount is below the code/label row, not beside it.
        expect(amountCenter.dy, greaterThan(codeCenter.dy));
      },
    );

    testWidgets(
      'inactive tile uses a single row (code+label beside the amount, not above)',
      (tester) async {
        await tester.pumpWidget(buildTile(isActive: false));

        final codeCenter = tester.getCenter(find.text('USD'));
        final amountCenter = tester.getCenter(find.text('1,234.00'));

        // Single-row layout: code and amount are roughly on the same
        // horizontal line, with the amount to the right.
        expect((amountCenter.dy - codeCenter.dy).abs(), lessThan(4));
        expect(amountCenter.dx, greaterThan(codeCenter.dx));
      },
    );

    testWidgets('active tile shows a visually distinct border/highlight', (
      tester,
    ) async {
      await tester.pumpWidget(buildTile(isActive: true));
      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.border, isNotNull);
    });
  });
}
