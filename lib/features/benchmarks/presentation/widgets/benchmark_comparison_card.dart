import 'package:flutter/material.dart';

import '../../../../core/constants/ui_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/benchmark_comparison_result.dart';

/// §4.1/§4.2 embedded comparison card for the Converter page.
///
/// Deliberately dumb, like `CurrencyInputTile` — it only renders whatever
/// [results] it's given. Real Price Mode visibility (TC-RPM-011) is fully
/// derived from active-benchmark count: when [results] is empty (no active
/// benchmarks, or none of them have a resolvable rate right now), this
/// renders nothing at all — no empty-state text here. That's a deliberate,
/// already-tested distinction (Batch 03) from the dedicated benchmark
/// management page, which does show real §4.4 empty-state text.
class BenchmarkComparisonCard extends StatelessWidget {
  const BenchmarkComparisonCard({super.key, required this.results});

  final List<BenchmarkComparisonResult> results;

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final top = results.first;
    final remaining = results.skip(1).toList();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(UiConstants.currencyTileRadius),
        onTap: remaining.isEmpty
            ? null
            : () => _showRemaining(context, remaining),
        child: Container(
          width: double.infinity,
          // §15.6: at least `gapMd` (12px) internal padding so the
          // comparison text never touches the card's edge.
          padding: const EdgeInsets.symmetric(
            horizontal: UiConstants.spaceMd,
            vertical: UiConstants.gapMd,
          ),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(UiConstants.currencyTileRadius),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.local_offer_outlined,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: UiConstants.gapSm),
              Expanded(
                child: Text(
                  top.displayText,
                  style: AppTypography.body(
                    color: theme.colorScheme.onSurface,
                  ).copyWith(height: 1.0),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (remaining.isNotEmpty) ...[
                const SizedBox(width: UiConstants.gapSm),
                Text(
                  '+${remaining.length} more',
                  style: AppTypography.caption(
                    color: AppColors.primary,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showRemaining(
    BuildContext context,
    List<BenchmarkComparisonResult> remaining,
  ) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final result in remaining)
              ListTile(
                leading: const Icon(Icons.local_offer_outlined),
                title: Text(result.displayText),
              ),
          ],
        ),
      ),
    );
  }
}
