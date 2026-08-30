# Context

## What we are building

A **Currency Converter** mobile app in Flutter.

- The user enters a **USD amount**.
- The app shows the converted value in **5 target currencies**: EUR, GBP, JPY,
  AUD, CAD.
- Conversion uses **real exchange rates** fetched from a free public API.
- Rates are **cached locally** so the app does not hit the API on every
  keystroke.
- Network and API failures are **handled explicitly and gracefully**.

## Who it is for

Reviewers evaluating an engineer take-home. They care, in order, about:

1. **Architecture** — clear layers (data / logic / UI), easy to add currencies,
   easy to swap the API, understandable folder structure.
2. **Error handling** — no internet, API 500, recoverable vs non-recoverable.
3. **Caching strategy** — when used, when invalidated, offline = stale vs fail.
4. **Testing** — a test that proves something, not a test that always passes.
5. **Communication** — the README explains the reasoning and trade-offs.

## Hard limits

- Scope is a **2-hour** take-home. Simple and explained beats complex and
  silent. Do **not** over-engineer.
- State management is capped at `Provider` / `ValueNotifier` / built-in by the
  brief. This pack goes with **built-in `ChangeNotifier`** and adds no state
  package (`riverpod`, `bloc`, `get`, `mobx` are out; `provider` is allowed by
  the brief but unnecessary at this size). See [`decisions.md`](decisions.md) D3
  and [`tech-stack.md`](tech-stack.md).
- Minimal UI is fine. No pixel-perfect design, no theming system, no animations.
- Not every edge case needs handling — but the ones named in
  [`error-handling.md`](error-handling.md) do.

## Assumptions (fixed — do not revisit)

- A free API tier exists and requires no paid key. See [`tech-stack.md`](tech-stack.md).
- The user has internet most of the time.
- Single user, single device. No auth, no accounts, no multi-user concerns.
- Base currency is always **USD**. Targets are the fixed list of 5 above.
- Persistence beyond a session is limited to the rate cache (SharedPreferences).
- Platform: any Flutter target (the brief names none); code stays
  platform-agnostic. Verify on whatever device/emulator is available.

## Out of scope

- Choosing the base currency, or arbitrary currency pairs.
- Historical rates, charts, trends.
- Localisation / i18n, currency-symbol formatting beyond a basic prefix.
- Background refresh, push updates, websockets.
- CI configuration, analytics, crash reporting.
