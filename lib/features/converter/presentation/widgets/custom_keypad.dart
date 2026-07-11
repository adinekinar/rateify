import 'package:flutter/material.dart';

import '../../../../core/constants/ui_constants.dart';
import '../../../../core/theme/app_typography.dart';

/// §16.2 Custom Keypad.
///
/// Purely a grid of buttons relaying taps upward — every callback here maps
/// 1:1 to a `ConverterController` method, which is the only place that
/// calls into `KeypadInputParser`. No parsing logic lives in this widget.
///
/// Keypad spacing and space-filling rule (§16.2, added Batch 03d): this
/// widget expects to be given a bounded height by its parent (e.g. wrapped
/// in `Expanded`) and fills it — each of the 5 rows is an `Expanded` row
/// within this widget's own `Column`, so button height scales up with
/// whatever space is actually available, rather than staying at a fixed
/// small size with unused space above it. A consistent, clearly-visible
/// gap (`UiConstants.gapSm`, the §15.6 minimum) separates every row and
/// every button in a row — buttons must read as distinct individual keys,
/// never a merged block.
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

  Widget _buttonRow(List<Widget> buttons) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < buttons.length; i++) ...[
            if (i != 0) const SizedBox(width: UiConstants.gapSm),
            buttons[i],
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buttonRow([
          Expanded(
            child: _KeypadButton(label: 'C', onTap: onClear, isAction: true),
          ),
          Expanded(
            child: _KeypadButton(
              icon: Icons.backspace_outlined,
              onTap: onBackspace,
              isAction: true,
            ),
          ),
        ]),
        const SizedBox(height: UiConstants.gapSm),
        for (final row in _digitRows) ...[
          _buttonRow([
            for (final digit in row)
              Expanded(
                child: _KeypadButton(label: digit, onTap: () => onDigit(digit)),
              ),
          ]),
          const SizedBox(height: UiConstants.gapSm),
        ],
        _buttonRow([
          Expanded(
            flex: 2,
            child: _KeypadButton(label: '0', onTap: () => onDigit('0')),
          ),
          Expanded(
            child: _KeypadButton(label: '.', onTap: onDecimal),
          ),
        ]),
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

    // No fixed height here — this button fills whatever its parent
    // Expanded row gives it, so it scales with the keypad's own available
    // space instead of staying at a fixed small size (§16.2).
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(UiConstants.smallButtonRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(UiConstants.smallButtonRadius),
        onTap: onTap,
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
    );
  }
}
