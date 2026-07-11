/// §10.5 Benchmark Item.
class BenchmarkItem {
  const BenchmarkItem({
    required this.id,
    required this.name,
    required this.price,
    required this.currencyCode,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final double price;
  final String currencyCode;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// `updatedAt` is only ever bumped by an explicit pass-in — activating or
  /// deactivating a benchmark (§4.2) does not count as an "edit" and must
  /// not shift its position under the §4.2 "top" ordering rule, which is
  /// keyed on `updatedAt`.
  BenchmarkItem copyWith({
    String? name,
    double? price,
    String? currencyCode,
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return BenchmarkItem(
      id: id,
      name: name ?? this.name,
      price: price ?? this.price,
      currencyCode: currencyCode ?? this.currencyCode,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BenchmarkItem &&
        other.id == id &&
        other.name == name &&
        other.price == price &&
        other.currencyCode == currencyCode &&
        other.isActive == isActive &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    price,
    currencyCode,
    isActive,
    createdAt,
    updatedAt,
  );

  @override
  String toString() =>
      'BenchmarkItem(id: $id, name: $name, price: $price, currencyCode: $currencyCode, '
      'isActive: $isActive, createdAt: $createdAt, updatedAt: $updatedAt)';
}
