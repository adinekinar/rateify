import 'package:flutter/material.dart';

import '../../../../core/constants/currency_reference.dart';

/// Bottom sheet (§16.4) for adding or removing a currency tile, built from
/// the trimmed [CurrencyReference.all] list.
///
/// §3.2 tap-to-remove addendum (Batch 05): an already-selected currency
/// (one whose code is in [existingCurrencyCodes]) stays tappable rather
/// than being disabled with no action — tapping it pops its code just like
/// any other row, and the caller (the converter page) interprets a tap on
/// an already-selected currency as a removal request instead of an add.
/// This keeps the sheet itself free of any add/remove branching or the
/// §3.2b min-tile-count check — the caller already owns that logic via
/// `ConverterController.addCurrency`/`removeCurrency`.
///
/// Distinct from the settings feature's own currency picker (used for
/// home-currency selection, which never needs a "selected" indicator at
/// all) — similar in shape but different enough in behavior that sharing
/// one widget across features would need an awkward always-on param.
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
              final isSelected = existingCurrencyCodes.contains(currency.code);
              return ListTile(
                title: Text(currency.code),
                subtitle: Text(currency.displayName),
                trailing: isSelected
                    ? const Icon(Icons.check_circle_outline)
                    : null,
                onTap: () => Navigator.of(context).pop(currency.code),
              );
            },
          );
        },
      ),
    );
  }
}
