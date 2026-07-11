import 'package:flutter/material.dart';

import '../../../../core/constants/ui_constants.dart';
import '../../../../core/theme/app_typography.dart';

/// §16.2 Custom Keypad.
///
/// Purely a grid of buttons relaying taps upward — every callback here maps
/// 1:1 to a `ConverterController` method, which is the only place that
/// calls into `KeypadInputParser`. No parsing logic lives in this widget.
class CustomKeypad extends StatelessWidget {
  const CustomKeypad({
    super.key,
    required this.onDigit,
    required this.onDecimal,
    required this.onBackspace,
    required this.onClear,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onDecimal;
  final VoidCallback onBackspace;
  final VoidCallback onClear;

  static const _digitRows = [
    ['7', '8', '9'],
    ['4', '5', '6'],
    ['1', '2', '3'],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: _KeypadButton(label: 'C', onTap: onClear, isAction: true),
            ),
            const SizedBox(width: UiConstants.spaceSm),
            Expanded(
              child: _KeypadButton(
                icon: Icons.backspace_outlined,
                onTap: onBackspace,
                isAction: true,
              ),
            ),
          ],
        ),
        for (final row in _digitRows)
          Row(
            children: [
              for (final digit in row) ...[
                Expanded(
                  child: _KeypadButton(
                    label: digit,
                    onTap: () => onDigit(digit),
                  ),
                ),
                if (digit != row.last)
                  const SizedBox(width: UiConstants.spaceSm),
              ],
            ],
          ),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _KeypadButton(label: '0', onTap: () => onDigit('0')),
            ),
            const SizedBox(width: UiConstants.spaceSm),
            Expanded(
              child: _KeypadButton(label: '.', onTap: onDecimal),
            ),
          ],
        ),
      ],
    );
  }
}

class _KeypadButton extends StatelessWidget {
  const _KeypadButton({
    this.label,
    this.icon,
    required this.onTap,
    this.isAction = false,
  }) : assert(
         label != null || icon != null,
         'a keypad button needs a label or an icon',
       );

  final String? label;
  final IconData? icon;
  final VoidCallback onTap;
  final bool isAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: UiConstants.spaceXs),
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(UiConstants.smallButtonRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(UiConstants.smallButtonRadius),
          onTap: onTap,
          child: SizedBox(
            height: 56,
            child: Center(
              child: icon != null
                  ? Icon(
                      icon,
                      color: onSurface.withValues(alpha: isAction ? 0.7 : 1),
                    )
                  : Text(
                      label!,
                      style: AppTypography.title(
                        color: onSurface.withValues(alpha: isAction ? 0.7 : 1),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
