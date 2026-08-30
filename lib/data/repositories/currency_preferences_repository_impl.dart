import 'dart:convert';
import 'dart:developer' as developer;

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants.dart';
import '../../domain/entities/currency_preferences.dart';
import '../../domain/repositories/currency_preferences_repository.dart';

/// [SharedPreferences]-backed store for the currency selection. One JSON string
/// array under [kCurrencyPrefsKey] — a *different key* from the rate cache, so
/// the two never interfere.
class CurrencyPreferencesRepositoryImpl implements CurrencyPreferencesRepository {
  CurrencyPreferencesRepositoryImpl(this._prefs);

  final SharedPreferences _prefs;

  @override
  Future<CurrencyPreferences> load() async {
    final String? raw = _prefs.getString(kCurrencyPrefsKey);
    if (raw == null) return CurrencyPreferences.defaults;
    try {
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      // Sanitize on the way in: a stored code may have been removed from the
      // catalogue in a later build.
      return CurrencyPreferences.sanitized(list.cast<String>());
    } catch (error, stackTrace) {
      developer.log(
        'Discarding unreadable currency selection',
        name: 'prefs',
        error: error,
        stackTrace: stackTrace,
      );
      await _prefs.remove(kCurrencyPrefsKey);
      return CurrencyPreferences.defaults;
    }
  }

  @override
  Future<void> save(CurrencyPreferences preferences) =>
      _prefs.setString(kCurrencyPrefsKey, jsonEncode(preferences.selected));
}
