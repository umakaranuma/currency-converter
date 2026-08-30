# Error Handling

Errors are **typed**. No returning `null` for failure, no throwing bare
`Exception`, no `throw 'string'` (R5.1).

## Exception hierarchy (`lib/core/errors.dart`)

```dart
sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;
}

/// Connectivity problem: device offline, DNS failure, connection reset, or the
/// request exceeded kRequestTimeout. Recoverable — retrying later may succeed.
class NetworkException extends AppException {
  const NetworkException([super.message = 'No internet connection']);
}

/// The server was reached but the response is unusable: non-200 status, body is
/// not the expected JSON, `result` != "success", or a required rate is missing.
/// Recoverable by retry, but not caused by the user's connection.
class ApiException extends AppException {
  const ApiException(super.message, {this.statusCode});
  final int? statusCode;
}

/// No usable cached data exists when it was needed (first run + fetch failed,
/// or the stored blob is corrupt). Non-recoverable without a successful fetch.
class CacheMissException extends AppException {
  const CacheMissException([super.message = 'No saved rates available']);
}
```

Using a `sealed` class lets the controller `switch` exhaustively over failure
types when picking a UI state.

## Where each is thrown

| Layer | Condition | Throws |
|---|---|---|
| remote datasource | `SocketException`, `TimeoutException`, connection-level `ClientException` | `NetworkException` |
| remote datasource | status != 200 | `ApiException(statusCode: ...)` |
| remote datasource | body not JSON / `result != "success"` / target rate missing | `ApiException('Unexpected response from rates service')` |
| local datasource | key absent | returns `null` (not an exception) |
| local datasource | stored JSON fails to parse | returns `null`, logs once |
| repository | fetch failed **and** no cache | rethrows `NetworkException` / `ApiException`, or `CacheMissException` if cache was corrupt |

The repository **catches** `NetworkException` / `ApiException` when a cache
exists and returns stale data instead of throwing (see
[`caching.md`](caching.md) step 3).

## Mapping to UI (in `ConverterController` / `converter_page`)

| Result from repository | View state | UI (see `features.md` F5/F6) |
|---|---|---|
| Fresh or freshly-fetched rates | `ready`, `isStale = false` | List + "updated just now" |
| Stale rates, `lastError is NetworkException` | `ready`, `isStale = true`, `isOffline = true` | List + amber banner: *You're offline — showing rates from {time} ago* |
| Stale rates, `lastError is ApiException` | `ready`, `isStale = true` | List + amber banner: *Rates service is unavailable — showing rates from {time} ago* |
| `NetworkException` thrown (no cache) | `error` | Full screen: *No internet connection and no saved rates yet.* + **Retry** |
| `ApiException` thrown (no cache) | `error` | Full screen: *The rates service is having problems. Please try again.* + **Retry** |
| `CacheMissException` | `error` | Same as the API-error screen + **Retry** |

## Rules

- Recoverable (`NetworkException`, `ApiException`) → always offer **Retry**.
- Non-recoverable-right-now (`CacheMissException`) → also Retry (a fetch is the
  only cure), but copy makes clear there is no saved data.
- Never show a raw exception `toString()` or stack trace to the user.
- Never collapse all of these into one identical snackbar (R5.5) — the banner /
  screen copy must differ by type.
- Log unexpected errors once to the console with `debugPrint`; do not swallow
  silently.
- The amount parser never throws — bad input becomes `0`.
