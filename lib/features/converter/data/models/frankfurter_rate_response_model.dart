/// Parses the raw JSON body from the Frankfurter API's `/latest` endpoint
/// (§9.1). Response shape (verified live against `api.frankfurter.dev/v1`):
///
/// ```json
/// {"amount":1.0,"base":"USD","date":"2026-07-10","rates":{"EUR":0.87,...}}
/// ```
class FrankfurterRateResponseModel {
  const FrankfurterRateResponseModel({
    required this.base,
    required this.date,
    required this.rates,
  });

  factory FrankfurterRateResponseModel.fromJson(Map<String, dynamic> json) {
    final rawRates = json['rates'] as Map<String, dynamic>;
    return FrankfurterRateResponseModel(
      base: json['base'] as String,
      date: DateTime.parse(json['date'] as String),
      rates: rawRates.map(
        (code, value) => MapEntry(code, (value as num).toDouble()),
      ),
    );
  }

  final String base;
  final DateTime date;
  final Map<String, double> rates;
}
