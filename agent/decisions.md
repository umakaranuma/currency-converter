# Decisions

The assignment's "Key Trade-off Questions" section leaves five decisions open
(D1–D5). Two further implementation decisions (D6–D7) are recorded below the
line. The agent **MUST** follow all of these and **MUST NOT** re-open them
(R1.3). The reasoning is copied into the project README (a graded deliverable).

---

## D1 — Cache TTL: **1 hour**

- **Options:** no cache / 1 h / 24 h.
- **Chosen:** 1 hour.
- **Why:** Mid-market FX rates drift ~0.1-0.5% within an hour — invisible to a
  casual converter user, and never "wrong" enough to matter. 1 h makes API
  traffic negligible (a handful of calls per session) while keeping numbers
  current. 24 h risks a visibly off rate after a volatile day; no cache
  reintroduces per-launch latency and defeats the offline story.
- **What breaks if rates move faster:** for a trading tool this would be far too
  long; you would drop to minutes and add a "rates as of" timestamp (we already
  show one) and a websocket/stream. Out of scope here.

## D2 — Offline behaviour: **show stale, clearly labelled; fail only with no data**

- **Options:** show stale / show error / crash.
- **Chosen:** serve the last cached rates whenever any cache exists, with a
  persistent "offline — rates from {N} ago" banner; show a full error screen
  with Retry only when there is no cache at all.
- **Why:** A converter is still useful with slightly old rates; a blank screen
  is not. The banner keeps it honest so the user is never silently misled.
  Crashing is never acceptable.

## D3 — State management: **built-in `ChangeNotifier` + `ListenableBuilder`**

- **Options:** Provider / ValueNotifier / plain widgets.
- **Chosen:** one `ChangeNotifier` controller, injected by constructor in
  `main.dart`, observed with a single `ListenableBuilder`.
- **Why:** One screen, one stream of state — a package would be pure ceremony.
  `ChangeNotifier` is still a clean, testable boundary (logic sits in the
  controller/repo, not widgets) and adds zero dependencies. The assignment
  explicitly caps state management at this level anyway.

## D4 — Architecture depth: **3-layer "lite" (data / domain / presentation)**

- **Options:** full three-layer Clean Arch / one file / middle ground.
- **Chosen:** middle ground — real `data` / `domain` / `presentation`
  separation and an abstract `RatesRepository`, but **no** usecase classes, no
  DI framework, no `Either`/`Result` type (typed exceptions instead).
- **Why:** The split is what makes the logic unit-testable and the API
  swappable — the things being graded. Usecases and a DI container are
  boilerplate that buys nothing at this size and would eat the time budget.

## D5 — Test focus: **repository (caching), then conversion math, then datasource mapping**

- **Options:** repository only / UI / both.
- **Chosen:** repository behaviour is the must-have (it is where the
  interesting logic — freshness, write-through, stale fallback — lives). Add
  conversion-math and datasource-error-mapping tests if time allows. No widget
  tests.
- **Why:** These tests fail if the real logic breaks. Widget tests on a
  deliberately minimal, still-changing UI would assert little and cost much.
  See [`testing.md`](testing.md) for the "not tested, and why" list.

---

## D6 — API choice: **`open.er-api.com` (key-less)**

- **Why:** exchangerate-api.com's open endpoint needs no signup or key, so
  there is nothing secret to manage and a reviewer can clone and run
  immediately. `fixer.io` and the keyed exchangerate-api tier are documented as
  the swap-in path (one new datasource) to demonstrate R2.6, but not used.

## D7 — No per-keystroke work beyond local math

- Conversion is `amount * rate` over the held rates — synchronous, instant. The
  controller keeps the rates in memory after the first load, so typing never
  calls the repository, cache, or network. An optional ~300 ms debounce on
  recompute is allowed but unnecessary.

---

# Decisions for the extension features (F10–F14)

## D8 — Currency selection is persisted state behind its own repository; base stays USD

- **What:** the shown currencies are a user-editable, ordered, persisted list
  (`CurrencyPreferences` entity + `CurrencyPreferencesRepository`), stored under
  a **separate** SharedPreferences key from the rate cache.
- **Why a repository, not just a value in the controller:** it keeps the
  add/remove/reorder/sanitize logic unit-testable with no widgets, and matches
  the existing `RatesRepository` shape so a new engineer sees one pattern.
- **Why base currency stays USD:** the brief says "user enters a USD amount".
  Making the base editable means per-base cache keys and a bigger caching story
  for little user value here — explicitly out of scope (kept as a README
  "what I'd do next" note instead).
- **Why a separate storage key:** changing the selection must never risk
  touching cached rates, and vice versa. Independent slots, independent schema
  versions.

## D9 — Fetch and cache the whole catalogue, not just the selected currencies

- **What:** `RatesDto.fromApiJson` keeps every `kSupportedCurrencies` code the
  feed provides (~30), and the cache stores all of them.
- **Why:** the payload already contains ~160 currencies, so keeping 30 instead
  of 5 costs nothing meaningful, and it means **adding a currency to the list
  never needs a network call** — the rate is already in memory (F10.AC6). This
  is the cleanest answer to the brief's "would it be hard to add 50 currencies?"
- **Missing-code policy:** a missing *default-selection* code = broken feed →
  `ApiException`. A missing exotic code is tolerated (that row just has no rate).

## D10 — Theme mode: manual toggle over its own tiny store

- **What:** `ThemeController` (ChangeNotifier) + `SettingsStore` (plain strings,
  no Flutter import in the data layer). `MaterialApp` reads `themeMode`.
- **Why separate from currency prefs and rate cache:** unrelated concern,
  unrelated lifetime, unrelated schema. One key, three states
  (`system`/`light`/`dark`), cycled by one button.
- **Why not a full settings screen:** one toggle is the whole surface; a screen
  would be ceremony (rules.md R1.4).

## D11 — `onReorderItem`, not the deprecated `onReorder`

- Flutter 3.44 deprecates `ReorderableListView.onReorder`. `CurrencyPreferences
  .reordered(old, new)` uses post-removal index semantics so the framework
  indices pass straight through with no `+1/-1` fixups.
