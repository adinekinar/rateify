import 'package:uuid/uuid.dart';

/// Thin wrapper around the `uuid` package so the rest of the app never
/// imports `package:uuid` directly.
abstract final class IdGenerator {
  static const Uuid _uuid = Uuid();

  static String generate() => _uuid.v4();
}
