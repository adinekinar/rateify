import 'app_exception.dart';

/// Thrown by local data sources / repositories when reading from or writing
/// to the Hive cache (§9.2) fails.
class CacheException extends AppException {
  const CacheException(super.message);

  factory CacheException.notFound() =>
      const CacheException('No cached data is available yet.');

  factory CacheException.readWriteFailed(String detail) =>
      CacheException('Could not access local storage: $detail');
}
