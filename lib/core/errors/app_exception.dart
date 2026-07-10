/// Base type for all app-level exceptions.
///
/// Feature-specific exceptions should extend this so error handling code
/// (e.g. converting to a user-friendly message per §18.9) can rely on a
/// single common type.
abstract class AppException implements Exception {
  const AppException(this.message);

  /// User-facing, human-readable explanation. Must never be a raw
  /// exception/stack trace string (§18.9).
  final String message;

  @override
  String toString() => message;
}
