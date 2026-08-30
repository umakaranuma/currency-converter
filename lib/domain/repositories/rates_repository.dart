import '../entities/exchange_rates.dart';

/// Contract the presentation layer depends on. The concrete implementation
/// ([RatesRepositoryImpl] in the data layer) owns the cache-vs-network policy;
/// callers just ask for rates.
abstract interface class RatesRepository {
  /// Returns the best available USD rate snapshot.
  ///
  /// Behaviour (see `agent/caching.md`):
  /// - fresh cache present and [forceRefresh] is false -> returns it, no network;
  /// - otherwise fetches, writes the result to cache, and returns it;
  /// - fetch fails but a cached snapshot exists -> returns the cache tagged with
  ///   [ExchangeRates.lastError] (does not throw);
  /// - fetch fails and no cache exists -> throws an [AppException]
  ///   ([NetworkException] / [ApiException] / [CacheMissException]).
  Future<ExchangeRates> getRates({bool forceRefresh = false});
}
