import 'package:flutter/material.dart';

import 'core/constants/ui_constants.dart';
import 'core/theme/app_colors.dart';

class FloatingNavItem {
  const FloatingNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// A floating, rounded bottom navigation bar (§15.1, §15.5) — lifted off the
/// screen edges with margin and a soft shadow, rather than flush against the
/// edge like a standard [NavigationBar].
///
/// No blur, frosted-glass, or glassmorphism effects: the background is a
/// plain opaque fill (the "Surface Alt" / "Dark Card" token via
/// [ColorScheme.surfaceContainerHighest], §15.2) and the shadow is an
/// ordinary [BoxShadow] — soft-edged, not a `BackdropFilter`. Motion reuses
/// the same short, non-bouncy `Curves.easeOutCubic` already used for the
/// bottom sheet transition (§17.4); nothing here scales, bounces, or
/// overshoots (§17.1).
class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.items,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<FloatingNavItem> items;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(
        UiConstants.spaceMd,
        0,
        UiConstants.spaceMd,
        UiConstants.spaceMd,
      ),
      child: Container(
        height: UiConstants.floatingNavBarHeight,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(UiConstants.floatingNavBarRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = constraints.maxWidth / items.length;
            return Stack(
              children: [
                AnimatedPositioned(
                  duration: UiConstants.bottomSheetAnimationDuration,
                  curve: Curves.easeOutCubic,
                  left: itemWidth * selectedIndex,
                  top: 0,
                  bottom: 0,
                  width: itemWidth,
                  child: Padding(
                    padding: const EdgeInsets.all(UiConstants.spaceSm),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(
                          UiConstants.floatingNavBarIndicatorRadius,
                        ),
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    for (var i = 0; i < items.length; i++)
                      Expanded(
                        child: _FloatingNavBarItem(
                          item: items[i],
                          selected: i == selectedIndex,
                          onTap: () => onDestinationSelected(i),
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FloatingNavBarItem extends StatelessWidget {
  const _FloatingNavBarItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final FloatingNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected
        ? AppColors.primary
        : theme.colorScheme.onSurface.withValues(alpha: 0.6);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(
          UiConstants.floatingNavBarIndicatorRadius,
        ),
        onTap: onTap,
        child: Semantics(
          selected: selected,
          button: true,
          label: item.label,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: UiConstants.spaceSm),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  selected ? item.selectedIcon : item.icon,
                  color: color,
                  size: 22,
                ),
                const SizedBox(height: 2),
                Text(
                  item.label,
                  style: theme.textTheme.bodySmall?.copyWith(color: color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
