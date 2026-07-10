import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/currency_reference.dart';
import '../../../../core/constants/ui_constants.dart';
import '../providers/settings_providers.dart';
import '../widgets/currency_picker_sheet.dart';

/// One-screen onboarding (§8.2): choose a home currency, or skip to accept
/// the default (`USD`). Either path seeds the initial converter tile pair
/// per §3.2a and marks onboarding complete so it never shows again.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  String _selectedCurrency = AppConstants.defaultHomeCurrency;

  Future<void> _pickCurrency() async {
    final picked = await CurrencyPickerSheet.show(
      context,
      selectedCode: _selectedCurrency,
    );
    if (picked != null) {
      setState(() => _selectedCurrency = picked);
    }
  }

  void _finishOnboarding(String homeCurrency) {
    ref
        .read(appSettingsProvider.notifier)
        .completeOnboardingWithHomeCurrency(homeCurrency);
    ref.read(onboardingCompletedProvider.notifier).complete();
  }

  @override
  Widget build(BuildContext context) {
    final selectedInfo = CurrencyReference.all.firstWhere(
      (currency) => currency.code == _selectedCurrency,
    );

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(UiConstants.spaceLg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Welcome to Rateify',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: UiConstants.spaceSm),
              Text(
                'Pick your home currency to get started. You can change this later in Settings.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: UiConstants.spaceXl),
              OutlinedButton(
                onPressed: _pickCurrency,
                child: Text(
                  '${selectedInfo.code} — ${selectedInfo.displayName}',
                ),
              ),
              const SizedBox(height: UiConstants.spaceLg),
              ElevatedButton(
                onPressed: () => _finishOnboarding(_selectedCurrency),
                child: const Text('Continue'),
              ),
              const SizedBox(height: UiConstants.spaceSm),
              TextButton(
                onPressed: () =>
                    _finishOnboarding(AppConstants.defaultHomeCurrency),
                child: const Text('Skip (use USD)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
