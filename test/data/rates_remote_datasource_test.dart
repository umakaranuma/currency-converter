import 'dart:io';

import 'package:currency_converter/core/errors.dart';
import 'package:currency_converter/data/datasources/rates_remote_datasource.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class _MockClient extends Mock implements http.Client {}

/// A representative success payload. `XXX` is here to prove we drop currencies
/// we do not display.
const String _okBody = '{"result":"success","base_code":"USD",'
    '"time_last_update_unix":1700000000,'
    '"rates":{"EUR":0.92,"GBP":0.79,"JPY":149.3,"AUD":1.52,"CAD":1.36,"XXX":1.0}}';

void main() {
  late _MockClient client;
  late HttpRatesRemoteDataSource dataSource;

  setUpAll(() => registerFallbackValue(Uri()));

  setUp(() {
    client = _MockClient();
    dataSource = HttpRatesRemoteDataSource(client);
  });

  test('200 + valid body -> keeps only the five target currencies', () async {
    when(() => client.get(any()))
        .thenAnswer((_) async => http.Response(_okBody, 200));

    final dto = await dataSource.fetch();

    expect(
      dto.rates.keys,
      containsAll(<String>['EUR', 'GBP', 'JPY', 'AUD', 'CAD']),
    );
    expect(dto.rates.containsKey('XXX'), isFalse);
    expect(dto.rates['EUR'], 0.92);
  });

  test('HTTP 500 -> ApiException that carries the status code', () async {
    when(() => client.get(any()))
        .thenAnswer((_) async => http.Response('server error', 500));

    await expectLater(
      dataSource.fetch(),
      throwsA(isA<ApiException>()
          .having((ApiException e) => e.statusCode, 'statusCode', 500)),
    );
  });

  test('200 but result != "success" -> ApiException', () async {
    when(() => client.get(any()))
        .thenAnswer((_) async => http.Response('{"result":"error"}', 200));

    await expectLater(dataSource.fetch(), throwsA(isA<ApiException>()));
  });

  test('malformed body -> ApiException', () async {
    when(() => client.get(any()))
        .thenAnswer((_) async => http.Response('<html>not json</html>', 200));

    await expectLater(dataSource.fetch(), throwsA(isA<ApiException>()));
  });

  test('socket failure -> NetworkException', () async {
    when(() => client.get(any()))
        .thenThrow(const SocketException('network is unreachable'));

    await expectLater(dataSource.fetch(), throwsA(isA<NetworkException>()));
  });
}
