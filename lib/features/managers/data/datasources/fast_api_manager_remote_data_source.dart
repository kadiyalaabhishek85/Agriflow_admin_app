import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../domain/entities/manager_item.dart';
import '../../domain/entities/manager_pagination.dart';
import '../../domain/entities/managers_exception.dart';
import 'manager_remote_data_source.dart';

/// FastAPI implementation of ManagerRemoteDataSource.
///
/// Verified endpoints (live OpenAPI, re-verified 2026-09-28):
/// - `GET   /api/v1/managers`                               → PaginatedResponse[ManagerPublic]
/// - `POST  /api/v1/managers`                               → 201 SuccessResponse[ManagerPublic]
/// - `PATCH /api/v1/managers/{manager_id}/status`           → SuccessResponse[ManagerPublic]
/// - `POST  /api/v1/managers/{manager_id}/reset-password`   → MessageResponse
class FastApiManagerRemoteDataSource implements ManagerRemoteDataSource {
  static const String defaultBaseUrl =
      'https://agriflow-backend-t8o4.onrender.com';
  static const String apiPrefix = '/api/v1';

  final String baseUrl;
  final http.Client client;

  FastApiManagerRemoteDataSource({
    String? baseUrl,
    http.Client? client,
  })  : baseUrl = baseUrl ?? defaultBaseUrl,
        client = client ?? http.Client();

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
      final response = await client
          .get(uri, headers: _headers(accessToken))
          .timeout(const Duration(seconds: 15));

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

      final response = await client
          .post(
            _uri('/managers'),
            headers: _headers(accessToken),
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));

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
      final response = await client
          .patch(
            _uri('/managers/$managerId/status'),
            headers: _headers(accessToken),
            body: jsonEncode({'status': status}),
          )
          .timeout(const Duration(seconds: 15));

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
      final response = await client
          .post(
            _uri('/managers/$managerId/reset-password'),
            headers: _headers(accessToken),
            body: jsonEncode({'new_password': newPassword}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return (json['message'] as String?) ?? 'Password reset successful.';
      }

      _handleErrorResponse(response);
    });
  }
}

typedef ManagerRemoteDataSourceImpl = FastApiManagerRemoteDataSource;
