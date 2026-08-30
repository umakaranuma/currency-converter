import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../core/constants.dart';
import '../../core/errors.dart';
import '../models/rates_dto.dart';

/// The single place the app talks to a rates API over the network
/// (rules.md R2.3). Swapping providers = a new implementation of this interface,
/// nothing else (rules.md R2.6).
abstract interface class RatesRemoteDataSource {
  /// Fetches the current snapshot. Throws [NetworkException] for connectivity
  /// problems and [ApiException] for anything wrong with the response.
  Future<RatesDto> fetch();
}

/// `package:http` implementation talking to exchangerate-api.com's key-less
/// endpoint. The [http.Client] is injected so tests can supply a fake.
class HttpRatesRemoteDataSource implements RatesRemoteDataSource {
  HttpRatesRemoteDataSource(this._client);

  final http.Client _client;

  @override
  Future<RatesDto> fetch() async {
    final Uri uri = Uri.parse('$kRatesBaseUrl/$kBaseCurrency');

    final http.Response response;
    try {
      response = await _client.get(uri).timeout(kRequestTimeout);
    } on SocketException {
      throw const NetworkException();
    } on TimeoutException {
      throw const NetworkException('Request timed out');
    } on http.ClientException {
      throw const NetworkException('Could not reach the rates service');
    }

    if (response.statusCode != 200) {
      throw ApiException(
        'Rates service returned HTTP ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw const ApiException('Rates service returned malformed data');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const ApiException('Rates service returned an unexpected payload');
    }

    return RatesDto.fromApiJson(decoded);
  }
}
