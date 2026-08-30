import 'package:currency_converter/core/errors.dart';
import 'package:currency_converter/data/datasources/rates_local_datasource.dart';
import 'package:currency_converter/data/datasources/rates_remote_datasource.dart';
import 'package:currency_converter/data/models/rates_dto.dart';
import 'package:currency_converter/domain/entities/exchange_rates.dart';
import 'package:currency_converter/data/repositories/rates_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemote extends Mock implements RatesRemoteDataSource {}

class _MockLocal extends Mock implements RatesLocalDataSource {}

/// Builds a snapshot whose age is [age] before "now", so tests can make it fall
/// on either side of the 1-hour TTL.
RatesDto _dto({required Duration age, Map<String, double>? rates}) => RatesDto(
      base: 'USD',
      rates: rates ??
          const <String, double>{
            'EUR': 0.90,
            'GBP': 0.80,
            'JPY': 150.0,
            'AUD': 1.50,
            'CAD': 1.35,
          },
      fetchedAt: DateTime.now().subtract(age),
    );

void main() {
  late _MockRemote remote;
  late _MockLocal local;
  late RatesRepositoryImpl repo;

  setUpAll(() => registerFallbackValue(_dto(age: Duration.zero)));

  setUp(() {
    remote = _MockRemote();
    local = _MockLocal();
    repo = RatesRepositoryImpl(remote, local, const Duration(hours: 1));
    when(() => local.write(any())).thenAnswer((_) async {});
  });

  // The assignment's headline test: prove the cache short-circuits the network.
  test('T1 - a fresh cache is served without calling the API', () async {
    final RatesDto fresh = _dto(age: const Duration(minutes: 5));
    when(() => local.read()).thenAnswer((_) async => fresh);

    final ExchangeRates result = await repo.getRates();

    expect(result.rates, fresh.rates);
    verify(() => local.read()).called(1);
    verifyNever(() => remote.fetch()); // remove the freshness check and this fails
  });

  test('T2 - a stale cache triggers a fetch and is written back', () async {
    final RatesDto stale = _dto(age: const Duration(hours: 2));
    final RatesDto fetched = _dto(
      age: Duration.zero,
      rates: const <String, double>{
        'EUR': 0.95,
        'GBP': 0.82,
        'JPY': 152.0,
        'AUD': 1.51,
        'CAD': 1.36,
      },
    );
    when(() => local.read()).thenAnswer((_) async => stale);
    when(() => remote.fetch()).thenAnswer((_) async => fetched);

    final ExchangeRates result = await repo.getRates();

    expect(result.rates, fetched.rates);
    verify(() => remote.fetch()).called(1);
    verify(() => local.write(fetched)).called(1);
  });

  test('T3 - offline with a stale cache serves stale data and does not throw',
      () async {
    final RatesDto stale = _dto(age: const Duration(hours: 3));
    when(() => local.read()).thenAnswer((_) async => stale);
    when(() => remote.fetch()).thenThrow(const NetworkException());

    final ExchangeRates result = await repo.getRates();

    expect(result.rates, stale.rates);
    expect(result.lastError, isA<NetworkException>()); // tagged as a fallback
  });

  test('T4 - offline with no cache rethrows NetworkException', () async {
    when(() => local.read()).thenAnswer((_) async => null);
    when(() => remote.fetch()).thenThrow(const NetworkException());

    await expectLater(repo.getRates(), throwsA(isA<NetworkException>()));
  });

  test('forceRefresh bypasses an otherwise-fresh cache', () async {
    when(() => local.read())
        .thenAnswer((_) async => _dto(age: const Duration(minutes: 1)));
    when(() => remote.fetch())
        .thenAnswer((_) async => _dto(age: Duration.zero));

    await repo.getRates(forceRefresh: true);

    verify(() => remote.fetch()).called(1);
  });

  test('an API error with a usable cache falls back instead of throwing',
      () async {
    final RatesDto stale = _dto(age: const Duration(hours: 5));
    when(() => local.read()).thenAnswer((_) async => stale);
    when(() => remote.fetch())
        .thenThrow(const ApiException('boom', statusCode: 500));

    final ExchangeRates result = await repo.getRates();

    expect(result.rates, stale.rates);
    expect(result.lastError, isA<ApiException>());
  });
}
