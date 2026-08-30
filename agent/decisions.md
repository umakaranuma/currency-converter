# Decisions

The assignment leaves five trade-offs open. They are resolved here. The agent
**MUST** follow these and **MUST NOT** re-open them (R1.3). The reasoning is
copied into the project README (that is a graded deliverable).

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

- Conversion is `amount * rate` over 5 held values — synchronous, instant. The
  controller keeps the rates in memory after the first load, so typing never
  calls the repository, cache, or network. An optional ~300 ms debounce on
  recompute is allowed but unnecessary.
