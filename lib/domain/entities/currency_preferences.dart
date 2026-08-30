import '../../core/constants.dart';

/// The user's choice of which target currencies to show and in what order.
/// Persisted independently of the rate cache (see `agent/decisions.md` D8).
class CurrencyPreferences {
  const CurrencyPreferences(this.selected);

  /// Ordered list of target currency codes. Never contains [kBaseCurrency],
  /// never contains duplicates, and every entry is in [kSupportedCurrencies].
  final List<String> selected;

  /// What a fresh install (or a "Reset") uses.
  static const CurrencyPreferences defaults =
      CurrencyPreferences(kDefaultSelection);

  bool contains(String code) => selected.contains(code);

  /// Returns a copy with [code] appended if it is supported and not already in.
  CurrencyPreferences withAdded(String code) {
    if (selected.contains(code) || !kSupportedCurrencies.contains(code)) {
      return this;
    }
    return CurrencyPreferences(<String>[...selected, code]);
  }

  /// Returns a copy without [code]. Removing the last one is refused — the list
  /// is never allowed to become empty.
  CurrencyPreferences withRemoved(String code) {
    if (!selected.contains(code) || selected.length == 1) return this;
    return CurrencyPreferences(
      selected.where((String c) => c != code).toList(),
    );
  }

  /// Returns a copy with the item at [oldIndex] moved so it lands at [newIndex]
  /// *after* removal — matching `ReorderableListView.onReorderItem` semantics,
  /// so the caller passes the framework's indices straight through.
  CurrencyPreferences reordered(int oldIndex, int newIndex) {
    final List<String> next = <String>[...selected];
    next.insert(newIndex, next.removeAt(oldIndex));
    return CurrencyPreferences(next);
  }

  /// Drops anything unknown / duplicated / equal to the base, falling back to
  /// [defaults] if nothing usable remains. Used when loading persisted data.
  static CurrencyPreferences sanitized(Iterable<String> codes) {
    final List<String> clean = <String>[];
    for (final String code in codes) {
      if (code != kBaseCurrency &&
          kSupportedCurrencies.contains(code) &&
          !clean.contains(code)) {
        clean.add(code);
      }
    }
    return clean.isEmpty ? defaults : CurrencyPreferences(clean);
  }
}
