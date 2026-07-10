import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/alerts/presentation/pages/alert_page.dart';
import 'features/converter/presentation/pages/converter_page.dart';
import 'features/settings/domain/entities/app_settings.dart';
import 'features/settings/presentation/pages/onboarding_page.dart';
import 'features/settings/presentation/pages/settings_page.dart';
import 'features/settings/presentation/providers/settings_providers.dart';
import 'features/trips/presentation/pages/trip_list_page.dart';

/// Root widget: sets up [MaterialApp] with the app theme and light/dark/system
/// mode support (§8.3), driven by the persisted [AppSettings.themeMode].
class RateifyApp extends ConsumerWidget {
  const RateifyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(
      appSettingsProvider.select((settings) => settings.themeMode),
    );

    return MaterialApp(
      title: 'Rateify',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _toFlutterThemeMode(themeMode),
      home: const AppStartupGate(),
    );
  }

  ThemeMode _toFlutterThemeMode(AppThemeMode mode) => switch (mode) {
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.dark => ThemeMode.dark,
    AppThemeMode.system => ThemeMode.system,
  };
}

/// Shows onboarding until it's completed (§8.2), then the main navigation
/// shell — a one-way gate, not a navigation stack.
class AppStartupGate extends ConsumerWidget {
  const AppStartupGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingCompleted = ref.watch(onboardingCompletedProvider);
    return onboardingCompleted ? const RootShell() : const OnboardingPage();
  }
}

/// Bottom navigation shell with the 4 main tabs (§16.3): Converter, Trip,
/// Alerts, Settings. Rate History is intentionally not a tab — it's accessed
/// from currency tile detail per §7.4.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _selectedIndex = 0;

  static const List<Widget> _tabs = [
    ConverterPage(),
    TripListPage(),
    AlertPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.currency_exchange_outlined),
            selectedIcon: Icon(Icons.currency_exchange),
            label: 'Converter',
          ),
          NavigationDestination(
            icon: Icon(Icons.card_travel_outlined),
            selectedIcon: Icon(Icons.card_travel),
            label: 'Trip',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
