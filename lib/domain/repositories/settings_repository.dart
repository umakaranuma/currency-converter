/// Persists small app-level settings that are not domain data (currently just
/// the theme mode). Kept string-typed so this interface stays free of Flutter
/// imports; the presentation layer maps the string to `ThemeMode`.
abstract interface class SettingsRepository {
  /// One of `'system'`, `'light'`, `'dark'`, or `null` if never set.
  String? readThemeMode();

  Future<void> writeThemeMode(String value);
}
