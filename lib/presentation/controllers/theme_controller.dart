import 'package:flutter/material.dart';

import '../../data/datasources/settings_store.dart';

/// Holds the chosen [ThemeMode] and persists changes. Built-in [ChangeNotifier]
/// only — `MaterialApp` rebuilds through a `ListenableBuilder` on this.
class ThemeController extends ChangeNotifier {
  ThemeController(this._store, this._mode);

  final SettingsStore _store;
  ThemeMode _mode;

  ThemeMode get mode => _mode;

  /// Reads the persisted choice once at startup.
  static ThemeController fromStore(SettingsStore store) =>
      ThemeController(store, _parse(store.readThemeMode()));

  Future<void> setMode(ThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
    await _store.writeThemeMode(mode.name);
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
