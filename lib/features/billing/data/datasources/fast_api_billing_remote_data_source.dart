import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:agriflow_admin/core/network/api_client.dart';
import 'package:agriflow_admin/features/auth/domain/entities/auth_exception.dart';
import '../../domain/entities/billing_exception.dart';
import '../../domain/entities/billing_pagination.dart';
import '../../domain/entities/billing_transaction_item.dart';
import 'billing_remote_data_source.dart';

/// FastAPI implementation of BillingRemoteDataSource.
class FastApiBillingRemoteDataSource implements BillingRemoteDataSource {
  static const String defaultBaseUrl = ApiClient.defaultBaseUrl;
  static const String apiPrefix = '/api/v1';

  final String baseUrl;
  final http.Client client;
  final ApiClient? apiClient;

  FastApiBillingRemoteDataSource({
    String? baseUrl,
    http.Client? client,
    this.apiClient,
  })  : baseUrl = baseUrl ?? defaultBaseUrl,
        client = client ?? http.Client();

  Future<http.Response> _send(
    String method,
    String path, {
    required String accessToken,
    Map<String, dynamic>? queryParameters,
    Object? body,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final uri = _uri(path, queryParameters);
    try {
      final authClient = apiClient;
      if (authClient != null) {
        switch (method) {
          case 'GET':
            return await authClient.get(uri, timeout: timeout);
          case 'POST':
            return await authClient.post(uri, body: body, timeout: timeout);
          case 'PATCH':
            return await authClient.patch(uri, body: body, timeout: timeout);
        }
      }
      final headers = _headers(token: accessToken);
      switch (method) {
        case 'GET':
          return await client.get(uri, headers: headers).timeout(timeout);
        case 'POST':
          return await client.post(uri, headers: headers, body: body).timeout(timeout);
        case 'PATCH':
          return await client.patch(uri, headers: headers, body: body).timeout(timeout);
        default:
          throw UnsupportedError('Unsupported HTTP method: $method');
      }
    } on AuthException catch (e) {
      throw BillingException(
        message: e.message,
        statusCode: e.statusCode ?? (e.errorCode == 'SESSION_EXPIRED' ? 401 : null),
        isNetworkError: e.isNetworkError,
      );
    }
  }

  Uri _uri(String path, [Map<String, dynamic>? queryParameters]) {
    final base = Uri.parse('$baseUrl$apiPrefix$path');
    if (queryParameters != null && queryParameters.isNotEmpty) {
      final cleanParams = <String, String>{};
      queryParameters.forEach((key, value) {
        if (value != null && value.toString().isNotEmpty) {
          cleanParams[key] = value.toString();
        }
      });
      return base.replace(queryParameters: cleanParams);
    }
    return base;
  }

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
        throw BillingUnauthorizedException(message: message);
      case 403:
        throw BillingForbiddenException(message: message);
      case 404:
        throw BillingNotFoundException(message: message);
      case 409:
        throw BillingConflictException(message: message);
      case 422:
        throw BillingValidationException(message: message);
      default:
        throw BillingServerException(message: message);
    }
  }

  @override
  Future<({List<BillingTransactionItem> items, BillingPagination pagination})> getTransactions({
    required String accessToken,
    int page = 1,
    int pageSize = 20,
    String? search,
    String? referenceType,
    String? direction,
    String? status,
    String? fromDate,
    String? toDate,
    String? sort,
    String? order,
  }) async {
    try {
      final query = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };
      if (search != null && search.trim().isNotEmpty) {
        query['search'] = search.trim();
      }
      if (referenceType != null &&
          referenceType.trim().isNotEmpty &&
          referenceType.toLowerCase() != 'all') {
        query['reference_type'] = referenceType.trim().toLowerCase();
      }
      if (direction != null &&
          direction.trim().isNotEmpty &&
          direction.toLowerCase() != 'all') {
        query['direction'] = direction.trim().toLowerCase();
      }
      if (status != null &&
          status.trim().isNotEmpty &&
          status.toLowerCase() != 'all') {
        query['status'] = status.trim().toLowerCase();
      }
      if (fromDate != null && fromDate.trim().isNotEmpty) {
        query['from_date'] = fromDate.trim();
      }
      if (toDate != null && toDate.trim().isNotEmpty) {
        query['to_date'] = toDate.trim();
      }
      if (sort != null && sort.isNotEmpty) {
        query['sort'] = sort;
      }
      if (order != null && order.isNotEmpty) {
        query['order'] = order;
      }

      final response = await _send(
        'GET',
        '/transactions',
        accessToken: accessToken,
        queryParameters: query,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as List<dynamic>? ?? [];
        final items = data
            .whereType<Map<String, dynamic>>()
            .map((item) => BillingTransactionItem.fromJson(item))
            .toList();

        final paginationJson = json['pagination'] as Map<String, dynamic>? ?? {};
        final pagination = BillingPagination.fromJson(paginationJson);

        return (items: items, pagination: pagination);
      }

      _handleErrorResponse(response);
    } on SocketException catch (_) {
      throw const BillingException(
        message: 'Network connection unavailable. Please check your internet connection.',
        isNetworkError: true,
      );
    } on TimeoutException catch (_) {
      throw const BillingException(
        message: 'Server request timed out. Please try again later.',
        isNetworkError: true,
      );
    }
  }

  @override
  Future<BillingTransactionItem> createTransaction({
    required String accessToken,
    required String farmerId,
    required double amount,
    required String direction,
    required String referenceType,
    String? description,
  }) async {
    try {
      final payload = <String, dynamic>{
        'farmer_id': farmerId,
        'amount': amount.toStringAsFixed(2),
        'direction': direction.trim().toLowerCase(),
        'reference_type': referenceType.trim().toLowerCase(),
      };
      if (description != null && description.trim().isNotEmpty) {
        payload['description'] = description.trim();
      }

      final response = await _send(
        'POST',
        '/transactions',
        accessToken: accessToken,
        body: jsonEncode(payload),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as Map<String, dynamic>? ?? json;
        return BillingTransactionItem.fromJson(data);
      }

      _handleErrorResponse(response);
    } on SocketException catch (_) {
      throw const BillingException(
        message: 'Network connection unavailable. Please check your internet connection.',
        isNetworkError: true,
      );
    } on TimeoutException catch (_) {
      throw const BillingException(
        message: 'Server request timed out. Please try again later.',
        isNetworkError: true,
      );
    }
  }

  @override
  Future<BillingTransactionItem> payTransaction({
    required String accessToken,
    required String transactionId,
    String? description,
  }) async {
    try {
      final payload = <String, dynamic>{};
      if (description != null && description.trim().isNotEmpty) {
        payload['description'] = description.trim();
      }

      final response = await _send(
        'PATCH',
        '/transactions/$transactionId/pay',
        accessToken: accessToken,
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as Map<String, dynamic>? ?? json;
        return BillingTransactionItem.fromJson(data);
      }

      _handleErrorResponse(response);
    } on SocketException catch (_) {
      throw const BillingException(
        message: 'Network connection unavailable. Please check your internet connection.',
        isNetworkError: true,
      );
    } on TimeoutException catch (_) {
      throw const BillingException(
        message: 'Server request timed out. Please try again later.',
        isNetworkError: true,
      );
    }
  }

  @override
  Future<Map<String, ({String name, String phone, String? village})>> getFarmers({
    required String accessToken,
  }) async {
    try {
      final response = await _send(
        'GET',
        '/farmers',
        accessToken: accessToken,
        queryParameters: {'page': 1, 'page_size': 100},
        timeout: const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as List<dynamic>? ?? [];
        final map = <String, ({String name, String phone, String? village})>{};
        for (final item in data) {
          if (item is Map<String, dynamic> && item['id'] != null) {
            final id = item['id'].toString();
            final name = item['name'] as String? ?? 'Farmer';
            final phone = item['phone'] as String? ?? '';
            final village = item['village'] as String? ?? item['address'] as String?;
            map[id] = (name: name, phone: phone, village: village);
          }
        }
        return map;
      }
      return {};
    } catch (_) {
      return {};
    }
  }
}

typedef BillingRemoteDataSourceImpl = FastApiBillingRemoteDataSource;
