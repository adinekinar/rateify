import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/ui_constants.dart';
import '../../../../core/formatting/number_formatter.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../../domain/entities/trip.dart';
import '../providers/trip_providers.dart';
import '../widgets/trip_form_sheet.dart';
import 'trip_detail_page.dart';

/// §5.1/§5.5 Trip Budget Tracker list screen: trip list, create-trip entry
/// point, and the "no trip yet" empty state.
class TripListPage extends ConsumerWidget {
  const TripListPage({super.key});

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Trip trip,
  ) async {
    // §18.10 — no hidden destructive action.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete trip?'),
        content: Text(
          'This removes "${trip.name}" and all its expenses permanently.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(tripListControllerProvider.notifier).deleteTrip(trip.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trips = ref.watch(tripListControllerProvider);
    final activeTrips = trips.where((trip) => !trip.isArchived).toList();
    final numberFormatPreference = ref.watch(
      appSettingsProvider.select((settings) => settings.numberFormatPreference),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Trips')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => TripFormSheet.show(context),
        child: const Icon(Icons.add),
      ),
      body: activeTrips.isEmpty
          ? const _EmptyState(
              title: 'Belum ada trip.',
              subtitle:
                  'Buat trip pertama untuk mulai mengontrol budget perjalanan.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(UiConstants.spaceMd),
              itemCount: activeTrips.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: UiConstants.spaceSm),
              itemBuilder: (context, index) {
                final trip = activeTrips[index];
                return _TripRow(
                  trip: trip,
                  numberFormatPreference: numberFormatPreference,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => TripDetailPage(tripId: trip.id),
                    ),
                  ),
                  onArchive: () => ref
                      .read(tripListControllerProvider.notifier)
                      .archiveTrip(trip.id),
                  onDelete: () => _confirmDelete(context, ref, trip),
                );
              },
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(UiConstants.spaceLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.card_travel_outlined,
              size: 48,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(height: UiConstants.spaceMd),
            Text(
              title,
              style: AppTypography.section(color: theme.colorScheme.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: UiConstants.spaceXs),
            Text(
              subtitle,
              style: AppTypography.body(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _TripRow extends StatelessWidget {
  const _TripRow({
    required this.trip,
    required this.numberFormatPreference,
    required this.onTap,
    required this.onArchive,
    required this.onDelete,
  });

  final Trip trip;
  final NumberFormatPreference numberFormatPreference;
  final VoidCallback onTap;
  final VoidCallback onArchive;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(UiConstants.currencyTileRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(UiConstants.currencyTileRadius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(UiConstants.gapMd),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      trip.name,
                      style: AppTypography.body(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Budget: '
                      '${formatNumber(trip.totalBudget, preference: numberFormatPreference)} '
                      '${trip.localCurrency}',
                      style: AppTypography.caption(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (action) {
                  if (action == 'archive') onArchive();
                  if (action == 'delete') onDelete();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'archive', child: Text('Archive')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
