import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants.dart';
import '../../domain/repositories/settings_repository.dart';

/// [SharedPreferences]-backed [SettingsRepository]. One string under
/// [kThemePrefsKey] — its own slot, independent of the rate cache and the
/// currency selection.
class SharedPrefsSettingsRepository implements SettingsRepository {
  SharedPrefsSettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  @override
  String? readThemeMode() => _prefs.getString(kThemePrefsKey);

  @override
  Future<void> writeThemeMode(String value) =>
      _prefs.setString(kThemePrefsKey, value);
}
