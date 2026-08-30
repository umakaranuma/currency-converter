import '../../core/constants.dart';
import '../../core/errors.dart';
import '../../domain/entities/exchange_rates.dart';
import '../../domain/repositories/rates_repository.dart';
import '../datasources/rates_local_datasource.dart';
import '../datasources/rates_remote_datasource.dart';

/// Owns the cache-vs-network decision. This is the class the assignment's
/// caching questions are really about, and the one the primary test pins down
/// (testing.md T1-T4).
class RatesRepositoryImpl implements RatesRepository {
  /// [ttl] is injectable so tests can put a snapshot on either side of the
  /// freshness boundary; production uses [kCacheTtl].
  RatesRepositoryImpl(
    this._remote,
    this._local, [
    this._ttl = kCacheTtl,
  ]);

  final RatesRemoteDataSource _remote;
  final RatesLocalDataSource _local;
  final Duration _ttl;

  @override
  Future<ExchangeRates> getRates({bool forceRefresh = false}) async {
    // --- Step 1: read whatever is cached (may be absent or corrupt). ---
    ExchangeRates? cached;
    bool cacheWasCorrupt = false;
    try {
      cached = (await _local.read())?.toEntity();
    } on CacheMissException {
      cacheWasCorrupt = true; // bad blob already cleared by the datasource
    }

    // --- Step 2: fresh cache hit -> serve it, no network at all. ---
    // This is the branch the caching test proves: remove it and `verifyNever`
    // on the remote datasource fails.
    if (!forceRefresh && cached != null && !cached.isStale(_ttl)) {
      return cached;
    }

    // --- Step 3: refresh needed (stale / missing / forced). ---
    try {
      final fresh = await _remote.fetch();
      await _local.write(fresh); // write-through: next launch is a cache hit
      return fresh.toEntity();
    } on AppException catch (error) {
      // Refresh failed. Prefer showing something over failing:
      if (cached != null) {
        // Serve the stale snapshot, tagged so the UI can explain why.
        return cached.copyWith(lastError: error);
      }
      // Nothing to fall back to.
      if (cacheWasCorrupt) {
        throw const CacheMissException(
          'Saved rates were unreadable and the refresh failed',
        );
      }
      rethrow; // NetworkException / ApiException, straight through
    }
  }
}
