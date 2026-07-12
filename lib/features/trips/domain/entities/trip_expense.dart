/// §5.3/§10.1 Expense categories for MVP.
enum ExpenseCategory { food, transport, hotel, shopping, ticket, other }

/// §10.7 Trip Expense.
class TripExpense {
  const TripExpense({
    required this.id,
    required this.tripId,
    required this.title,
    required this.amountLocal,
    required this.category,
    this.note,
    required this.spentAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String tripId;
  final String title;

  /// §5.4/§20.4 — always stored in the trip's local currency and never
  /// overwritten once recorded, even when exchange rates change. Only the
  /// home-currency conversion shown for display is ever recalculated (see
  /// `TripBudgetCalculator`).
  final double amountLocal;
  final ExpenseCategory category;
  final String? note;
  final DateTime spentAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  TripExpense copyWith({
    String? title,
    double? amountLocal,
    ExpenseCategory? category,
    String? note,
    bool clearNote = false,
    DateTime? spentAt,
    DateTime? updatedAt,
  }) {
    return TripExpense(
      id: id,
      tripId: tripId,
      title: title ?? this.title,
      amountLocal: amountLocal ?? this.amountLocal,
      category: category ?? this.category,
      note: clearNote ? null : (note ?? this.note),
      spentAt: spentAt ?? this.spentAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TripExpense &&
        other.id == id &&
        other.tripId == tripId &&
        other.title == title &&
        other.amountLocal == amountLocal &&
        other.category == category &&
        other.note == note &&
        other.spentAt == spentAt &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(
    id,
    tripId,
    title,
    amountLocal,
    category,
    note,
    spentAt,
    createdAt,
    updatedAt,
  );

  @override
  String toString() =>
      'TripExpense(id: $id, tripId: $tripId, title: $title, '
      'amountLocal: $amountLocal, category: $category, note: $note, '
      'spentAt: $spentAt, createdAt: $createdAt, updatedAt: $updatedAt)';
}
