# Design System

Presentation-layer only. None of this touches `domain` / `data` or the rules in
[`rules.md`](rules.md); it is *how* the `ready` / `loading` / `error` states from
[`features.md`](features.md) are painted.

## Goals

- Friendly and trustworthy (it shows money) — calm blues, a green "success"
  accent, generous spacing, large readable numbers.
- One set of tokens, no magic numbers in widgets.
- Light **and** dark, switched by the OS (`ThemeMode.system`).
- No font/asset/package additions — a tuned type scale on the platform font.

## Files (`lib/core/theme/`)

| File | Contents |
|---|---|
| `app_spacing.dart` | `AppSpacing` 4-pt scale (`xs`=4 … `xxxl`=48) and `AppRadius` (`sm`=10 … `pill`), as `Radius` / `BorderRadius` constants |
| `app_colors.dart` | `AppColors` `ThemeExtension` — the success / warning / info triads, the header gradient stops, and skeleton shimmer colours, for both brightnesses. Accessor: `context.appColors` |
| `app_theme.dart` | `AppTheme.light` / `AppTheme.dark` — a hand-built `ColorScheme` each, component themes (card, input, buttons, divider, snackbar, appbar), and one `TextTheme` |

`main.dart` wires `theme: AppTheme.light`, `darkTheme: AppTheme.dark`,
`themeMode: ThemeMode.system`.

## Colour roles

| Role | Light | Dark | Used for |
|---|---|---|---|
| `primary` | `#4F6CF7` indigo | `#9DB0FF` | actions, focus ring, USD pill |
| `secondary` | `#0FB981` emerald | `#5FE0B5` | positive / "money" accents |
| `tertiary` | `#7C5CFC` violet | `#C3B0FF` | gradient end, decorative |
| `AppColors.success` | `#12A150` | `#4ED88A` | "rates updated" pill |
| `AppColors.warning` | `#F5A524` | `#FFC24B` | offline / stale banner |
| `AppColors.info` | `#3B82F6` | `#7FB0FF` | reserved for neutral notices |
| `error` | `#E5484D` | `#FF6B6E` | full-screen error state |
| surface ramp | `#FFFFFF` → `#E3E8F2` | `#0E1117` → `#272D39` | page bg, cards, chips |

Every colour is defined for both themes; widgets never hard-code a hex value.

## Type scale (`TextTheme`)

`displaySmall` 36/700 (the amount) · `headlineMedium` 26/700 · `titleLarge`
20/700 · `titleMedium` 16/600 · `bodyLarge/Medium/Small` 16/14/12.5 ·
`labelMedium` 12/600 tracked (section captions). Big numbers use tight negative
tracking and `FontFeature.tabularFigures()` so digits don't jump.

## Components

- **Gradient header** — `primary → tertiary` diagonal wash, ~210 px, behind the
  content layer (a `Stack`); carries the title, subtitle, and refresh button in
  `onGradient` colour.
- **Amount card** (`AmountInput`) — elevated rounded-28 card straddling the
  gradient/surface seam; caption + USD flag pill, oversized borderless field
  with a `$` prefix and `0.00` hint.
- **Result card** (`ConversionRow`) — rounded-20 outlined card: flag tile,
  code + full name, amount (tabular) + `1 USD = …` line. Tap copies the amount
  (snackbar); no logic in the widget.
- **Status banner** (`StatusBanner`) — fresh: a small `success`-tinted pill
  ("Rates updated 4 min ago", spinner while refreshing). Offline/stale: a
  `warning`-tinted rounded card with Retry + dismiss (F6.AC1/AC3).
- **Skeleton** (`ShimmerBox` + `_SkeletonBody`) — five pulsing placeholder rows
  during the first load instead of a bare spinner (F5.AC1).
- **Error state** (`_ErrorBody`) — circular `errorContainer` icon badge,
  headline + detail that differ by exception type (rules.md R5.5), a filled
  "Try again" button.

## Constraints kept

- No new packages, fonts, or image assets.
- Pure Flutter Material 3; all styling flows from `Theme.of(context)`.
- `flutter analyze` clean; the data/domain tests are unaffected.
