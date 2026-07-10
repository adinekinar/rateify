import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rateify/core/theme/app_theme.dart';
import 'package:rateify/floating_nav_bar.dart';

void main() {
  const items = [
    FloatingNavItem(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      label: 'Home',
    ),
    FloatingNavItem(
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      label: 'Settings',
    ),
  ];

  Widget buildBar({
    required int selectedIndex,
    required ValueChanged<int> onSelected,
    bool dark = false,
  }) {
    return MaterialApp(
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      home: Scaffold(
        bottomNavigationBar: FloatingNavBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onSelected,
          items: items,
        ),
      ),
    );
  }

  testWidgets('renders all item labels and reports taps via callback', (
    tester,
  ) async {
    int? tappedIndex;
    await tester.pumpWidget(
      buildBar(selectedIndex: 0, onSelected: (index) => tappedIndex = index),
    );

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    await tester.tap(find.text('Settings'));
    expect(tappedIndex, 1);
  });

  testWidgets('uses no BackdropFilter (no blur/frosted-glass effect)', (
    tester,
  ) async {
    await tester.pumpWidget(buildBar(selectedIndex: 0, onSelected: (_) {}));

    expect(find.byType(BackdropFilter), findsNothing);
  });

  testWidgets('renders correctly in dark mode with a non-null surface color', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildBar(selectedIndex: 1, onSelected: (_) {}, dark: true),
    );

    final container = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(FloatingNavBar),
            matching: find.byType(Container),
          )
          .first,
    );
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.color, isNotNull);
  });

  testWidgets(
    'sliding indicator animation uses easeOutCubic (no bounce/spring curve)',
    (tester) async {
      await tester.pumpWidget(buildBar(selectedIndex: 0, onSelected: (_) {}));

      final animatedPositioned = tester.widget<AnimatedPositioned>(
        find.byType(AnimatedPositioned),
      );
      expect(animatedPositioned.curve, Curves.easeOutCubic);
    },
  );
}
