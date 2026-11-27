import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:agriflow_admin/core/network/api_client.dart';
import 'package:agriflow_admin/features/auth/domain/entities/auth_exception.dart';

import '../../domain/entities/audit_log_item.dart';
import '../../domain/entities/audit_log_pagination.dart';
import '../../domain/entities/event_logs_exception.dart';
import 'event_log_remote_data_source.dart';

/// FastAPI implementation of EventLogRemoteDataSource.
///
/// Verified endpoint (live OpenAPI):
/// - `GET /api/v1/admin/audit-logs` → PaginatedResponse[AuditLogPublic]
class FastApiEventLogRemoteDataSource implements EventLogRemoteDataSource {
  static const String defaultBaseUrl = ApiClient.defaultBaseUrl;
  static const String apiPrefix = '/api/v1';

  final String baseUrl;
  final http.Client client;
  final ApiClient? apiClient;

  FastApiEventLogRemoteDataSource({
    String? baseUrl,
    http.Client? client,
    this.apiClient,
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
        throw EventLogsUnauthorizedException(message: message);
      case 403:
        throw EventLogsForbiddenException(message: message);
      default:
        throw EventLogsServerException(message: message);
    }
  }

  /// Wraps SocketException/TimeoutException once for every call below.
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on EventLogsException {
      rethrow;
    } on SocketException catch (_) {
      throw const EventLogsException(
        message:
            'Network connection unavailable. Please check your internet connection.',
        isNetworkError: true,
      );
    } on TimeoutException catch (_) {
      throw const EventLogsException(
        message: 'Server request timed out. Please try again later.',
        isNetworkError: true,
      );
    }
  }

  @override
  Future<({
    List<AuditLogItem> items,
    AuditLogPagination pagination,
  })> getAuditLogs({
    required String accessToken,
    int page = 1,
    int pageSize = 20,
    String? search,
    String? role,
    String? sort,
    String? order,
  }) {
    return _guard(() async {
      final query = <String, String>{
        'page': '$page',
        'page_size': '$pageSize',
        'sort': sort ?? 'created_at',
        'order': order ?? 'desc',
      };
      if (search != null && search.isNotEmpty) query['search'] = search;
      if (role != null && role.isNotEmpty && role != 'all') query['role'] = role;

      final uri = _uri('/admin/audit-logs', query);
      final http.Response response;
      try {
        final authClient = apiClient;
        if (authClient != null) {
          response = await authClient.get(uri, timeout: const Duration(seconds: 25));
        } else {
          response = await client
              .get(uri, headers: _headers(accessToken))
              .timeout(const Duration(seconds: 25));
        }
      } on AuthException catch (e) {
        throw EventLogsUnauthorizedException(message: e.message);
      }

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as List<dynamic>? ?? [];
        final pagination = AuditLogPagination.fromJson(
          (json['pagination'] as Map<String, dynamic>?) ?? const {},
        );
        return (
          items: data
              .whereType<Map<String, dynamic>>()
              .map(AuditLogItem.fromJson)
              .toList(),
          pagination: pagination,
        );
      }

      _handleErrorResponse(response);
    });
  }
}
