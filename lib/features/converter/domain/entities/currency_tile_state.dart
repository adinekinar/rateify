/// §10.4 Currency Tile State.
///
/// Session-restore rule (§10.4/§20.8): `id` is ephemeral, regenerated fresh
/// each session — it is never persisted and must not be assumed stable
/// across app restarts. Only `currencyCode` order is persisted, via
/// `AppSettings.selectedConverterCurrencies`.
class CurrencyTileState {
  const CurrencyTileState({
    required this.id,
    required this.currencyCode,
    required this.isActiveInput,
    required this.rawInput,
    required this.convertedAmount,
    required this.sortOrder,
  });

  final String id;
  final String currencyCode;
  final bool isActiveInput;

  /// Full-precision raw keypad input, only ever non-empty on the active
  /// tile (§20.1 — inactive tiles never hold independent input state).
  final String rawInput;

  /// Full-precision converted amount for an inactive tile, or `null` if it
  /// can't currently be computed (no rate available). Never a display
  /// string (§20.2).
  final double? convertedAmount;
  final int sortOrder;

  CurrencyTileState copyWith({
    String? id,
    String? currencyCode,
    bool? isActiveInput,
    String? rawInput,
    double? convertedAmount,
    bool clearConvertedAmount = false,
    int? sortOrder,
  }) {
    return CurrencyTileState(
      id: id ?? this.id,
      currencyCode: currencyCode ?? this.currencyCode,
      isActiveInput: isActiveInput ?? this.isActiveInput,
      rawInput: rawInput ?? this.rawInput,
      convertedAmount: clearConvertedAmount
          ? null
          : (convertedAmount ?? this.convertedAmount),
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CurrencyTileState &&
        other.id == id &&
        other.currencyCode == currencyCode &&
        other.isActiveInput == isActiveInput &&
        other.rawInput == rawInput &&
        other.convertedAmount == convertedAmount &&
        other.sortOrder == sortOrder;
  }

  @override
  int get hashCode => Object.hash(
    id,
    currencyCode,
    isActiveInput,
    rawInput,
    convertedAmount,
    sortOrder,
  );

  @override
  String toString() =>
      'CurrencyTileState(id: $id, currencyCode: $currencyCode, isActiveInput: $isActiveInput, '
      'rawInput: $rawInput, convertedAmount: $convertedAmount, sortOrder: $sortOrder)';
}
