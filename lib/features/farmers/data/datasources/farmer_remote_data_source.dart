import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:agriflow_admin/core/network/api_client.dart';
import 'package:agriflow_admin/features/auth/domain/entities/auth_exception.dart';
import '../../domain/entities/bank_change_request_item.dart';
import '../../domain/entities/farmer_exception.dart';
import '../../domain/entities/farmer_item.dart';
import '../../domain/entities/farmer_pagination.dart';

/// Abstract remote data source contract for All Farmers module.
abstract class FarmerRemoteDataSource {
  Future<({List<FarmerItem> items, FarmerPagination pagination})> getFarmers({
    required String accessToken,
    int page = 1,
    int pageSize = 20,
    String? search,
    String? status,
    String? sort,
    String? order,
  });

  Future<FarmerItem> getFarmerDetail({
    required String accessToken,
    required String farmerId,
  });

  Future<FarmerItem> setFarmerApproval({
    required String accessToken,
    required String farmerId,
    required String status,
  });

  /// PATCH /farmers/{farmer_id} — partial profile update (FEAT-04).
  Future<FarmerItem> updateFarmerProfile({
    required String accessToken,
    required String farmerId,
    String? name,
    String? phone,
    String? email,
    String? address,
    double? acresOfLand,
    String? soilType,
    String? irrigationType,
    String? primaryCrop,
    String? secondaryCrop,
  });

  Future<FarmerItem> createFarmer({
    required String accessToken,
    required String name,
    required String phone,
    required String password,
    String? email,
    String? address,
    double? acresOfLand,
    String? cropAddress,
  });

  Future<({List<BankChangeRequestItem> items, FarmerPagination pagination})> getBankChangeRequests({
    required String accessToken,
    int page = 1,
    int pageSize = 20,
    String? search,
    String? status,
    String? sort,
    String? order,
  });

  Future<void> reviewBankChangeRequest({
    required String accessToken,
    required String requestId,
    required bool approve,
    String? adminNotes,
  });
}

/// FastAPI implementation of FarmerRemoteDataSource.
class FastApiFarmerRemoteDataSource implements FarmerRemoteDataSource {
  static const String defaultBaseUrl = ApiClient.defaultBaseUrl;
  static const String apiPrefix = '/api/v1';

  final String baseUrl;
  final http.Client client;
  final ApiClient? apiClient;

  FastApiFarmerRemoteDataSource({
    String? baseUrl,
    http.Client? client,
    this.apiClient,
  })  : baseUrl = baseUrl ?? defaultBaseUrl,
        client = client ?? http.Client();

  Future<http.Response> _send(
    String method,
    Uri uri, {
    required String accessToken,
    Object? body,
    Duration timeout = const Duration(seconds: 25),
  }) async {
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
          return await client
              .post(uri, headers: headers, body: body)
              .timeout(timeout);
        case 'PATCH':
          return await client
              .patch(uri, headers: headers, body: body)
              .timeout(timeout);
        default:
          throw UnsupportedError('Unsupported HTTP method: $method');
      }
    } on AuthException catch (e) {
      throw FarmerUnauthorizedException(message: e.message);
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
          final detail = body['detail'];
          if (detail is List && detail.isNotEmpty) {
            final first = detail.first;
            message = first is Map && first['msg'] != null
                ? first['msg'].toString()
                : detail.toString();
          } else {
            message = detail.toString();
          }
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
      // Body not JSON
    }

    switch (response.statusCode) {
      case 401:
        throw FarmerUnauthorizedException(message: message);
      case 403:
        throw FarmerForbiddenException(message: message);
      case 404:
        throw FarmerNotFoundException(message: message);
      case 409:
        throw FarmerConflictException(message: message);
      case 422:
        throw FarmerValidationException(message: message);
      default:
        throw FarmerServerException(message: message);
    }
  }

  @override
  Future<({List<FarmerItem> items, FarmerPagination pagination})> getFarmers({
    required String accessToken,
    int page = 1,
    int pageSize = 20,
    String? search,
    String? status,
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
      if (status != null && status.trim().isNotEmpty && status.toLowerCase() != 'all') {
        query['status'] = status.trim().toLowerCase();
      }
      if (sort != null && sort.trim().isNotEmpty) {
        query['sort'] = sort.trim();
      }
      if (order != null && order.trim().isNotEmpty) {
        query['order'] = order.trim().toLowerCase();
      }

      final uri = _uri('/farmers', query);
      final response = await _send('GET', uri, accessToken: accessToken);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is! Map<String, dynamic>) {
          throw const FarmerServerException(message: 'Malformed response structure');
        }

        final dataList = decoded['data'] as List<dynamic>? ?? [];
        final items = dataList
            .whereType<Map<String, dynamic>>()
            .map((json) => FarmerItem.fromJson(json))
            .toList();

        final paginationJson = decoded['pagination'] as Map<String, dynamic>? ?? {};
        final pagination = FarmerPagination.fromJson(paginationJson);

        return (items: items, pagination: pagination);
      } else {
        _handleErrorResponse(response);
      }
    } on SocketException {
      throw const FarmerException(
        message: 'No internet connection. Please verify your network.',
        isNetworkError: true,
      );
    } on TimeoutException {
      throw const FarmerException(
        message: 'Connection timed out. Please try again.',
        isNetworkError: true,
      );
    } on FarmerException {
      rethrow;
    } catch (e) {
      throw FarmerException(message: 'Unexpected error: $e');
    }
  }

  @override
  Future<FarmerItem> getFarmerDetail({
    required String accessToken,
    required String farmerId,
  }) async {
    try {
      final uri = _uri('/farmers/$farmerId');
      final response = await _send('GET', uri, accessToken: accessToken);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is! Map<String, dynamic>) {
          throw const FarmerServerException(message: 'Malformed response structure');
        }

        final data = decoded['data'] as Map<String, dynamic>? ?? decoded;
        return FarmerItem.fromJson(data);
      } else {
        _handleErrorResponse(response);
      }
    } on SocketException {
      throw const FarmerException(
        message: 'No internet connection. Please verify your network.',
        isNetworkError: true,
      );
    } on TimeoutException {
      throw const FarmerException(
        message: 'Connection timed out. Please try again.',
        isNetworkError: true,
      );
    } on FarmerException {
      rethrow;
    } catch (e) {
      throw FarmerException(message: 'Unexpected error: $e');
    }
  }

  @override
  Future<FarmerItem> setFarmerApproval({
    required String accessToken,
    required String farmerId,
    required String status,
  }) async {
    try {
      final uri = _uri('/farmers/$farmerId/approval');
      final body = jsonEncode({
        'status': status.toLowerCase().trim(),
      });

      final response = await _send(
        'PATCH',
        uri,
        accessToken: accessToken,
        body: body,
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is! Map<String, dynamic>) {
          throw const FarmerServerException(message: 'Malformed response structure');
        }
        final data = decoded['data'] as Map<String, dynamic>? ?? decoded;
        return FarmerItem.fromJson(data);
      } else {
        _handleErrorResponse(response);
      }
    } on SocketException {
      throw const FarmerException(
        message: 'No internet connection. Please verify your network.',
        isNetworkError: true,
      );
    } on TimeoutException {
      throw const FarmerException(
        message: 'Connection timed out. Please try again.',
        isNetworkError: true,
      );
    } on FarmerException {
      rethrow;
    } catch (e) {
      throw FarmerException(message: 'Unexpected error: $e');
    }
  }

  @override
  Future<FarmerItem> updateFarmerProfile({
    required String accessToken,
    required String farmerId,
    String? name,
    String? phone,
    String? email,
    String? address,
    double? acresOfLand,
    String? soilType,
    String? irrigationType,
    String? primaryCrop,
    String? secondaryCrop,
  }) async {
    try {
      final uri = _uri('/farmers/$farmerId');
      final body = <String, dynamic>{};
      if (name != null && name.trim().isNotEmpty) body['name'] = name.trim();
      if (phone != null && phone.trim().isNotEmpty) body['phone'] = phone.trim();
      if (email != null && email.trim().isNotEmpty) body['email'] = email.trim();
      if (address != null && address.trim().isNotEmpty) body['address'] = address.trim();
      if (acresOfLand != null) body['acres_of_land'] = acresOfLand;
      if (soilType != null && soilType.trim().isNotEmpty) body['soil_type'] = soilType.trim();
      if (irrigationType != null && irrigationType.trim().isNotEmpty) {
        body['irrigation_type'] = irrigationType.trim();
      }
      if (primaryCrop != null && primaryCrop.trim().isNotEmpty) {
        body['primary_crop'] = primaryCrop.trim();
      }
      if (secondaryCrop != null && secondaryCrop.trim().isNotEmpty) {
        body['secondary_crop'] = secondaryCrop.trim();
      }

      final response = await _send(
        'PATCH',
        uri,
        accessToken: accessToken,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is! Map<String, dynamic>) {
          throw const FarmerServerException(message: 'Malformed response structure');
        }
        final data = decoded['data'] as Map<String, dynamic>? ?? decoded;
        return FarmerItem.fromJson(data);
      } else {
        _handleErrorResponse(response);
      }
    } on SocketException {
      throw const FarmerException(
        message: 'No internet connection. Please verify your network.',
        isNetworkError: true,
      );
    } on TimeoutException {
      throw const FarmerException(
        message: 'Connection timed out. Please try again.',
        isNetworkError: true,
      );
    } on FarmerException {
      rethrow;
    } catch (e) {
      throw FarmerException(message: 'Unexpected error: $e');
    }
  }

  @override
  Future<FarmerItem> createFarmer({
    required String accessToken,
    required String name,
    required String phone,
    required String password,
    String? email,
    String? address,
    double? acresOfLand,
    String? cropAddress,
  }) async {
    try {
      final uri = _uri('/farmers');
      final payload = <String, dynamic>{
        'name': name.trim(),
        'phone': phone.trim(),
        'password': password,
      };

      if (email != null && email.trim().isNotEmpty) {
        payload['email'] = email.trim();
      }
      if (address != null && address.trim().isNotEmpty) {
        payload['address'] = address.trim();
      }
      if (acresOfLand != null) {
        payload['acres_of_land'] = acresOfLand;
      }
      if (cropAddress != null && cropAddress.trim().isNotEmpty) {
        payload['crop_address'] = cropAddress.trim();
      }

      final response = await _send(
        'POST',
        uri,
        accessToken: accessToken,
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);
        if (decoded is! Map<String, dynamic>) {
          throw const FarmerServerException(message: 'Malformed response structure');
        }
        final data = decoded['data'] as Map<String, dynamic>? ?? decoded;
        return FarmerItem.fromJson(data);
      } else {
        _handleErrorResponse(response);
      }
    } on SocketException {
      throw const FarmerException(
        message: 'No internet connection. Please verify your network.',
        isNetworkError: true,
      );
    } on TimeoutException {
      throw const FarmerException(
        message: 'Connection timed out. Please try again.',
        isNetworkError: true,
      );
    } on FarmerException {
      rethrow;
    } catch (e) {
      throw FarmerException(message: 'Unexpected error: $e');
    }
  }

  @override
  Future<({List<BankChangeRequestItem> items, FarmerPagination pagination})> getBankChangeRequests({
    required String accessToken,
    int page = 1,
    int pageSize = 20,
    String? search,
    String? status,
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
      if (status != null && status.trim().isNotEmpty && status.toLowerCase() != 'all') {
        query['status'] = status.trim().toLowerCase();
      }
      if (sort != null && sort.trim().isNotEmpty) {
        query['sort'] = sort.trim();
      }
      if (order != null && order.trim().isNotEmpty) {
        query['order'] = order.trim().toLowerCase();
      }

      final uri = _uri('/farmers/bank-change-requests', query);
      final response = await _send('GET', uri, accessToken: accessToken);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is! Map<String, dynamic>) {
          throw const FarmerServerException(message: 'Malformed response structure');
        }

        final dataList = decoded['data'] as List<dynamic>? ?? [];
        final items = dataList
            .whereType<Map<String, dynamic>>()
            .map((json) => BankChangeRequestItem.fromJson(json))
            .toList();

        final paginationJson = decoded['pagination'] as Map<String, dynamic>? ?? {};
        final pagination = FarmerPagination.fromJson(paginationJson);

        return (items: items, pagination: pagination);
      } else {
        _handleErrorResponse(response);
      }
    } on SocketException {
      throw const FarmerException(
        message: 'No internet connection. Please verify your network.',
        isNetworkError: true,
      );
    } on TimeoutException {
      throw const FarmerException(
        message: 'Connection timed out. Please try again.',
        isNetworkError: true,
      );
    } on FarmerException {
      rethrow;
    } catch (e) {
      throw FarmerException(message: 'Unexpected error: $e');
    }
  }

  @override
  Future<void> reviewBankChangeRequest({
    required String accessToken,
    required String requestId,
    required bool approve,
    String? adminNotes,
  }) async {
    try {
      final uri = _uri('/farmers/bank-change-requests/$requestId');
      final payload = <String, dynamic>{
        'approve': approve,
        'admin_notes': adminNotes,
      };

      final response = await _send(
        'PATCH',
        uri,
        accessToken: accessToken,
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        return;
      } else {
        _handleErrorResponse(response);
      }
    } on SocketException {
      throw const FarmerException(
        message: 'No internet connection. Please verify your network.',
        isNetworkError: true,
      );
    } on TimeoutException {
      throw const FarmerException(
        message: 'Connection timed out. Please try again.',
        isNetworkError: true,
      );
    } on FarmerException {
      rethrow;
    } catch (e) {
      throw FarmerException(message: 'Unexpected error: $e');
    }
  }
}
