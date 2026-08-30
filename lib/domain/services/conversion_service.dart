/// Pure conversion math, isolated from UI and I/O so it is trivial to unit-test
/// (rules.md R2.2, testing.md). No Flutter, no async, no dependencies.
class ConversionService {
  const ConversionService();

  /// Converts [amount] (in the base currency) into every currency present in
  /// [rates], returning `code -> converted amount`.
  ///
  /// - A non-positive [amount] yields `0` for each known code (so the UI can
  ///   still render rows instead of going blank).
  /// - Empty [rates] yields an empty map. Never throws.
  Map<String, double> convert(double amount, Map<String, double> rates) {
    if (rates.isEmpty) return const <String, double>{};
    if (amount <= 0) {
      return <String, double>{for (final String code in rates.keys) code: 0};
    }
    return <String, double>{
      for (final MapEntry<String, double> entry in rates.entries)
        entry.key: amount * entry.value,
    };
  }
}
