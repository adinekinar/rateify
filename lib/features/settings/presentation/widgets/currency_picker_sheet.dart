import 'package:flutter/material.dart';

import '../../../../core/constants/currency_reference.dart';

/// Bottom sheet listing [CurrencyReference.all], used by both onboarding
/// and the Settings page's "Home currency" row. Not in the original §11
/// tree for the settings feature (which lists no `presentation/widgets`
/// folder), added here because both call sites need the identical picker.
class CurrencyPickerSheet extends StatelessWidget {
  const CurrencyPickerSheet({super.key, this.selectedCode});

  final String? selectedCode;

  static Future<String?> show(BuildContext context, {String? selectedCode}) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => CurrencyPickerSheet(selectedCode: selectedCode),
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
              return ListTile(
                title: Text(currency.code),
                subtitle: Text(currency.displayName),
                trailing: currency.code == selectedCode
                    ? const Icon(Icons.check)
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
