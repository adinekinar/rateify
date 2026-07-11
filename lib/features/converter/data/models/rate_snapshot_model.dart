import 'package:collection/collection.dart';

import 'frankfurter_rate_response_model.dart';

/// §10.1 core enum. Defined here (rather than a separate domain entities
/// file) because its first and only consumer this batch is
/// [RateSnapshotModel] — see the design note on [RateSnapshotModel] itself.
enum RateSourceStatus { freshRemote, cached, unavailable }

/// §10.3 Rate Snapshot.
///
/// Design note: the spec's §11 architecture tree lists this file under
/// `data/models/`, not a separate `domain/entities/` class — so this model
/// doubles as the [ExchangeRateRepository] contract's return type directly.
/// Introducing a parallel domain entity with a mapper between the two would
/// just be a duplicate class with no behavioral difference.
class RateSnapshotModel {
  const RateSnapshotModel({
    required this.baseCurrency,
    required this.rates,
    required this.fetchedAt,
    required this.sourceStatus,
  });

  /// Constructed when a fetch succeeds — `sourceStatus` is always
  /// [RateSourceStatus.freshRemote] at the moment of writing to cache; a
  /// later cache-fallback read re-tags the same data as `cached` (see
  /// [ExchangeRateRepositoryImpl]).
  factory RateSnapshotModel.fromFrankfurterResponse(
    FrankfurterRateResponseModel response, {
    required DateTime fetchedAt,
  }) {
    return RateSnapshotModel(
      baseCurrency: response.base,
      rates: response.rates,
      fetchedAt: fetchedAt,
      sourceStatus: RateSourceStatus.freshRemote,
    );
  }

  /// §9.2 step 4 — no cache and remote fetch failed. `fetchedAt` reflects
  /// when this unavailable result was determined, not a successful fetch.
  factory RateSnapshotModel.unavailable({
    required String baseCurrency,
    required DateTime determinedAt,
  }) {
    return RateSnapshotModel(
      baseCurrency: baseCurrency,
      rates: const {},
      fetchedAt: determinedAt,
      sourceStatus: RateSourceStatus.unavailable,
    );
  }

  final String baseCurrency;

  /// Rates from [baseCurrency] to each target currency Frankfurter supports.
  /// Currencies with no Frankfurter rate simply have no entry here — callers
  /// must handle a missing key, not assume every bundled reference currency
  /// is present (see Batch 02 summary for which ones are currently absent).
  final Map<String, double> rates;
  final DateTime fetchedAt;
  final RateSourceStatus sourceStatus;

  RateSnapshotModel copyWith({RateSourceStatus? sourceStatus}) {
    return RateSnapshotModel(
      baseCurrency: baseCurrency,
      rates: rates,
      fetchedAt: fetchedAt,
      sourceStatus: sourceStatus ?? this.sourceStatus,
    );
  }

  Map<String, dynamic> toJson() => {
    'baseCurrency': baseCurrency,
    'rates': rates,
    'fetchedAt': fetchedAt.toIso8601String(),
    'sourceStatus': sourceStatus.name,
  };

  factory RateSnapshotModel.fromJson(Map<String, dynamic> json) {
    final rawRates = json['rates'] as Map;
    return RateSnapshotModel(
      baseCurrency: json['baseCurrency'] as String,
      rates: rawRates.map(
        (code, value) => MapEntry(code as String, (value as num).toDouble()),
      ),
      fetchedAt: DateTime.parse(json['fetchedAt'] as String),
      sourceStatus: RateSourceStatus.values.byName(
        json['sourceStatus'] as String,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    const mapEquals = MapEquality<String, double>();
    return other is RateSnapshotModel &&
        other.baseCurrency == baseCurrency &&
        mapEquals.equals(other.rates, rates) &&
        other.fetchedAt == fetchedAt &&
        other.sourceStatus == sourceStatus;
  }

  @override
  int get hashCode => Object.hash(
    baseCurrency,
    const MapEquality<String, double>().hash(rates),
    fetchedAt,
    sourceStatus,
  );
}
