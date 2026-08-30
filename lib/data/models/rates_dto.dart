import 'dart:convert';

import '../../core/constants.dart';
import '../../core/errors.dart';
import '../../domain/entities/exchange_rates.dart';

/// Data-layer representation of a rate snapshot. It knows how to parse the API
/// payload and how to (de)serialize itself for the cache. The rest of the app
/// only ever sees the domain [ExchangeRates] via [toEntity].
class RatesDto {
  const RatesDto({
    required this.base,
    required this.rates,
    required this.fetchedAt,
  });

  final String base;
  final Map<String, double> rates;
  final DateTime fetchedAt;

  /// Parses the exchangerate-api.com (`open.er-api.com`) response body.
  ///
  /// Throws [ApiException] if the service signalled an error, the shape is
  /// unexpected, or any of [kTargetCurrencies] is missing. Only the currencies
  /// we actually display are kept; the rest of the payload is dropped.
  factory RatesDto.fromApiJson(Map<String, dynamic> json) {
    if (json['result'] != 'success') {
      throw const ApiException('Rates service reported an error');
    }
    final Object? rawRates = json['rates'];
    if (rawRates is! Map) {
      throw const ApiException('Unexpected response from rates service');
    }

    final Map<String, double> parsed = <String, double>{};
    for (final String code in kTargetCurrencies) {
      final Object? value = rawRates[code];
      if (value is! num) {
        throw ApiException('Missing rate for $code in response');
      }
      parsed[code] = value.toDouble();
    }

    return RatesDto(
      base: (json['base_code'] as String?) ?? kBaseCurrency,
      rates: parsed,
      // Stamp with *our* fetch time: the cache TTL is about how long ago we
      // asked, not when the provider last published (caching.md / F8).
      fetchedAt: DateTime.now(),
    );
  }

  /// Rebuilds a snapshot from its cached JSON string. Throws if the blob is
  /// malformed or out-of-schema — the caller ([RatesLocalDataSource]) turns that
  /// into a cache miss.
  factory RatesDto.fromCacheJson(String source) {
    final Map<String, dynamic> json =
        jsonDecode(source) as Map<String, dynamic>;
    final Map<String, dynamic> rawRates =
        (json['rates'] as Map).cast<String, dynamic>();

    return RatesDto(
      base: json['base'] as String,
      rates: <String, double>{
        for (final MapEntry<String, dynamic> e in rawRates.entries)
          e.key: (e.value as num).toDouble(),
      },
      fetchedAt: DateTime.fromMillisecondsSinceEpoch(json['fetchedAt'] as int),
    );
  }

  factory RatesDto.fromEntity(ExchangeRates entity) => RatesDto(
        base: entity.base,
        rates: entity.rates,
        fetchedAt: entity.fetchedAt,
      );

  /// Serializes to the exact shape [RatesDto.fromCacheJson] expects.
  String toCacheJson() => jsonEncode(<String, dynamic>{
        'base': base,
        'rates': rates,
        'fetchedAt': fetchedAt.millisecondsSinceEpoch,
      });

  ExchangeRates toEntity() => ExchangeRates(
        base: base,
        rates: rates,
        fetchedAt: fetchedAt,
      );
}
