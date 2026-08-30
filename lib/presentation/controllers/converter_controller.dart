import 'package:flutter/foundation.dart';

import '../../core/constants.dart';
import '../../core/errors.dart';
import '../../domain/entities/currency_preferences.dart';
import '../../domain/repositories/currency_preferences_repository.dart';
import '../../domain/repositories/rates_repository.dart';
import '../../domain/services/conversion_service.dart';

/// The three mutually exclusive things the screen can be doing.
enum ConverterStatus { loading, ready, error }

/// Immutable view model the UI renders. One object = one complete description of
/// what to paint, so the widget tree stays a pure function of [ConverterState].
@immutable
class ConverterState {
  const ConverterState({
    required this.status,
    this.amount = 0,
    this.selected = kDefaultSelection,
    this.rates,
    this.conversions = const <String, double>{},
    this.fetchedAt,
    this.isStale = false,
    this.isOffline = false,
    this.isRefreshing = false,
    this.error,
  });

  const ConverterState.loading() : this(status: ConverterStatus.loading);

  /// Current status. Drives which view is shown.
  final ConverterStatus status;

  /// Last parsed USD amount from the input field.
  final double amount;

  /// The user's picked target currencies, in display order.
  final List<String> selected;

  /// `code -> rate` for the whole supported catalogue. Non-null once any
  /// snapshot (fresh or stale) has loaded.
  final Map<String, double>? rates;

  /// `code -> converted amount` for the whole catalogue, recomputed locally on
  /// every keystroke. The screen reads only the [selected] keys from this.
  final Map<String, double> conversions;

  /// When the displayed rates were fetched (for the "updated X ago" hint).
  final DateTime? fetchedAt;

  /// Rates are older than [kCacheTtl] (a refresh was attempted but failed).
  final bool isStale;

  /// The last refresh failed specifically on connectivity.
  final bool isOffline;

  /// A background refresh is in flight while data is already on screen.
  final bool isRefreshing;

  /// Populated only when [status] is [ConverterStatus.error].
  final AppException? error;

  ConverterState copyWith({
    ConverterStatus? status,
    double? amount,
    List<String>? selected,
    Map<String, double>? rates,
    Map<String, double>? conversions,
    DateTime? fetchedAt,
    bool? isStale,
    bool? isOffline,
    bool? isRefreshing,
    AppException? error,
  }) {
    return ConverterState(
      status: status ?? this.status,
      amount: amount ?? this.amount,
      selected: selected ?? this.selected,
      rates: rates ?? this.rates,
      conversions: conversions ?? this.conversions,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      isStale: isStale ?? this.isStale,
      isOffline: isOffline ?? this.isOffline,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: error ?? this.error,
    );
  }
}

/// Holds converter state and mediates between the UI and the repositories.
///
/// Built-in [ChangeNotifier] only — no state-management package (rules.md R3).
/// All logic (parsing, when to fetch, currency selection, error mapping) lives
/// here, not in widgets.
class ConverterController extends ChangeNotifier {
  ConverterController(
    this._rates,
    this._preferencesRepo, {
    ConversionService conversionService = const ConversionService(),
  }) : _conversion = conversionService;

  final RatesRepository _rates;
  final CurrencyPreferencesRepository _preferencesRepo;
  final ConversionService _conversion;

  ConverterState _state = const ConverterState.loading();
  ConverterState get state => _state;

  double _amount = 0;
  CurrencyPreferences _preferences = CurrencyPreferences.defaults;

  /// First load on startup: read the saved currency selection, then the rates
  /// (cache-first).
  Future<void> load() async {
    _preferences = await _preferencesRepo.load();
    _emit(_state.copyWith(selected: _preferences.selected));
    await _loadRates(forceRefresh: false);
  }

  /// User asked for fresh data (app-bar button / pull-to-refresh). Always hits
  /// the network; keeps current data visible while it runs.
  Future<void> refresh() => _loadRates(forceRefresh: true);

  /// Retry from the full-screen error state (F6.AC5).
  Future<void> retry() => _loadRates(forceRefresh: true);

  /// Called on every keystroke in the amount field. Pure local math over the
  /// rates we already hold — no cache read, no network (rules.md R4.1).
  void updateAmount(String raw) {
    _amount = _parseAmount(raw);
    _emit(_state.copyWith(amount: _amount, conversions: _recompute()));
  }

  // --- currency selection -------------------------------------------------

  Future<void> addCurrency(String code) =>
      _updatePreferences(_preferences.withAdded(code));

  Future<void> removeCurrency(String code) =>
      _updatePreferences(_preferences.withRemoved(code));

  Future<void> reorderCurrencies(int oldIndex, int newIndex) =>
      _updatePreferences(_preferences.reordered(oldIndex, newIndex));

  Future<void> resetCurrencies() =>
      _updatePreferences(CurrencyPreferences.defaults);

  Future<void> _updatePreferences(CurrencyPreferences next) async {
    if (identical(next, _preferences)) return; // no-op guard from the entity
    _preferences = next;
    _emit(_state.copyWith(selected: next.selected));
    await _preferencesRepo.save(next);
  }

  // --- rates ------------------------------------------------------------

  Future<void> _loadRates({required bool forceRefresh}) async {
    final bool hasDataOnScreen = _state.status == ConverterStatus.ready;
    _emit(hasDataOnScreen
        ? _state.copyWith(isRefreshing: true)
        : _state.copyWith(status: ConverterStatus.loading));

    try {
      final result = await _rates.getRates(forceRefresh: forceRefresh);
      _emit(ConverterState(
        status: ConverterStatus.ready,
        amount: _amount,
        selected: _preferences.selected,
        rates: result.rates,
        conversions: _conversion.convert(_amount, result.rates),
        fetchedAt: result.fetchedAt,
        isStale: result.isStale(kCacheTtl),
        isOffline: result.lastError is NetworkException,
      ));
    } on AppException catch (error) {
      if (hasDataOnScreen) {
        // Never blank out good data because a refresh failed (rules.md R5.3).
        _emit(_state.copyWith(
          isRefreshing: false,
          isStale: true,
          isOffline: error is NetworkException,
        ));
      } else {
        _emit(ConverterState(
          status: ConverterStatus.error,
          error: error,
          amount: _amount,
          selected: _preferences.selected,
        ));
      }
    }
  }

  Map<String, double> _recompute() {
    final Map<String, double>? rates = _state.rates;
    return rates == null
        ? const <String, double>{}
        : _conversion.convert(_amount, rates);
  }

  /// Tolerant parse: blank or partial input ("", ".", "1.2.3") becomes 0 instead
  /// of throwing (features.md F1.AC2/AC3).
  double _parseAmount(String raw) {
    final String cleaned = raw.trim().replaceAll(',', '');
    if (cleaned.isEmpty) return 0;
    return double.tryParse(cleaned) ?? 0;
  }

  void _emit(ConverterState next) {
    _state = next;
    notifyListeners();
  }
}
