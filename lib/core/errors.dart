/// Typed error model for the whole app.
///
/// The assignment asks us to *distinguish* failure kinds rather than collapse
/// them into one string/toast (rules.md R5). `AppException` is `sealed` so the
/// presentation layer can `switch` over every case exhaustively and the compiler
/// will flag a missing branch.
library;

/// Base type for every expected, handled failure in the app.
sealed class AppException implements Exception {
  const AppException(this.message);

  /// Human-readable, already safe to surface in the UI (no stack traces).
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// Connectivity problem: device offline, DNS failure, connection reset, or the
/// request exceeded [kRequestTimeout]. **Recoverable** — retrying later may
/// succeed, and stale cached data (if any) is still worth showing.
class NetworkException extends AppException {
  const NetworkException([super.message = 'No internet connection']);
}

/// The server was reached but the response is unusable: a non-200 status, a body
/// that is not the expected JSON, `result != "success"`, or a required rate is
/// missing. **Recoverable** by retry, but not caused by the user's connection.
class ApiException extends AppException {
  const ApiException(super.message, {this.statusCode});

  /// HTTP status code when the failure was a bad response, else `null`.
  final int? statusCode;
}

/// No usable rates could be produced: first run with no cache and the fetch
/// failed, or the stored snapshot was corrupt and the fetch also failed.
/// Not recoverable without a successful network fetch.
class CacheMissException extends AppException {
  const CacheMissException([super.message = 'No saved rates available']);
}
