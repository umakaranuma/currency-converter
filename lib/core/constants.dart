/// App-wide configuration. Every tunable value the assignment cares about
/// (currency catalogue, cache TTL, request timeout, API base URL, storage keys)
/// lives here so it can be changed in one place instead of being scattered as
/// literals — see `agent/rules.md` R7.3.
library;

/// The only base currency this app converts *from*. Fixed by scope
/// (`agent/decisions.md` D8) — the amount is always entered in USD.
const String kBaseCurrency = 'USD';

/// The full catalogue of currencies the app can convert to. The user picks and
/// orders a subset of these on the currency-picker screen; the picked set is
/// persisted (see [kCurrencyPrefsKey]). The rate fetch keeps *all* of these so
/// changing the selection never needs a network call.
///
/// Extending the app to "50 currencies" is a one-line change here (rules.md
/// R2.5) plus a matching [kCurrencyInfo] entry.
const List<String> kSupportedCurrencies = <String>[
  'EUR', 'GBP', 'JPY', 'AUD', 'CAD', 'CHF', 'CNY', 'HKD', 'NZD', 'SEK',
  'KRW', 'SGD', 'NOK', 'MXN', 'INR', 'BRL', 'ZAR', 'TRY', 'AED', 'DKK',
  'PLN', 'THB', 'IDR', 'HUF', 'CZK', 'ILS', 'PHP', 'MYR', 'SAR',
];

/// The selection a fresh install starts with, in display order. Also what
/// "Reset" on the picker restores.
const List<String> kDefaultSelection = <String>['EUR', 'GBP', 'JPY', 'AUD', 'CAD'];

/// Currencies conventionally shown with no decimal places. Everything else uses
/// two. Consumed only by `core/formatting`.
const Set<String> kZeroDecimalCurrencies = <String>{'JPY', 'KRW'};

/// Human-facing metadata (full name + flag emoji) for the base and every
/// supported currency. Purely presentational — the conversion logic only needs
/// the codes. Every code in [kSupportedCurrencies] must have an entry here.
const Map<String, ({String name, String flag})> kCurrencyInfo =
    <String, ({String name, String flag})>{
  'USD': (name: 'US Dollar', flag: '\u{1F1FA}\u{1F1F8}'),
  'EUR': (name: 'Euro', flag: '\u{1F1EA}\u{1F1FA}'),
  'GBP': (name: 'British Pound', flag: '\u{1F1EC}\u{1F1E7}'),
  'JPY': (name: 'Japanese Yen', flag: '\u{1F1EF}\u{1F1F5}'),
  'AUD': (name: 'Australian Dollar', flag: '\u{1F1E6}\u{1F1FA}'),
  'CAD': (name: 'Canadian Dollar', flag: '\u{1F1E8}\u{1F1E6}'),
  'CHF': (name: 'Swiss Franc', flag: '\u{1F1E8}\u{1F1ED}'),
  'CNY': (name: 'Chinese Yuan', flag: '\u{1F1E8}\u{1F1F3}'),
  'HKD': (name: 'Hong Kong Dollar', flag: '\u{1F1ED}\u{1F1F0}'),
  'NZD': (name: 'New Zealand Dollar', flag: '\u{1F1F3}\u{1F1FF}'),
  'SEK': (name: 'Swedish Krona', flag: '\u{1F1F8}\u{1F1EA}'),
  'KRW': (name: 'South Korean Won', flag: '\u{1F1F0}\u{1F1F7}'),
  'SGD': (name: 'Singapore Dollar', flag: '\u{1F1F8}\u{1F1EC}'),
  'NOK': (name: 'Norwegian Krone', flag: '\u{1F1F3}\u{1F1F4}'),
  'MXN': (name: 'Mexican Peso', flag: '\u{1F1F2}\u{1F1FD}'),
  'INR': (name: 'Indian Rupee', flag: '\u{1F1EE}\u{1F1F3}'),
  'BRL': (name: 'Brazilian Real', flag: '\u{1F1E7}\u{1F1F7}'),
  'ZAR': (name: 'South African Rand', flag: '\u{1F1FF}\u{1F1E6}'),
  'TRY': (name: 'Turkish Lira', flag: '\u{1F1F9}\u{1F1F7}'),
  'AED': (name: 'UAE Dirham', flag: '\u{1F1E6}\u{1F1EA}'),
  'DKK': (name: 'Danish Krone', flag: '\u{1F1E9}\u{1F1F0}'),
  'PLN': (name: 'Polish Zloty', flag: '\u{1F1F5}\u{1F1F1}'),
  'THB': (name: 'Thai Baht', flag: '\u{1F1F9}\u{1F1ED}'),
  'IDR': (name: 'Indonesian Rupiah', flag: '\u{1F1EE}\u{1F1E9}'),
  'HUF': (name: 'Hungarian Forint', flag: '\u{1F1ED}\u{1F1FA}'),
  'CZK': (name: 'Czech Koruna', flag: '\u{1F1E8}\u{1F1FF}'),
  'ILS': (name: 'Israeli Shekel', flag: '\u{1F1EE}\u{1F1F1}'),
  'PHP': (name: 'Philippine Peso', flag: '\u{1F1F5}\u{1F1ED}'),
  'MYR': (name: 'Malaysian Ringgit', flag: '\u{1F1F2}\u{1F1FE}'),
  'SAR': (name: 'Saudi Riyal', flag: '\u{1F1F8}\u{1F1E6}'),
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

/// SharedPreferences key for the cached rate snapshot. The `_v1` suffix is the
/// cache schema version — bump it to invalidate every stored snapshot if the
/// serialized shape ever changes (caching.md).
const String kCachePrefsKey = 'cached_exchange_rates_v1';

/// SharedPreferences key for the user's picked + ordered currency list. A
/// *separate slot* from the rate cache — changing the selection never touches
/// cached rates (decisions.md D8).
const String kCurrencyPrefsKey = 'currency_selection_v1';

/// SharedPreferences key for the chosen theme mode (`system` / `light` / `dark`).
const String kThemePrefsKey = 'theme_mode_v1';
