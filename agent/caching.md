# Caching Strategy

## Storage

- One key in `SharedPreferences`: `kCachePrefsKey`
  (`"cached_exchange_rates_v1"`).
- Value: a JSON string of
  `{ "base": "USD", "rates": { "EUR": 0.92, ... }, "fetchedAt": <unixMillis> }`.
- The `_v1` suffix is the schema version — bump it to invalidate all old caches
  if the shape ever changes.

## TTL

**`kCacheTtl = 1 hour`.** Rationale is in [`decisions.md`](decisions.md) (D1):
FX mid-market rates move fractions of a percent intra-hour; a converter demo
does not need tick-level accuracy, and 1 hour keeps API usage trivial while
never showing rates a user would call "wrong". Freshness check:

```dart
bool isStale(Duration ttl) => DateTime.now().difference(fetchedAt) >= ttl;
```

## Read path — `RatesRepositoryImpl.getRates({forceRefresh = false})`

```
1. cached = local.read()            // may be null
2. if !forceRefresh && cached != null && !cached.isStale(kCacheTtl):
       return cached                 // FRESH HIT — no API call  (this is the tested path, R6.2)
3. try:
       remote = await remoteDatasource.fetch()   // network + API
       await local.write(remote)                  // write-through
       return remote
   catch NetworkException or ApiException as e:
       if cached != null:
           return cached.copyWith(staleServed: true, lastError: e)  // STALE FALLBACK
       else:
           rethrow                                                   // HARD FAIL
```

Key points:

- Step 2 is the only path that returns without any I/O beyond one prefs read.
  Typing in the amount field never even calls `getRates` again — the controller
  already holds the rates and just re-runs `ConversionService.convert`.
- Step 3 always **writes through** on success (R4.3 / F3.AC4).
- On failure with a cache, we **serve stale** and attach the error so the UI can
  show the right banner (F6.AC1/AC3). We do **not** throw.
- On failure with no cache, we **throw** the typed exception (F6.AC2/AC4).

## When the cache is used

| Situation | Behaviour |
|---|---|
| App launch, cache fresh | Serve cache, no network |
| App launch, cache stale, online | Fetch, write-through, serve fresh |
| App launch, cache stale, offline | Serve stale cache + offline banner |
| App launch, no cache, offline | Error screen + Retry |
| Typing in amount field | Recompute locally from held rates — never touches cache or network |
| Manual refresh (F7) | `forceRefresh: true` → always fetch; on failure fall back to stale/error as above |
| Fetch succeeds | Overwrite cache entirely (no merge) |

## When the cache is invalidated

- **Time:** older than `kCacheTtl` → treated as stale (still usable as offline
  fallback, but a refresh is attempted first).
- **Schema:** `kCachePrefsKey` version suffix changes → old key is simply never
  read again.
- **Corrupt data:** if `local.read()` fails to parse, treat as no cache (return
  null, log once) — do not crash.
- There is **no** manual "clear cache" feature (out of scope).

## Offline policy (explicit)

- **Show stale data, do not fail**, whenever any cache exists — with a visible
  "offline / showing rates from X ago" banner so the user is never misled.
- **Only fail hard** (error screen) when there is genuinely nothing to show.
- Staleness and offline are surfaced, never silent (R5.3).
