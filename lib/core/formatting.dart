/// Display formatting helpers. Kept in `core/` (pure Dart, no Flutter) so the
/// "how many decimals / how to phrase a timestamp" rules live in exactly one
/// place — features.md F2.AC4 / F8.
library;

import 'constants.dart';

/// Formats a money [amount] with the correct number of fraction digits for
/// [code] — 0 for the currencies in [kZeroDecimalCurrencies], 2 for the rest.
String formatMoney(double amount, String code) =>
    amount.toStringAsFixed(kZeroDecimalCurrencies.contains(code) ? 0 : 2);

/// Formats a per-unit FX rate. Sub-100 rates get 4 digits so EUR/GBP keep useful
/// precision (`0.9231`), large rates like JPY get 2 (`149.30`).
String formatRate(double rate) =>
    rate >= 100 ? rate.toStringAsFixed(2) : rate.toStringAsFixed(4);

/// Coarse "time since" label for the last-updated hint and the offline banner.
/// [now] is injectable for deterministic tests.
String formatRelativeTime(DateTime time, {DateTime? now}) {
  final Duration delta = (now ?? DateTime.now()).difference(time);
  if (delta.isNegative || delta.inSeconds < 45) return 'just now';
  if (delta.inMinutes < 60) return '${delta.inMinutes} min ago';
  if (delta.inHours < 24) return '${delta.inHours} h ago';
  return '${delta.inDays} d ago';
}
