import 'package:flutter/foundation.dart';

import '../../core/constants.dart';
import '../../core/errors.dart';
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

  /// `code -> rate`. Non-null once any snapshot (fresh or stale) has loaded.
  final Map<String, double>? rates;

  /// `code -> converted amount`, recomputed locally on every keystroke.
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

/// Holds converter state and mediates between the UI and the repository.
///
/// Built-in [ChangeNotifier] only — no state-management package (rules.md R3).
/// All logic (parsing, when to fetch, how to map errors to view state) lives
/// here, not in widgets.
class ConverterController extends ChangeNotifier {
  ConverterController(
    this._repository, {
    ConversionService conversionService = const ConversionService(),
  }) : _conversion = conversionService;

  final RatesRepository _repository;
  final ConversionService _conversion;

  ConverterState _state = const ConverterState.loading();
  ConverterState get state => _state;

  double _amount = 0;

  /// First load on startup: cache-first, shows a spinner only if nothing is
  /// cached yet.
  Future<void> load() => _loadRates(forceRefresh: false);

  /// User asked for fresh data (app-bar button / pull-to-refresh, F7). Always
  /// hits the network; keeps current data visible while it runs.
  Future<void> refresh() => _loadRates(forceRefresh: true);

  /// Retry from the full-screen error state (F6.AC5).
  Future<void> retry() => _loadRates(forceRefresh: true);

  /// Called on every keystroke in the amount field. Pure local math over the
  /// rates we already hold — no cache read, no network (rules.md R4.1).
  void updateAmount(String raw) {
    _amount = _parseAmount(raw);
    final Map<String, double>? rates = _state.rates;
    _emit(_state.copyWith(
      amount: _amount,
      conversions:
          rates == null ? const <String, double>{} : _conversion.convert(_amount, rates),
    ));
  }

  Future<void> _loadRates({required bool forceRefresh}) async {
    final bool hasDataOnScreen = _state.status == ConverterStatus.ready;
    _emit(hasDataOnScreen
        ? _state.copyWith(isRefreshing: true)
        : const ConverterState.loading());

    try {
      final result = await _repository.getRates(forceRefresh: forceRefresh);
      _emit(ConverterState(
        status: ConverterStatus.ready,
        amount: _amount,
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
        _emit(ConverterState(status: ConverterStatus.error, error: error, amount: _amount));
      }
    }
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
