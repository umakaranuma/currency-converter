import '../../core/errors.dart';

/// A snapshot of USD-based exchange rates plus the moment we obtained it.
///
/// This is the domain currency of the app: the repository returns it, the
/// controller renders it. It carries no JSON/HTTP concerns — mapping lives in
/// `data/models/rates_dto.dart`.
class ExchangeRates {
  const ExchangeRates({
    required this.base,
    required this.rates,
    required this.fetchedAt,
    this.lastError,
  });

  /// Base currency the [rates] are expressed against (always `USD` here).
  final String base;

  /// Target currency code -> units of that currency per 1 unit of [base].
  final Map<String, double> rates;

  /// When this snapshot was fetched from the network (not when the upstream
  /// provider last published). Used for freshness and the "updated X ago" hint.
  final DateTime fetchedAt;

  /// Non-null when these rates were served as a **stale fallback** because a
  /// refresh failed. The type of error tells the UI whether to blame the
  /// network or the API. Null on a normal fresh result.
  final AppException? lastError;

  /// True once the snapshot is older than [ttl]. A stale snapshot is still
  /// usable offline; the repository just tries to refresh it first.
  bool isStale(Duration ttl) => DateTime.now().difference(fetchedAt) >= ttl;

  /// Whether this instance is a stale fallback rather than a fresh fetch.
  bool get servedAsFallback => lastError != null;

  /// Returns a copy tagged with [lastError] (used by the repository when it
  /// falls back to cache after a failed refresh).
  ExchangeRates copyWith({AppException? lastError}) => ExchangeRates(
        base: base,
        rates: rates,
        fetchedAt: fetchedAt,
        lastError: lastError ?? this.lastError,
      );
}
