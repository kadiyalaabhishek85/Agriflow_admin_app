import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:agriflow_admin/core/network/api_client.dart';
import 'package:agriflow_admin/features/auth/domain/entities/auth_exception.dart';

import '../../domain/entities/manager_item.dart';
import '../../domain/entities/manager_pagination.dart';
import '../../domain/entities/managers_exception.dart';
import 'manager_remote_data_source.dart';

/// FastAPI implementation of ManagerRemoteDataSource.
class FastApiManagerRemoteDataSource implements ManagerRemoteDataSource {
  static const String defaultBaseUrl = ApiClient.defaultBaseUrl;
  static const String apiPrefix = '/api/v1';

  final String baseUrl;
  final http.Client client;
  final ApiClient? apiClient;

  FastApiManagerRemoteDataSource({
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
      final headers = _headers(accessToken);
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
      throw ManagersUnauthorizedException(message: e.message);
    }
  }

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$baseUrl$apiPrefix$path').replace(queryParameters: query);

  Map<String, String> _headers(String token) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
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
        throw ManagersUnauthorizedException(message: message);
      case 403:
        throw ManagersForbiddenException(message: message);
      case 404:
        throw ManagersNotFoundException(message: message);
      case 422:
        throw ManagersValidationException(message: message);
      default:
        throw ManagersServerException(message: message);
    }
  }

  /// Wraps SocketException/TimeoutException once for every call below.
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on ManagersException {
      rethrow;
    } on SocketException catch (_) {
      throw const ManagersException(
        message:
            'Network connection unavailable. Please check your internet connection.',
        isNetworkError: true,
      );
    } on TimeoutException catch (_) {
      throw const ManagersException(
        message: 'Server request timed out. Please try again later.',
        isNetworkError: true,
      );
    }
  }

  Map<String, String> _listQuery({
    required int page,
    required int pageSize,
    String? search,
    String? status,
    String? sort,
    String? order,
  }) {
    final query = <String, String>{
      'page': '$page',
      'page_size': '$pageSize',
    };
    if (search != null && search.isNotEmpty) query['search'] = search;
    if (status != null && status.isNotEmpty) query['status'] = status;
    query['sort'] = sort ?? 'created_at';
    query['order'] = order ?? 'desc';
    return query;
  }

  @override
  Future<({List<ManagerItem> items, ManagerPagination pagination})>
      getManagers({
    required String accessToken,
    int page = 1,
    int pageSize = 20,
    String? search,
    String? status,
    String? sort,
    String? order,
  }) {
    return _guard(() async {
      final uri = _uri('/managers', _listQuery(
        page: page,
        pageSize: pageSize,
        search: search,
        status: status,
        sort: sort,
        order: order,
      ));
      final response = await _send('GET', uri, accessToken: accessToken);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as List<dynamic>? ?? [];
        final pagination = ManagerPagination.fromJson(
          (json['pagination'] as Map<String, dynamic>?) ?? const {},
        );
        return (
          items: data
              .whereType<Map<String, dynamic>>()
              .map(ManagerItem.fromJson)
              .toList(),
          pagination: pagination,
        );
      }

      _handleErrorResponse(response);
    });
  }

  @override
  Future<ManagerItem> createManager({
    required String accessToken,
    required String name,
    required String phone,
    required String password,
    String? email,
    String? assignedRegion,
    String? department,
  }) {
    return _guard(() async {
      final payload = <String, dynamic>{
        'name': name,
        'phone': phone,
        'password': password,
        if (email != null && email.isNotEmpty) 'email': email,
        'role': 'manager',
        if (assignedRegion != null && assignedRegion.isNotEmpty)
          'assigned_region': assignedRegion,
        if (department != null && department.isNotEmpty)
          'department': department,
      };

      final response = await _send(
        'POST',
        _uri('/managers'),
        accessToken: accessToken,
        body: jsonEncode(payload),
      );

      // Contract: 201 Created (SuccessResponse[ManagerPublic]).
      if (response.statusCode == 201 || response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as Map<String, dynamic>?;
        if (data == null) {
          throw const ManagersServerException(
            message: 'Unexpected response while creating manager.',
          );
        }
        return ManagerItem.fromJson(data);
      }

      _handleErrorResponse(response);
    });
  }

  @override
  Future<ManagerItem> updateManagerStatus({
    required String accessToken,
    required String managerId,
    required String status,
  }) {
    return _guard(() async {
      final response = await _send(
        'PATCH',
        _uri('/managers/$managerId/status'),
        accessToken: accessToken,
        body: jsonEncode({'status': status}),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as Map<String, dynamic>?;
        if (data == null) {
          throw const ManagersServerException(
            message: 'Unexpected response while updating manager status.',
          );
        }
        return ManagerItem.fromJson(data);
      }

      _handleErrorResponse(response);
    });
  }

  @override
  Future<String> resetManagerPassword({
    required String accessToken,
    required String managerId,
    required String newPassword,
  }) {
    return _guard(() async {
      final response = await _send(
        'POST',
        _uri('/managers/$managerId/reset-password'),
        accessToken: accessToken,
        body: jsonEncode({'new_password': newPassword}),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return (json['message'] as String?) ?? 'Password reset successful.';
      }

      _handleErrorResponse(response);
    });
  }
}

typedef ManagerRemoteDataSourceImpl = FastApiManagerRemoteDataSource;
