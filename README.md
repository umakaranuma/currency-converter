# USD Currency Converter

A small Flutter app: type a USD amount, see it converted to EUR, GBP, JPY, AUD
and CAD using real exchange rates, with local caching and explicit handling of
network / API failures.

The functional spec this was built from lives in [`agent/`](agent/) — one
markdown file per concern (rules, features, architecture, caching, error
handling, testing, decisions).

## Run it

```bash
flutter pub get
flutter run
```

```bash
flutter test       # 15 tests
flutter analyze    # clean
```

No API key or configuration is needed — the app uses exchangerate-api.com's
key-less `open.er-api.com` endpoint.

---

## 1. Walk me through the architecture

Three layers, dependencies point inward (`presentation → domain → data`):

```
lib/
├── main.dart                     composition root: builds the object graph
├── core/
│   ├── constants.dart            currency set + display metadata, TTL, timeout, URL, cache key
│   ├── errors.dart               sealed AppException hierarchy
│   ├── formatting.dart           money / rate / "x ago" string helpers
│   └── theme/                    design system: spacing, colour tokens, light+dark ThemeData
├── data/                         everything I/O
│   ├── datasources/
│   │   ├── rates_remote_datasource.dart   HTTP + JSON, maps failures to exceptions
│   │   └── rates_local_datasource.dart    SharedPreferences read/write
│   ├── models/rates_dto.dart     API JSON  ⇄  cache JSON  ⇄  domain entity
│   └── repositories/rates_repository_impl.dart   the cache-vs-network policy
├── domain/                       pure Dart, no Flutter / no http
│   ├── entities/exchange_rates.dart        snapshot + fetchedAt + isStale(ttl)
│   ├── repositories/rates_repository.dart  the interface presentation depends on
│   └── services/conversion_service.dart    amount × rate
└── presentation/
    ├── controllers/converter_controller.dart   ChangeNotifier + immutable view state
    ├── pages/converter_page.dart               loading / error / ready switch
    └── widgets/                                amount input, row, status banner
```

**Why these layers.** The two things being graded — "is the logic testable?"
and "can you swap the API?" — both come from the same split: `domain` defines a
`RatesRepository` interface and plain entities; `data` implements it. The
repository and the conversion service are plain Dart, so they unit-test with no
widget harness. Swapping providers means writing one new
`RatesRemoteDataSource`; `domain` and `presentation` don't change.

**Why not full Clean Architecture.** No use-case classes, no DI container, no
`Either`/`Result` type. At this size those are boilerplate. Errors are modelled
as a `sealed` exception hierarchy instead of a result type — you still get
exhaustive handling (the `switch` in `converter_page.dart` won't compile if a
case is missed) without wrapping every call site.

**State management.** One `ChangeNotifier` (`ConverterController`) injected via
constructor in `main.dart`, observed by a single `ListenableBuilder`. The brief
allows the Provider package; one screen with one stream of state doesn't need
it. All parsing, fetch-timing and error-to-UI mapping lives in the controller,
never in widgets.

**Adding currencies** is a one-line edit to `kTargetCurrencies` in
`core/constants.dart`; nothing else hard-codes the list.

## 2. How does caching work?

- **Store:** a single JSON string under one SharedPreferences key
  (`cached_exchange_rates_v1`) — `{ base, rates, fetchedAt }`. It survives app
  restarts, so a cold launch while offline can still show data.
- **TTL: 1 hour** (`kCacheTtl`). Mid-market FX rates drift a fraction of a
  percent within an hour — invisible for a converter, and 1 h keeps API traffic
  to a handful of calls per session. 24 h risks a visibly wrong rate after a
  volatile day; no cache reintroduces per-launch latency and kills the offline
  story.
- **Read path** (`RatesRepositoryImpl.getRates`):
  1. read the cache;
  2. if it exists and `now - fetchedAt < 1 h` and the caller didn't force a
     refresh → **return it, no network call**;
  3. otherwise fetch → on success **write through** to the cache and return the
     fresh snapshot;
  4. on fetch failure **with** a cached snapshot → return the stale snapshot
     tagged with the error (no throw);
  5. on fetch failure **without** any cache → throw the typed exception.
- **Typing in the amount field never calls this.** The controller keeps the
  rates in memory and re-runs `ConversionService.convert` locally on each
  keystroke, so there is no per-keystroke I/O.
- **Invalidation:** by time (older than the TTL → refresh is attempted first);
  by schema (`_v1` suffix — bump it and old blobs are never read); a blob that
  fails to parse is deleted and treated as a miss.

## 3. What if there's no internet?

The rule is **show stale data, clearly labelled; only fail hard when there is
nothing to show.**

| Situation | What the user sees |
|---|---|
| Offline, cache present | The rates stay on screen; a dismissible amber banner: *"You're offline — showing rates from 20 min ago."* Pull-to-refresh / the refresh button retry. |
| API returned 500 / garbage, cache present | Same, with copy that blames the service, not the connection. |
| Offline, **no** cache (first run) | Full-screen state: *"No internet connection and no saved rates yet."* + **Retry**. |
| API failing, no cache | Full-screen state: *"The rates service is having problems."* + **Retry**. |

The distinction is carried by the `sealed AppException` type:
`NetworkException` (offline / timeout — recoverable),
`ApiException` (reached the server, response unusable — recoverable, carries the
status code), `CacheMissException` (nothing cached and the fetch failed — not
recoverable without a successful fetch). The remote datasource maps
`SocketException` / `TimeoutException` → `NetworkException` and non-200 /
malformed body → `ApiException`; the repository decides stale-fallback vs
throw; the controller maps the outcome to a view state; the page renders it.

## 4. What did you test, and what did you not?

**Tested** (`flutter test`, 15 cases):

- **`RatesRepositoryImpl`** (`test/data/rates_repository_impl_test.dart`) — the
  headline test. Both datasources are faked with `mocktail`:
  - fresh cache is served and **`remote.fetch()` is never called**
    (`verifyNever`) — delete the freshness check and this test fails;
  - stale cache → fetches and writes through;
  - offline + stale cache → returns the stale data tagged with the error,
    doesn't throw;
  - offline + no cache → rethrows `NetworkException`;
  - `forceRefresh` bypasses a fresh cache; an `ApiException` with a cache falls
    back.
- **`ConversionService`** — the arithmetic, zero/negative amount, empty rates.
- **`HttpRatesRemoteDataSource`** — with a mocked `http.Client`: happy body
  keeps only the 5 target codes; 500 → `ApiException(statusCode: 500)`;
  `result != "success"` → `ApiException`; non-JSON body → `ApiException`;
  `SocketException` → `NetworkException`.

**Not tested, on purpose:**

- **Widget / golden tests** — the UI is deliberately minimal and was still
  moving at the end; pinning it tests nothing durable.
- **The SharedPreferences adapter** — it's a thin wrapper over a trusted
  package; the repository tests fake it.
- **The live API** — no network in tests; the datasource tests cover our
  parsing and error mapping against representative payloads.
- **`main.dart` wiring** — three constructor calls; a smoke test would assert
  almost nothing.

## 5. If we needed 50 currencies + real-time updates

- **50 currencies:** the list is already a single constant, so that part is a
  data change. UI becomes a `ListView.builder` (already is) plus search/filter
  and probably grouping. The API returns all rates in one call, so no extra
  requests. Cache size is still trivial.
- **Real-time:** drop the TTL to seconds or move to a streaming source
  (websocket / SSE); push updates through the controller instead of fetching on
  demand; show per-rate freshness rather than one global timestamp; reconsider
  `ChangeNotifier` vs an explicit `Stream` on the repository. The layer split
  means this is a `data` + `controller` change, not a rewrite.

## 6. Why X over Y

- **`ChangeNotifier` over the Provider package** — one screen, one state object;
  a package would be ceremony. The controller is still a clean, testable seam.
- **`sealed` exceptions over `Either`/`Result`** — exhaustive handling from the
  compiler without wrapping every call and unwrapping at every use site.
- **Key-less `open.er-api.com` over a keyed provider** — nothing secret to
  manage, `git clone && flutter run` just works. A keyed provider would be one
  new datasource + a `--dart-define`.
- **1-hour TTL over 24 h or none** — see §2.
- **Stale-with-a-banner over hard-fail offline** — a converter is still useful
  with hour-old rates; a blank screen isn't. The banner keeps it honest.
- **`fetchedAt = our fetch time`, not the provider's publish time** — the TTL is
  about "how long since *we* asked", and the free endpoint only publishes daily,
  which would otherwise make every snapshot look stale.

## Design system

`lib/core/theme/` is a small token-based design system, documented in
[`agent/design-system.md`](agent/design-system.md):

- **`app_spacing.dart`** — one 4-point spacing scale and one radius scale;
  widgets use these, not raw numbers.
- **`app_colors.dart`** — an `AppColors` `ThemeExtension` for the semantic
  colours Material's `ColorScheme` doesn't model (success / warning / info
  triads, the header gradient, skeleton shimmer), defined for light **and**
  dark. Accessor: `context.appColors`.
- **`app_theme.dart`** — `AppTheme.light` / `AppTheme.dark`: a hand-built
  `ColorScheme` each (indigo primary, emerald accent), component themes
  (cards, inputs, buttons, banner), and one tuned type scale with tabular
  figures for the numbers.

`main.dart` sets `themeMode: ThemeMode.system`, so it follows the OS. No fonts,
image assets, or extra packages were added — it's pure Material 3, and every
colour/size comes from `Theme.of(context)`.

The UI itself: a gradient header, a floating amount card, flag-badged result
cards (tap to copy), a freshness pill / offline banner, skeleton rows on first
load, and a typed-per-error full-screen error state.

## Known cuts / what's next

- Error copy is in-code English strings — no localisation.
- The offline banner's "dismissed" flag is per-widget and resets on reason
  change; fine for one screen, wouldn't scale.
- No widget tests (see §4). First addition with more time would be a golden of
  each of the three view states.
- `ConverterController` is app-lifetime and never disposed — acceptable for a
  single root singleton, would matter if it became route-scoped.
