import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/alerts/presentation/pages/alert_page.dart';
import 'features/converter/presentation/pages/converter_page.dart';
import 'features/settings/presentation/pages/settings_page.dart';
import 'features/trips/presentation/pages/trip_list_page.dart';

/// Root widget: sets up [MaterialApp] with the app theme and light/dark/system
/// mode support (§8.3). Actual theme-mode persistence is wired up once the
/// settings feature exists (Batch 01) — for now this always follows the
/// system setting, which is the spec's stated default.
class RateifyApp extends StatelessWidget {
  const RateifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rateify',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      // Explicit even though it matches MaterialApp's own default — §8.3
      // states "system" is the spec'd default, not just an implementation detail.
      // ignore: avoid_redundant_argument_values
      themeMode: ThemeMode.system,
      home: const RootShell(),
    );
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
