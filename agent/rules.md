# Rules

Non-negotiable constraints for the implementing agent. Read this before writing
any code. Keyword meaning is defined in [`README.md`](README.md).

## R1 — Scope discipline

- R1.1 The agent **MUST** build only what this spec pack describes. No extra
  features, no speculative abstraction "for later".
- R1.2 The agent **MUST NOT** add a feature that is listed as out of scope in
  [`context.md`](context.md).
- R1.3 When a choice is already made in [`decisions.md`](decisions.md), the
  agent **MUST** follow it and **MUST NOT** re-litigate it in code or comments.
- R1.4 "Simple + explained" beats "complex + silent". If an abstraction is not
  used by this app today, do not add it.

## R2 — Architecture

- R2.1 The app **MUST** have clear layers: **data** (API + cache), **domain**
  (business logic / entities), **presentation** (UI). See
  [`architecture.md`](architecture.md).
- R2.2 Business logic **MUST NOT** live in widget files. A widget may call a
  controller/repository; it may not perform HTTP, JSON parsing, cache reads, or
  rate math itself.
- R2.3 All network access **MUST** be behind a single datasource class so it is
  mockable and swappable.
- R2.4 Dependencies point **inward**: presentation → domain → data abstractions.
  Domain **MUST NOT** import Flutter (`package:flutter/...`) or `http`.
- R2.5 Adding a 6th target currency **MUST** be a change to one constant/list,
  not a change across many files.
- R2.6 Swapping the exchange-rate API **MUST** be possible by writing one new
  datasource implementation, with no change to domain or presentation.

## R3 — State management

- R3.1 The brief caps this at `Provider` / `ValueNotifier` / built-in. The agent
  **MUST NOT** add `riverpod`, `bloc`, `get`, `mobx`, or any heavier state
  package. The `provider` package is permitted by the brief but **SHOULD NOT**
  be added — one screen does not need it (see [`decisions.md`](decisions.md) D3).
- R3.2 State **MUST** be exposed with a built-in `ChangeNotifier` (or
  `ValueNotifier`) and consumed with `ListenableBuilder` /
  `ValueListenableBuilder` / `AnimatedBuilder`.
- R3.3 The UI **MUST** render three explicit states: **loading**, **data**
  (with an "offline / stale" variant), and **error**.

## R4 — Networking & caching

- R4.1 The app **MUST NOT** make an API call on every keystroke. Typing in the
  amount field recomputes results from **already-cached rates** only.
- R4.2 A network fetch of rates happens only on: first launch with no cache,
  cache older than the TTL, or an explicit user refresh. See
  [`caching.md`](caching.md).
- R4.3 Cached rates **MUST** be persisted with `shared_preferences` and survive
  an app restart.
- R4.4 Every cache entry **MUST** store a fetch timestamp so freshness can be
  evaluated.
- R4.5 The HTTP client **MUST** use a finite timeout (see
  [`tech-stack.md`](tech-stack.md)); an unbounded request is a bug.

## R5 — Error handling

- R5.1 Errors **MUST** be modelled as **typed exceptions**, not raw strings or
  bare `Exception`. See [`error-handling.md`](error-handling.md).
- R5.2 The code **MUST** distinguish **network** failures (offline, timeout)
  from **API** failures (non-200, malformed body) from **cache** failures
  (no data available).
- R5.3 On a failed refresh **with** a usable cache, the app **MUST** keep
  showing cached values plus a non-blocking notice — it **MUST NOT** blank the
  screen or crash.
- R5.4 On a failed fetch with **no** cache, the app **MUST** show a clear error
  state with a retry action.
- R5.5 The agent **MUST NOT** reduce all error handling to a single toast /
  snackbar. The UI must convey which kind of problem occurred (offline vs
  server vs no cached data).
- R5.6 No secrets in the repo. If the chosen API needs a key, read it from
  `--dart-define` and document it; do not commit it.

## R6 — Testing

- R6.1 There **MUST** be at least one meaningful automated test. See
  [`testing.md`](testing.md).
- R6.2 The primary test **MUST** prove caching behaviour: a fresh cache is
  served **without** calling the API. The test **MUST** fail if the caching
  branch is removed.
- R6.3 Tests **MUST NOT** hit the real network. Datasources are mocked/faked.
- R6.4 The agent **MUST NOT** write tests that mock everything and can never
  fail.

## R7 — Code quality

- R7.1 `flutter analyze` **MUST** pass with zero issues under the existing
  `analysis_options.yaml` (`flutter_lints`).
- R7.2 `flutter test` **MUST** pass.
- R7.3 Constants (currency list, TTL, base URL, timeout) **MUST** live in one
  `core/constants` location, not scattered as literals.
- R7.4 Public classes and non-obvious decisions **SHOULD** have a short doc
  comment. Trade-offs go in the README, not in long inline essays.
- R7.5 The default counter app in `lib/main.dart` and the default
  `test/widget_test.dart` **MUST** be removed/replaced.

## R8 — Deliverables

- R8.1 The project `README.md` **MUST** answer every question in
  [`deliverables.md`](deliverables.md).
- R8.2 If something was cut for time, the README **MUST** say so and say what
  would come next. Priority when time runs out: **README > test > extra
  features**.

## Red flags — automatic fail if present

- 🚩 No error handling, or all errors collapsed into toast messages.
- 🚩 All logic in UI files; nothing is unit-testable.
- 🚩 No explanation of choices anywhere.
- 🚩 Tests that assert nothing meaningful / always pass.
- 🚩 Hardcoded rates, URLs, or the currency list duplicated across files.
- 🚩 Happy-path only — no handling for API failure or offline.

## Green flags — aim for all of these

- ✅ Clear layer separation, dependency direction respected.
- ✅ Caching with a written rationale (TTL, invalidation, offline policy).
- ✅ Custom exception types, not strings.
- ✅ A test that would break if the caching logic broke.
- ✅ README explains the *why*, including at least one "I chose X over Y
  because…".
