import 'app_exception.dart';

/// Thrown by remote data sources / repositories when a network request
/// (e.g. to the Frankfurter API, §9.1) fails.
class NetworkException extends AppException {
  const NetworkException(super.message);

  factory NetworkException.noConnection() =>
      const NetworkException('No internet connection is available.');

  factory NetworkException.timeout() =>
      const NetworkException('The request timed out. Please try again.');

  factory NetworkException.unexpected(String detail) =>
      NetworkException('Something went wrong while fetching rates: $detail');
}
