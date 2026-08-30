# Features

Functional requirements. Implement top to bottom. Each item has an ID, a
priority, and acceptance criteria (AC). Priorities: **P0** = must ship,
**P1** = ship if the P0 set is solid, **P2** = only with spare time.

---

## F1 — Enter a USD amount (P0)

A single text field where the user types the amount in USD.

- AC1 The field accepts digits and one decimal separator. Reject other input
  (use `keyboardType: TextInputType.numberWithOptions(decimal: true)` plus an
  input formatter).
- AC2 Empty field is treated as `0` (or shows no results), not an error.
- AC3 Invalid/partial input (e.g. `"."`, `"1.2.3"`) does not crash and does not
  throw; it is treated as `0` until valid.
- AC4 The base currency **USD** is shown as a fixed, non-editable label next to
  the field.
- AC5 Very large numbers do not overflow or freeze the UI.

## F2 — Show conversions to 5 currencies (P0)

Below the input, a list showing the converted amount for **EUR, GBP, JPY, AUD,
CAD**.

- AC1 Order and set are fixed by the constant currency list in
  [`architecture.md`](architecture.md) / `core/constants`.
- AC2 Each row shows: currency code, converted amount, and the per-unit rate
  used (e.g. `1 USD = 0.92 EUR`).
- AC3 Converted amount = `usdAmount * rate`, computed from **cached** rates
  (see [`caching.md`](caching.md)). Rate math lives in the domain layer, not
  the widget (R2.2).
- AC4 Amounts are displayed with a sensible fixed number of decimals (2 for
  EUR/GBP/AUD/CAD, 0 for JPY). This formatting rule lives in one place.
- AC5 Results update **as the user types**, with no network call per keystroke
  (R4.1). A short debounce (≈300 ms) on the recompute is acceptable but not
  required since the math is local.

## F3 — Fetch real exchange rates (P0)

On the events listed in [`caching.md`](caching.md), fetch USD-based rates from
the API in [`tech-stack.md`](tech-stack.md).

- AC1 Exactly one datasource class performs the HTTP call and JSON parsing.
- AC2 The response is mapped to a typed model, then to a domain entity
  (`Map<String, double>` of code → rate, plus a timestamp).
- AC3 Only the 5 needed rates are kept; the rest of the payload is ignored.
- AC4 A successful fetch **writes through** to the cache immediately (R4.3).
- AC5 The request uses the configured timeout (R4.5).

## F4 — Cache rates locally (P0)

- AC1 Rates + fetch timestamp are persisted via `shared_preferences`.
- AC2 On app start, the repository loads the cache before deciding whether to
  fetch.
- AC3 Freshness is decided by comparing `now - timestamp` to the TTL constant.
- AC4 Full behaviour, invalidation, and offline policy are specified in
  [`caching.md`](caching.md) — implement exactly that.

## F5 — Loading state (P0)

- AC1 While the first fetch (no cache yet) is in flight, show a loading
  indicator instead of an empty/zero list.
- AC2 A background refresh while cached data is already on screen **MUST NOT**
  replace the list with a spinner; show a subtle inline refreshing hint
  instead.

## F6 — Error states (P0)

Driven by the typed errors in [`error-handling.md`](error-handling.md).

- AC1 **Offline / timeout, cache available:** keep showing cached results; show
  a dismissible banner "You're offline — showing rates from {relative time}".
- AC2 **Offline / timeout, no cache:** full-screen error with an icon, the
  message "No internet connection and no saved rates yet", and a **Retry**
  button.
- AC3 **API error (non-200 / bad body), cache available:** same as AC1 but the
  message names a server problem, not connectivity.
- AC4 **API error, no cache:** full-screen error naming a server problem, with
  **Retry**.
- AC5 Retry re-runs the fetch and transitions through the loading state.

## F7 — Manual refresh (P1)

- AC1 A refresh affordance (app-bar icon or pull-to-refresh) forces a fetch
  regardless of TTL.
- AC2 It reuses the same fetch path as F3 and the same error handling as F6.

## F8 — "Last updated" indicator (P1)

- AC1 Somewhere visible, show when the displayed rates were fetched, as a
  relative time ("updated 12 min ago"). Recompute from the cache timestamp.

## F9 — Offline awareness on launch (P2)

- AC1 If the app launches offline but has a valid (even if stale) cache, go
  straight to showing cached data with the offline banner — do not show the
  error screen.

## Non-functional expectations

- The app builds and runs on Android with `flutter run`.
- No jank while typing: the recompute is synchronous local math over 5 entries.
- No uncaught exceptions in the console during normal use or during any of the
  F6 scenarios.
