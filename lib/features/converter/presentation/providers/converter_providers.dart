import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/exchange_rate_repository.dart';

/// §12.1 core provider. Overridden in `main()` with a real
/// [ExchangeRateRepositoryImpl] once the rate-snapshot Hive box has been
/// opened — same composition-root pattern as `settingsRepositoryProvider`.
final exchangeRateRepositoryProvider = Provider<ExchangeRateRepository>((ref) {
  throw UnimplementedError(
    'exchangeRateRepositoryProvider must be overridden with an ExchangeRateRepositoryImpl in main()',
  );
});
