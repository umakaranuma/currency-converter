# Architecture

## Shape: 3-layer "lite"

Full Clean Architecture (datasources + models + repositories + entities +
usecases + DI container) is too heavy for a 2-hour converter. We use a trimmed
version that still gives testable logic and a swappable API:

```
presentation  →  domain  →  data
   (UI)          (logic)     (API + cache, behind an interface)
```

- **data** owns everything I/O: HTTP, JSON, SharedPreferences.
- **domain** owns the rules: freshness, conversion math, the abstract
  repository contract, and the typed entities. No Flutter, no `http`, no
  `shared_preferences` imports here.
- **presentation** owns widgets and one `ChangeNotifier` controller that calls
  the repository and exposes view state.

Wiring is done by plain constructor injection in `main.dart` — no DI package.

## Folder structure (create exactly this under `lib/`)

```
lib/
├── main.dart                     ← builds the object graph, runs the app
│
├── core/
│   ├── constants.dart            ← base currency, currency catalogue + default set,
│   │                               TTL, base URL, timeout, all storage keys
│   ├── errors.dart               ← exception hierarchy (see error-handling.md)
│   ├── formatting.dart           ← money / rate / relative-time string helpers (pure Dart)
│   └── theme/                    ← design system — app_spacing, app_colors, app_theme
│
├── data/
│   ├── datasources/
│   │   ├── rates_remote_datasource.dart   ← abstract + http implementation
│   │   └── rates_local_datasource.dart    ← abstract + shared_preferences implementation
│   ├── models/
│   │   └── rates_dto.dart         ← parses API JSON, toEntity(), toJson()/fromJson() for cache
│   └── repositories/
│       ├── rates_repository_impl.dart                ← implements domain RatesRepository
│       ├── currency_preferences_repository_impl.dart ← implements CurrencyPreferencesRepository
│       └── settings_repository_impl.dart             ← implements SettingsRepository (theme mode)
│
├── domain/
│   ├── entities/
│   │   ├── exchange_rates.dart    ← { base, Map<String,double> rates, DateTime fetchedAt } + isStale(ttl)
│   │   └── currency_preferences.dart ← ordered selected codes + add/remove/reorder/sanitize
│   ├── repositories/
│   │   ├── rates_repository.dart                ← abstract: getRates({bool forceRefresh})
│   │   ├── currency_preferences_repository.dart ← abstract: load() / save(prefs)
│   │   └── settings_repository.dart             ← abstract: read/writeThemeMode (string, Flutter-free)
│   └── services/
│       └── conversion_service.dart ← pure: convert(amount, rates) → Map<String,double>
│
└── presentation/
    ├── controllers/
    │   ├── converter_controller.dart  ← ChangeNotifier: amount, selection, ConverterState
    │   └── theme_controller.dart      ← ChangeNotifier: ThemeMode + persistence
    ├── pages/
    │   ├── converter_page.dart        ← Scaffold, wires controllers to widgets
    │   └── currency_picker_page.dart  ← add/remove/search currencies (F10/F11)
    └── widgets/
        ├── amount_input.dart          ← + clear (×) button (F14)
        ├── conversion_row.dart
        ├── shimmer_box.dart           ← first-load skeleton (F5)
        └── status_banner.dart         ← offline / stale / last-updated
```

> If time is short, `domain/services/conversion_service.dart` MAY be a top-level
> function and `widgets/` MAY be collapsed into `converter_page.dart`. The
> `data` / `domain` / `presentation` split itself is **not** optional (R2.1).

## Dependency rules (enforced)

- `domain/` imports nothing from `data/` or `presentation/` and nothing from
  Flutter. It defines interfaces; `data/` implements them.
- `data/` imports `domain/` (to implement the repo and return entities) and
  `core/`. It may import `http`, `shared_preferences`, `dart:convert`.
- `presentation/` imports `domain/` and `core/`. It does **not** import `data/`
  except in `main.dart` for construction.
- `core/` imports nothing from the three layers.

## The object graph (`main.dart`)

```
SharedPreferences.getInstance()
      │
RatesLocalDataSourceImpl(prefs)
RatesRemoteDataSourceImpl(httpClient)
      │
RatesRepositoryImpl(remote, local)         // implements RatesRepository
      │
ConverterController(repository, ConversionService())
      │
runApp( ConverterApp(controller) )   // MaterialApp root; defined in main.dart, home: ConverterPage
```

## Why this structure

- A new engineer can open `domain/` and learn *what the app does* without wading
  through HTTP or widgets.
- Swapping `exchangerate-api` for `fixer.io` = one new `RatesRemoteDataSource`
  implementation; nothing else moves (R2.6).
- Adding currencies = edit `core/constants.dart` `kTargetCurrencies` (R2.5).
- The repository and conversion service are plain Dart → fast unit tests with no
  Flutter test harness.
