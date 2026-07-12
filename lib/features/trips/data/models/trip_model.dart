import '../../domain/entities/trip.dart';

/// JSON (de)serialization for [Trip], kept out of the domain entity (same
/// separation as `BenchmarkItemJsonMapper`).
///
/// Storage choice (Batch 05): plain JSON via `toJson`/`fromJson`, one
/// string per trip under its own `id` key in a `Box<dynamic>` — same
/// reasoning as the Batch 04 benchmark repository, no generated Hive
/// `TypeAdapter` needed for this small, stable shape.
extension TripJsonMapper on Trip {
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'localCurrency': localCurrency,
    'homeCurrency': homeCurrency,
    'totalBudget': totalBudget,
    'isArchived': isArchived,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}

Trip tripFromJson(Map<String, dynamic> json) => Trip(
  id: json['id'] as String,
  name: json['name'] as String,
  localCurrency: json['localCurrency'] as String,
  homeCurrency: json['homeCurrency'] as String,
  totalBudget: (json['totalBudget'] as num).toDouble(),
  isArchived: json['isArchived'] as bool,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);
