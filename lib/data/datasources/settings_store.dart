import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants.dart';

/// Tiny persistence for app settings that aren't domain data. Currently just the
/// theme mode. Kept as plain strings so the data layer stays free of Flutter
/// imports — the presentation layer maps them to `ThemeMode`.
class SettingsStore {
  SettingsStore(this._prefs);

  final SharedPreferences _prefs;

  /// One of `'system'`, `'light'`, `'dark'`, or `null` if never set.
  String? readThemeMode() => _prefs.getString(kThemePrefsKey);

  Future<void> writeThemeMode(String value) =>
      _prefs.setString(kThemePrefsKey, value);
}
