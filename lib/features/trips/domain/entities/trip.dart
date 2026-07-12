/// §10.6 Trip.
class Trip {
  const Trip({
    required this.id,
    required this.name,
    required this.localCurrency,
    required this.homeCurrency,
    required this.totalBudget,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String localCurrency;

  /// §5.2/§20.7 snapshot rule — captured once from `AppSettings.homeCurrency`
  /// at trip creation and never re-derived from the global setting
  /// afterward. There is deliberately no `copyWith` parameter to change
  /// this — see [copyWith].
  final String homeCurrency;
  final double totalBudget;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// `homeCurrency` is intentionally not a parameter here (§20.7) — once a
  /// trip is created, nothing in the app is allowed to change which
  /// currency its budget is denominated in.
  Trip copyWith({
    String? name,
    String? localCurrency,
    double? totalBudget,
    bool? isArchived,
    DateTime? updatedAt,
  }) {
    return Trip(
      id: id,
      name: name ?? this.name,
      localCurrency: localCurrency ?? this.localCurrency,
      homeCurrency: homeCurrency,
      totalBudget: totalBudget ?? this.totalBudget,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Trip &&
        other.id == id &&
        other.name == name &&
        other.localCurrency == localCurrency &&
        other.homeCurrency == homeCurrency &&
        other.totalBudget == totalBudget &&
        other.isArchived == isArchived &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    localCurrency,
    homeCurrency,
    totalBudget,
    isArchived,
    createdAt,
    updatedAt,
  );

  @override
  String toString() =>
      'Trip(id: $id, name: $name, localCurrency: $localCurrency, '
      'homeCurrency: $homeCurrency, totalBudget: $totalBudget, '
      'isArchived: $isArchived, createdAt: $createdAt, updatedAt: $updatedAt)';
}
