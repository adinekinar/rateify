import 'package:flutter/material.dart';

import '../../../../core/constants/currency_reference.dart';

/// Bottom sheet (§16.4) for adding a currency tile, built from the trimmed
/// [CurrencyReference.all] list. Currencies already in [existingCurrencyCodes]
/// are visibly disabled (§3.2 duplicate prevention) rather than hidden —
/// the user can see why a currency isn't tappable.
///
/// Distinct from the settings feature's own currency picker (used for
/// home-currency selection, which never needs to disable anything) —
/// similar in shape but different enough in behavior that sharing one
/// widget across features would need an awkward always-on disabling param.
class ConverterCurrencyPickerSheet extends StatelessWidget {
  const ConverterCurrencyPickerSheet({
    super.key,
    required this.existingCurrencyCodes,
  });

  final Set<String> existingCurrencyCodes;

  static Future<String?> show(
    BuildContext context, {
    required Set<String> existingCurrencyCodes,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => ConverterCurrencyPickerSheet(
        existingCurrencyCodes: existingCurrencyCodes,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (context, scrollController) {
          return ListView.builder(
            controller: scrollController,
            itemCount: CurrencyReference.all.length,
            itemBuilder: (context, index) {
              final currency = CurrencyReference.all[index];
              final isDisabled = existingCurrencyCodes.contains(currency.code);
              return ListTile(
                enabled: !isDisabled,
                title: Text(currency.code),
                subtitle: Text(currency.displayName),
                trailing: isDisabled ? const Text('Added') : null,
                onTap: isDisabled
                    ? null
                    : () => Navigator.of(context).pop(currency.code),
              );
            },
          );
        },
      ),
    );
  }
}
