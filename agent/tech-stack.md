# Tech Stack

## Flutter / Dart

Use the SDK already pinned in `pubspec.yaml` (`sdk: ^3.12.2`). Material app.

## Packages (add to `pubspec.yaml`)

| Package | Scope | Why |
|---|---|---|
| `http` | dependency | Minimal, well-known HTTP client. `Client` is injectable and mockable. |
| `shared_preferences` | dependency | Assignment explicitly permits it for caching; enough for a single key-value blob. |
| `mocktail` | dev_dependency | Mocks for the repository/datasource unit tests. No code-gen, unlike `mockito`. |

Do **not** add anything else. In particular no `dio`, no `connectivity_plus`
(detect offline by catching `SocketException` from the request itself — a
connectivity check is a race anyway), no state-management package (R3.1).

`flutter_lints` and `flutter_test` are already present — keep them.

## Exchange-rate API

**Primary: `open.er-api.com` (exchangerate-api.com's free, key-less endpoint).**

```
GET https://open.er-api.com/v6/latest/USD
```

Response shape (trimmed):

```json
{
  "result": "success",
  "time_last_update_unix": 1740700801,
  "base_code": "USD",
  "rates": { "EUR": 0.92, "GBP": 0.79, "JPY": 149.3, "AUD": 1.52, "CAD": 1.36, ... }
}
```

- No API key, no signup → nothing secret to manage, reviewer can run it as-is.
- `result` must equal `"success"`; otherwise treat as an API error.
- Read the 5 codes in `kTargetCurrencies` out of `rates`; ignore the rest.
- If any target code is missing from `rates`, treat as an API error (malformed).

### Key handling (only if a keyed API is substituted)

If the agent chooses a keyed provider instead, the key **MUST** come from
`--dart-define=RATES_API_KEY=...` read via
`String.fromEnvironment('RATES_API_KEY')`, and the README must document the run
command. Never commit a key (R5.6). The primary endpoint above avoids this
entirely.

## HTTP configuration

- Timeout: **10 seconds** (`kRequestTimeout`), applied with
  `httpClient.get(uri).timeout(kRequestTimeout)`.
- Treat these as **network** errors: `SocketException`, `TimeoutException`,
  `http.ClientException` with a connection message.
- Treat these as **API** errors: status code not 200, `result != "success"`,
  JSON parse failure, missing expected fields.

## State management (built-in only)

- One `ConverterController extends ChangeNotifier` in
  `presentation/controllers/`.
- It holds: current `amount` (parsed double), and a `ConverterViewState` that is
  one of `loading` / `ready` / `error`, carrying the rates, the computed
  results, an `isStale`/`isOffline` flag, the `fetchedAt` time, and (for error)
  a typed failure.
- Widgets rebuild via a single `ListenableBuilder` (or
  `AnimatedBuilder`) at the page root. No `setState` for shared state; local
  `setState` is fine for pure widget-local concerns (e.g. banner dismissed).

## Constants (`lib/core/constants.dart`)

```dart
const String kBaseCurrency = 'USD';
const List<String> kTargetCurrencies = ['EUR', 'GBP', 'JPY', 'AUD', 'CAD'];
const Duration kCacheTtl = Duration(hours: 1);      // see caching.md / decisions.md
const Duration kRequestTimeout = Duration(seconds: 10);
const String kRatesBaseUrl = 'https://open.er-api.com/v6/latest';
const String kCachePrefsKey = 'cached_exchange_rates_v1';
```
