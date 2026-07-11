import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/currency_reference.dart';
import '../../../../core/formatting/number_formatter.dart';
import '../../../benchmarks/presentation/pages/benchmark_page.dart';
import '../../domain/entities/app_settings.dart';
import '../providers/settings_providers.dart';
import '../widgets/currency_picker_sheet.dart';

/// Real Settings screen (§8). "Manage benchmarks" is wired in as of Batch
/// 04, now that the benchmarks feature exists — "Refresh rates now" and
/// "Manage cached rates" (§8.1) remain deliberately absent until their own
/// features exist.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  Future<void> _pickHomeCurrency(
    BuildContext context,
    WidgetRef ref,
    String currentCode,
  ) async {
    final picked = await CurrencyPickerSheet.show(
      context,
      selectedCode: currentCode,
    );
    if (picked != null) {
      ref.read(appSettingsProvider.notifier).updateHomeCurrency(picked);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final homeCurrencyInfo = CurrencyReference.all.firstWhere(
      (currency) => currency.code == settings.homeCurrency,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Home currency'),
            subtitle: Text(
              '${homeCurrencyInfo.code} — ${homeCurrencyInfo.displayName}',
            ),
            onTap: () => _pickHomeCurrency(context, ref, settings.homeCurrency),
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text('Theme mode'),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SegmentedButton<AppThemeMode>(
                segments: const [
                  ButtonSegment(
                    value: AppThemeMode.light,
                    label: Text('Light'),
                  ),
                  ButtonSegment(value: AppThemeMode.dark, label: Text('Dark')),
                  ButtonSegment(
                    value: AppThemeMode.system,
                    label: Text('System'),
                  ),
                ],
                selected: {settings.themeMode},
                onSelectionChanged: (selection) {
                  ref
                      .read(appSettingsProvider.notifier)
                      .updateThemeMode(selection.first);
                },
              ),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text('Number format'),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SegmentedButton<NumberFormatPreference>(
                segments: [
                  ButtonSegment(
                    value: NumberFormatPreference.commaDecimalDot,
                    label: Text(
                      formatNumber(
                        1500000,
                        preference: NumberFormatPreference.commaDecimalDot,
                      ),
                    ),
                  ),
                  ButtonSegment(
                    value: NumberFormatPreference.dotDecimalComma,
                    label: Text(
                      formatNumber(
                        1500000,
                        preference: NumberFormatPreference.dotDecimalComma,
                      ),
                    ),
                  ),
                ],
                selected: {settings.numberFormatPreference},
                onSelectionChanged: (selection) {
                  ref
                      .read(appSettingsProvider.notifier)
                      .updateNumberFormatPreference(selection.first);
                },
              ),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text('Alert check frequency'),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SegmentedButton<Duration>(
                segments: const [
                  ButtonSegment(value: Duration(hours: 1), label: Text('1h')),
                  ButtonSegment(value: Duration(hours: 3), label: Text('3h')),
                  ButtonSegment(value: Duration(hours: 6), label: Text('6h')),
                  ButtonSegment(value: Duration(hours: 12), label: Text('12h')),
                ],
                selected: {settings.alertCheckFrequency},
                onSelectionChanged: (selection) {
                  ref
                      .read(appSettingsProvider.notifier)
                      .updateAlertCheckFrequency(selection.first);
                },
              ),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text('Manage benchmarks'),
            subtitle: const Text('Real Price Mode comparison items'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const BenchmarkPage()),
            ),
          ),
        ],
      ),
    );
  }
}
