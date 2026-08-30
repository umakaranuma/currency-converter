# Testing

Aim: a small number of tests that **prove behaviour**. A test that passes with
the logic deleted is worthless (R6.4).

## Must-have test (P0) — caching behaviour

**File:** `test/data/rates_repository_impl_test.dart`

Uses `mocktail` to fake both datasources. No real network, no real prefs.

### T1 — fresh cache is served without calling the API  *(this is R6.2)*

```
Arrange: local.read() → ExchangeRates(fetchedAt: now - 5 min)   // within 1h TTL
         remote.fetch() → registered but should not be invoked
Act:     repo.getRates()
Assert:  result rates == cached rates
         verifyNever(() => remote.fetch())
         verify(() => local.read()).called(1)
```

If the "is it stale?" check is removed so the repo always fetches, `verifyNever`
fails. That is the point.

### T2 — stale cache triggers a fetch and writes through

```
Arrange: local.read() → ExchangeRates(fetchedAt: now - 2 h)     // past TTL
         remote.fetch() → fresh ExchangeRates
Act:     repo.getRates()
Assert:  result == fresh rates
         verify(() => remote.fetch()).called(1)
         verify(() => local.write(fresh)).called(1)
```

### T3 — offline with a stale cache serves stale, does not throw

```
Arrange: local.read() → stale ExchangeRates
         remote.fetch() → throws NetworkException
Act:     repo.getRates()
Assert:  returns the stale rates
         result.staleServed == true   (and lastError is NetworkException)
         does NOT throw
```

### T4 — offline with no cache rethrows NetworkException

```
Arrange: local.read() → null
         remote.fetch() → throws NetworkException
Act/Assert: expect(() => repo.getRates(), throwsA(isA<NetworkException>()))
```

## Should-have test (P1) — conversion math

**File:** `test/domain/conversion_service_test.dart` — plain Dart, no mocks.

- `convert(100, {EUR: 0.92, JPY: 149.0})` → `{EUR: 92.0, JPY: 14900.0}`.
- `convert(0, rates)` → all zeros.
- Empty / unavailable rates → empty map, no throw.

## Should-have test (P1) — remote datasource error mapping

**File:** `test/data/rates_remote_datasource_test.dart` — inject a mocked
`http.Client`.

- 200 + valid body → parsed `ExchangeRates` with only the 5 target codes.
- 500 → `ApiException` with `statusCode == 500`.
- 200 + `{"result":"error"}` → `ApiException`.
- client throws `SocketException` → `NetworkException`.

## Explicitly NOT tested (and why — put this in the README)

- **Widget / golden tests.** UI is intentionally minimal and still in flux at
  the 2-hour mark; pinning pixels now tests nothing durable.
- **`SharedPreferences` implementation.** It is a thin adapter over a trusted
  package; testing it tests the framework. The repository tests fake it.
- **Real API contract.** No live network in CI. Datasource tests cover our
  parsing/error mapping against representative payloads.
- **`main.dart` wiring.** Trivial constructor calls; a smoke test would assert
  almost nothing.

## Bar to clear

- `flutter test` passes.
- `flutter analyze` clean.
- Removing the freshness check in the repository makes **T1 fail** — verify this
  manually once.
