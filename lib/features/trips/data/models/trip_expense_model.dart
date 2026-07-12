import '../../domain/entities/trip_expense.dart';

/// JSON (de)serialization for [TripExpense] — same plain-JSON-per-id-key
/// storage choice as [TripJsonMapper] (see that file's doc comment).
extension TripExpenseJsonMapper on TripExpense {
  Map<String, dynamic> toJson() => {
    'id': id,
    'tripId': tripId,
    'title': title,
    'amountLocal': amountLocal,
    'category': category.name,
    'note': note,
    'spentAt': spentAt.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}

TripExpense tripExpenseFromJson(Map<String, dynamic> json) => TripExpense(
  id: json['id'] as String,
  tripId: json['tripId'] as String,
  title: json['title'] as String,
  amountLocal: (json['amountLocal'] as num).toDouble(),
  category: ExpenseCategory.values.byName(json['category'] as String),
  note: json['note'] as String?,
  spentAt: DateTime.parse(json['spentAt'] as String),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);
