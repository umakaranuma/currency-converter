/// App-wide configuration. Every tunable value the assignment cares about
/// (currency set, cache TTL, request timeout, API base URL) lives here so it can
/// be changed in one place instead of being scattered as literals — see
/// `agent/rules.md` R7.3.
library;

/// The only base currency this app converts *from*.
const String kBaseCurrency = 'USD';

/// The fixed set of currencies we convert *to*, in display order.
///
/// Adding a currency is a one-line change here (rules.md R2.5); nothing else in
/// the codebase hard-codes this list.
const List<String> kTargetCurrencies = <String>['EUR', 'GBP', 'JPY', 'AUD', 'CAD'];

/// Fraction digits to show per currency. JPY has no minor unit, so it is shown
/// with 0 decimals; everything else uses 2. Consumed only by `core/formatting`.
const Map<String, int> kCurrencyDecimals = <String, int>{
  'EUR': 2,
  'GBP': 2,
  'JPY': 0,
  'AUD': 2,
  'CAD': 2,
};

/// Human-facing metadata (full name + flag emoji) for the base and every target
/// currency. Purely presentational — the conversion logic only needs the codes.
const Map<String, ({String name, String flag})> kCurrencyInfo =
    <String, ({String name, String flag})>{
  'USD': (name: 'US Dollar', flag: '\u{1F1FA}\u{1F1F8}'),
  'EUR': (name: 'Euro', flag: '\u{1F1EA}\u{1F1FA}'),
  'GBP': (name: 'British Pound', flag: '\u{1F1EC}\u{1F1E7}'),
  'JPY': (name: 'Japanese Yen', flag: '\u{1F1EF}\u{1F1F5}'),
  'AUD': (name: 'Australian Dollar', flag: '\u{1F1E6}\u{1F1FA}'),
  'CAD': (name: 'Canadian Dollar', flag: '\u{1F1E8}\u{1F1E6}'),
};

/// How long a cached rate snapshot is considered "fresh". Within this window the
/// repository serves the cache and makes **no** network call. Rationale for the
/// 1-hour value is in `agent/decisions.md` D1.
const Duration kCacheTtl = Duration(hours: 1);

/// Hard ceiling on a single rates request. An unbounded HTTP call is a bug
/// (rules.md R4.5); on expiry we treat it as a network failure.
const Duration kRequestTimeout = Duration(seconds: 10);

/// exchangerate-api.com's key-less "open" endpoint. A full request URL is
/// `"$kRatesBaseUrl/$kBaseCurrency"`. No API key is required, so there is no
/// secret to manage (decisions.md D6).
const String kRatesBaseUrl = 'https://open.er-api.com/v6/latest';

/// SharedPreferences key holding the cached snapshot. The `_v1` suffix is the
/// cache schema version — bump it to invalidate every stored snapshot if the
/// serialized shape ever changes (caching.md).
const String kCachePrefsKey = 'cached_exchange_rates_v1';
