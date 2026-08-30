import 'dart:developer' as developer;

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants.dart';
import '../../core/errors.dart';
import '../models/rates_dto.dart';

/// Persistent, single-slot cache for the last good rate snapshot.
abstract interface class RatesLocalDataSource {
  /// Returns the cached snapshot, or `null` if nothing is stored.
  ///
  /// Throws [CacheMissException] if a value *is* stored but cannot be parsed
  /// (out-of-schema / corrupt); the bad entry is cleared first so the next
  /// launch starts clean.
  Future<RatesDto?> read();

  /// Overwrites the cache with [snapshot] (write-through after a fetch).
  Future<void> write(RatesDto snapshot);
}

/// [SharedPreferences]-backed implementation. A single JSON string under
/// [kCachePrefsKey] — enough for one snapshot, and it survives app restarts so
/// the app can open straight into cached data when offline (F9).
class SharedPrefsRatesLocalDataSource implements RatesLocalDataSource {
  SharedPrefsRatesLocalDataSource(this._prefs);

  final SharedPreferences _prefs;

  @override
  Future<RatesDto?> read() async {
    final String? raw = _prefs.getString(kCachePrefsKey);
    if (raw == null) return null;

    try {
      return RatesDto.fromCacheJson(raw);
    } catch (error, stackTrace) {
      // Corrupt blob: log once, drop it, and report a miss.
      developer.log(
        'Discarding unreadable rates cache',
        name: 'cache',
        error: error,
        stackTrace: stackTrace,
      );
      await _prefs.remove(kCachePrefsKey);
      throw const CacheMissException('Saved rates were unreadable');
    }
  }

  @override
  Future<void> write(RatesDto snapshot) =>
      _prefs.setString(kCachePrefsKey, snapshot.toCacheJson());
}
