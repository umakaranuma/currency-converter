# Deliverables

## 1. The app

- Runs on Android with `flutter run`.
- Implements every **P0** item in [`features.md`](features.md).
- Satisfies every **MUST** in [`rules.md`](rules.md).
- `flutter analyze` clean, `flutter test` green.
- Default counter code and default widget test removed (R7.5).

## 2. At least one meaningful test

- The caching test (`test/data/rates_repository_impl_test.dart`, T1) is
  mandatory. See [`testing.md`](testing.md).

## 3. Project `README.md` (replace the current stub)

It **MUST** answer all of the following. Pull the reasoning straight from
[`decisions.md`](decisions.md).

1. **Walk me through your architecture.**
   - The `data` / `domain` / `presentation` layers, what lives in each, why the
     "lite" depth (D4), and the dependency direction.
   - A short folder tree.
2. **How does caching work?**
   - SharedPreferences blob + timestamp, 1 h TTL (D1), the read path
     (fresh hit → stale check → fetch + write-through → stale fallback), and
     what invalidates it. Reference [`caching.md`](caching.md).
3. **What if there's no internet?**
   - Serve stale cache with a visible banner; full error screen + Retry only
     when no cache exists (D2). Name the distinction between
     `NetworkException`, `ApiException`, `CacheMissException`.
4. **What did you test, and what did you not test, and why?**
   - Tested: repository caching/fallback, (if done) conversion math and
     datasource error mapping — because they break if the logic breaks.
   - Not tested: widget/golden, SharedPreferences adapter, live API, `main.dart`
     wiring — with the one-line reason each (see [`testing.md`](testing.md)).
5. **If we needed 50 currencies + real-time updates, what would change?**
   - Currencies: **already built.** The catalogue is one constant, the fetch
     keeps all of it, and the selection is user-editable + persisted behind
     `CurrencyPreferencesRepository` (F10–F12, decisions.md D8–D9). Going to 50
     is adding entries to `kSupportedCurrencies` / `kCurrencyInfo` — no other
     change; the picker already virtualizes with `ListView.builder` + search.
   - Real-time: drop TTL to seconds or move to a streaming endpoint / websocket,
     push updates through the controller, show per-rate freshness, reconsider
     `ChangeNotifier` vs a `Stream`-based approach.
   - Editable **base** currency was deliberately left out (README "next steps"):
     it needs per-base cache keys for little user value at this scope (D8).
6. **Why did you choose X over Y?** (at least one concrete trade-off)
   - e.g. `ChangeNotifier` over Provider (D3); typed exceptions over
     `Either`/`Result` (D4); key-less API over a keyed one (D6); 1 h TTL over
     24 h (D1). Frame as trade-offs, not "best practice".

Also include:

- **Run instructions:** `flutter pub get`, `flutter run`; `flutter test`.
- **Known cuts / next steps:** anything dropped for time and what you'd do next
  (R8.2). If time ran out, priority order was **README > test > extra
  features**.

## 4. Submission

- GitHub repo containing the code, the test(s), and the README.
- Commit in meaningful increments (happy path → caching → error handling →
  test + README) so the history shows the thought process.

## Definition of done

- [ ] `flutter analyze` → no issues
- [ ] `flutter test` → all pass, including the caching test
- [ ] Removing the freshness check makes the caching test fail (checked once)
- [ ] App shows conversions for the 5 currencies from a typed USD amount
- [ ] No API call while typing (verify: type with airplane mode off and watch
      there are no new network calls per keystroke)
- [ ] Offline with cache → stale data + banner; offline without cache → error +
      Retry
- [ ] API 500 path handled distinctly from the offline path
- [ ] README answers all six questions above
- [ ] Default Flutter counter app and default widget test are gone

### Extension features (F10–F14)

- [ ] Currency picker: add/remove persists across restart; last currency can't
      be removed; "Reset" restores the default five
- [ ] Search filters by code or name; the clear (×) button resets it
- [ ] Drag-to-reorder persists across restart
- [ ] Adding / removing / reordering a currency makes **no network call**
- [ ] Theme toggle cycles system → light → dark and persists across restart
- [ ] Clear (×) button on the amount field appears only when it has text
- [ ] The extension features each have logic in a repo/controller, not a widget
- [ ] `currency_preferences_test.dart` + `currency_preferences_repository_impl_test.dart`
      pass
