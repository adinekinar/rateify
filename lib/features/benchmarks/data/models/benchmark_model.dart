import '../../domain/entities/benchmark_item.dart';

/// JSON (de)serialization for [BenchmarkItem], kept out of the domain
/// entity (same separation as `AppSettingsJsonMapper`).
///
/// Storage choice (Batch 04): plain JSON via `toJson`/`fromJson`, one
/// string per benchmark under its own `id` key in a `Box<dynamic>` — same
/// reasoning as the Batch 01 settings repository, no generated Hive
/// `TypeAdapter` needed for this small, stable shape.
extension BenchmarkItemJsonMapper on BenchmarkItem {
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
    'currencyCode': currencyCode,
    'isActive': isActive,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}

BenchmarkItem benchmarkItemFromJson(Map<String, dynamic> json) => BenchmarkItem(
  id: json['id'] as String,
  name: json['name'] as String,
  price: (json['price'] as num).toDouble(),
  currencyCode: json['currencyCode'] as String,
  isActive: json['isActive'] as bool,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);
