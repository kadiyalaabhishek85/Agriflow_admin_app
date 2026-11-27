import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:agriflow_admin/core/network/api_client.dart';

import '../../domain/entities/market_rate_item.dart';
import '../../domain/exceptions/market_rates_exception.dart';
import 'market_rates_remote_data_source.dart';

/// FastAPI implementation of MarketRatesRemoteDataSource.
///
/// Verified endpoints (live OpenAPI, re-verified 2026-09-28):
/// - `GET  /api/v1/market-rates`        (authenticated)
/// - `GET  /api/v1/public/market-rates` (anonymous, identical payload)
/// - `POST /api/v1/market-rates`        (authenticated, MarketRateCreate)
///
/// Read fallback is deliberate and documented: `getRates` first performs the
/// authenticated request and, if it fails for any reason, retries against the
/// public endpoint, which returns the identical `MarketRatePublic` payload.
/// Viewing the rate board must not break when a session token is missing or
/// expired. Mutations (`setRate`) NEVER fall back — they require auth.
class FastApiMarketRatesRemoteDataSource implements MarketRatesRemoteDataSource {
  static const String defaultBaseUrl = ApiClient.defaultBaseUrl;
  static const String apiPrefix = '/api/v1';

  final String baseUrl;
  final http.Client client;

  FastApiMarketRatesRemoteDataSource({
    String? baseUrl,
    http.Client? client,
  })  : baseUrl = baseUrl ?? defaultBaseUrl,
        client = client ?? http.Client();

  Uri _uri(String path) => Uri.parse('$baseUrl$apiPrefix$path');

  Map<String, String> _headers({String? token}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Never _handleErrorResponse(http.Response response) {
    String message = 'Request failed with status ${response.statusCode}';
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        if (body['detail'] != null) {
          message = body['detail'].toString();
        } else if (body['message'] != null) {
          message = body['message'].toString();
        } else if (body['error'] != null) {
          final err = body['error'];
          if (err is Map && err['message'] != null) {
            message = err['message'].toString();
          } else {
            message = err.toString();
          }
        }
      }
    } catch (_) {
      // Body not JSON, keep default status message
    }

    switch (response.statusCode) {
      case 401:
        throw MarketRatesUnauthorizedException(message: message);
      case 403:
        throw MarketRatesForbiddenException(message: message);
      case 404:
        throw MarketRatesNotFoundException(message: message);
      case 422:
        throw MarketRatesValidationException(message: message);
      default:
        throw MarketRatesServerException(message: message);
    }
  }

  Future<List<MarketRateItem>> _fetchRates(
    Uri uri, {
    String? token,
  }) async {
    try {
      final response = await client
          .get(uri, headers: _headers(token: token))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as List<dynamic>? ?? [];
        return data
            .whereType<Map<String, dynamic>>()
            .map(MarketRateItem.fromJson)
            .toList();
      }

      _handleErrorResponse(response);
    } on MarketRatesException {
      rethrow;
    } on SocketException catch (_) {
      throw const MarketRatesException(
        message:
            'Network connection unavailable. Please check your internet connection.',
        isNetworkError: true,
      );
    } on TimeoutException catch (_) {
      throw const MarketRatesException(
        message: 'Server request timed out. Please try again later.',
        isNetworkError: true,
      );
    }
  }

  @override
  Future<List<MarketRateItem>> getRates({
    required String accessToken,
  }) async {
    try {
      return await _fetchRates(_uri('/market-rates'), token: accessToken);
    } catch (_) {
      // Documented read fallback: public endpoint returns the identical
      // MarketRatePublic payload. If it also fails, its error propagates.
      return await _fetchRates(_uri('/public/market-rates'));
    }
  }

  @override
  Future<List<MarketRateItem>> getPublicRates() {
    return _fetchRates(_uri('/public/market-rates'));
  }

  @override
  Future<void> setRate({
    required String accessToken,
    required String cropType,
    required String grade,
    required double pricePerKg,
    required String effectiveDate,
  }) async {
    try {
      final uri = _uri('/market-rates');
      final payload = <String, dynamic>{
        'crop_type': cropType,
        'grade': grade,
        'price_per_kg': pricePerKg,
        'effective_date': effectiveDate,
      };

      final response = await client
          .post(
            uri,
            headers: _headers(token: accessToken),
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 201 || response.statusCode == 200) {
        return;
      }

      _handleErrorResponse(response);
    } on MarketRatesException {
      rethrow;
    } on SocketException catch (_) {
      throw const MarketRatesException(
        message:
            'Network connection unavailable. Please check your internet connection.',
        isNetworkError: true,
      );
    } on TimeoutException catch (_) {
      throw const MarketRatesException(
        message: 'Server request timed out. Please try again later.',
        isNetworkError: true,
      );
    }
  }
}

typedef MarketRatesRemoteDataSourceImpl = FastApiMarketRatesRemoteDataSource;
