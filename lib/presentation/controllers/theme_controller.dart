import 'package:flutter/material.dart';

import '../../domain/repositories/settings_repository.dart';

/// Holds the chosen [ThemeMode] and persists changes. Built-in [ChangeNotifier]
/// only — `MaterialApp` rebuilds through a `ListenableBuilder` on this. Depends
/// on the [SettingsRepository] interface, like the other controllers depend on
/// their repositories.
class ThemeController extends ChangeNotifier {
  ThemeController(this._settings, this._mode);

  final SettingsRepository _settings;
  ThemeMode _mode;

  ThemeMode get mode => _mode;

  /// Reads the persisted choice once at startup.
  static ThemeController fromRepository(SettingsRepository settings) =>
      ThemeController(settings, _parse(settings.readThemeMode()));

  Future<void> setMode(ThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
    await _settings.writeThemeMode(mode.name);
  }

  /// Cycles system -> light -> dark -> system, for a single-tap toggle button.
  Future<void> cycle() => setMode(switch (_mode) {
        ThemeMode.system => ThemeMode.light,
        ThemeMode.light => ThemeMode.dark,
        ThemeMode.dark => ThemeMode.system,
      });

  static ThemeMode _parse(String? value) => switch (value) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
}
