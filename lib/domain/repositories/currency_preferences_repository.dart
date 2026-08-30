import '../entities/currency_preferences.dart';

/// Persists the user's currency selection + order. The implementation lives in
/// the data layer; the controller depends only on this contract.
abstract interface class CurrencyPreferencesRepository {
  /// Returns the stored selection, or [CurrencyPreferences.defaults] if nothing
  /// valid is stored. Never throws.
  Future<CurrencyPreferences> load();

  /// Overwrites the stored selection.
  Future<void> save(CurrencyPreferences preferences);
}
