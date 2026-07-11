import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/network_exception.dart';
import '../models/frankfurter_rate_response_model.dart';

/// Isolates all Frankfurter API access (§9.1) — the only file in the app
/// allowed to know the HTTP details of this provider.
///
/// Verified live on 2026-07-11 against `api.frankfurter.dev`: `/v1/latest`
/// remains available and returns the classic `{base, date, rates}` shape
/// (confirmed via `curl`), which maps directly onto [RateSnapshotModel]
/// with no restructuring. A newer `/v2/rates` exists but returns an
/// array-of-quote-objects shape (`[{base, quote, rate, date}, ...]`) that
/// would need extra transformation for no benefit here, so `v1` — already
/// what `ApiConstants.frankfurterBaseUrl` pointed to — is what's used.
class ExchangeRateRemoteDataSource {
  ExchangeRateRemoteDataSource({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  /// Fetches latest rates for every currency Frankfurter supports, anchored
  /// to [baseCurrency] — one call, no `symbols`/`quotes` filter, so newly
  /// bundled currencies are picked up automatically without a code change.
  Future<FrankfurterRateResponseModel> fetchLatestRates({
    required String baseCurrency,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '${ApiConstants.frankfurterBaseUrl}${ApiConstants.latestRatesPath}',
        queryParameters: {'base': baseCurrency},
        options: Options(
          sendTimeout: ApiConstants.requestTimeout,
          receiveTimeout: ApiConstants.requestTimeout,
        ),
      );
      final data = response.data;
      if (data == null) {
        throw NetworkException.unexpected(
          'Empty response body from Frankfurter.',
        );
      }
      return FrankfurterRateResponseModel.fromJson(data);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  NetworkException _mapDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException.timeout();
      case DioExceptionType.connectionError:
        return NetworkException.noConnection();
      case DioExceptionType.badCertificate:
      case DioExceptionType.badResponse:
      case DioExceptionType.cancel:
      case DioExceptionType.transformTimeout:
      case DioExceptionType.unknown:
        return NetworkException.unexpected(e.message ?? e.toString());
    }
  }
}
