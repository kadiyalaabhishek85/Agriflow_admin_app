import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_client.dart';
import '../../domain/entities/notification_item.dart';

/// Remote data source for Admin/Manager notifications.
///
/// Uses the verified live FastAPI endpoints:
/// - GET  /api/v1/notifications
/// - PATCH /api/v1/notifications/{notification_id}/read
/// - PATCH /api/v1/notifications/read-all
/// - POST  /api/v1/events/ticket
/// - GET   /api/v1/events/stream?ticket=...
abstract class NotificationRemoteDataSource {
  /// Fetches paginated notifications for the authenticated user.
  Future<List<NotificationItem>> fetchNotifications({
    required String accessToken,
    int page,
    int pageSize,
  });

  /// Marks a single notification as read.
  Future<void> markRead({
    required String accessToken,
    required String notificationId,
  });

  /// Marks all notifications as read.
  Future<void> markAllRead({required String accessToken});

  /// Obtains a single-use SSE ticket for real-time event streaming.
  Future<String> getStreamTicket({required String accessToken});
}

class FastApiNotificationRemoteDataSource
    implements NotificationRemoteDataSource {
  static const String defaultBaseUrl =
      'https://agriflow-backend-t8o4.onrender.com';
  static const String apiPrefix = '/api/v1';

  final String baseUrl;
  final http.Client client;

  /// When provided, every request is routed through [ApiClient], which reads
  /// the access token from secure storage at request time, silently refreshes
  /// it on 401 (single retry), and invokes its session-expired callback when
  /// refresh fails. The `accessToken` argument of each method is then ignored.
  ///
  /// This exists because backend access tokens expire after 900 seconds
  /// (verified live: JWT `exp = iat + 900`), and a token captured once at
  /// shell startup stops working after 15 minutes.
  final ApiClient? apiClient;

  FastApiNotificationRemoteDataSource({
    String? baseUrl,
    http.Client? client,
    this.apiClient,
  })  : baseUrl = baseUrl ?? defaultBaseUrl,
        client = client ?? http.Client();

  Uri _uri(String path, [Map<String, dynamic>? queryParams]) {
    final base = Uri.parse('$baseUrl$apiPrefix$path');
    if (queryParams != null && queryParams.isNotEmpty) {
      return base.replace(
        queryParameters:
            queryParams.map((k, v) => MapEntry(k, v.toString())),
      );
    }
    return base;
  }

  String _pathWithQuery(String path, Map<String, dynamic>? queryParams) {
    if (queryParams == null || queryParams.isEmpty) return path;
    final query = queryParams.entries
        .map((e) =>
            '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value.toString())}')
        .join('&');
    return '$path?$query';
  }

  Map<String, String> _headers({required String token}) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<http.Response> _send(
    String method,
    String path, {
    Map<String, dynamic>? queryParams,
    required String accessToken,
    Duration timeout = const Duration(seconds: 12),
  }) {
    if (apiClient != null) {
      final target = _pathWithQuery(path, queryParams);
      switch (method) {
        case 'GET':
          return apiClient!.get(target, timeout: timeout);
        case 'POST':
          return apiClient!.post(target, timeout: timeout);
        case 'PATCH':
          return apiClient!.patch(target, timeout: timeout);
        case 'DELETE':
          return apiClient!.delete(target, timeout: timeout);
        default:
          throw ArgumentError('Unsupported method $method');
      }
    }

    final uri = _uri(path, queryParams);
    final request = switch (method) {
      'GET' => client.get(uri, headers: _headers(token: accessToken)),
      'POST' => client.post(uri, headers: _headers(token: accessToken)),
      'PATCH' => client.patch(uri, headers: _headers(token: accessToken)),
      'DELETE' => client.delete(uri, headers: _headers(token: accessToken)),
      _ => throw ArgumentError('Unsupported method $method'),
    };
    return request.timeout(timeout);
  }

  @override
  Future<List<NotificationItem>> fetchNotifications({
    required String accessToken,
    int page = 1,
    int pageSize = 50,
  }) async {
    final response = await _send(
      'GET',
      '/notifications',
      queryParams: {
        'page': page,
        'page_size': pageSize,
        'sort': 'created_at',
        'order': 'desc',
      },
      accessToken: accessToken,
      timeout: const Duration(seconds: 12),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final list = (json['data'] is List) ? json['data'] as List : [];
      return list
          .map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    if (response.statusCode == 401) {
      throw const SocketException('Session expired — please log in again.');
    }

    throw Exception(
        'Failed to fetch notifications (HTTP ${response.statusCode})');
  }

  @override
  Future<void> markRead({
    required String accessToken,
    required String notificationId,
  }) async {
    final response = await _send(
      'PATCH',
      '/notifications/$notificationId/read',
      accessToken: accessToken,
      timeout: const Duration(seconds: 10),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to mark notification read');
    }
  }

  @override
  Future<void> markAllRead({required String accessToken}) async {
    final response = await _send(
      'PATCH',
      '/notifications/read-all',
      accessToken: accessToken,
      timeout: const Duration(seconds: 10),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to mark all notifications read');
    }
  }

  @override
  Future<String> getStreamTicket({required String accessToken}) async {
    final response = await _send(
      'POST',
      '/events/ticket',
      accessToken: accessToken,
      timeout: const Duration(seconds: 10),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final data = json['data'] ?? json;
      return (data['ticket'] ?? '').toString();
    }

    throw Exception('Failed to get stream ticket (HTTP ${response.statusCode})');
  }

  /// Builds the SSE stream URI for a single-use ticket.
  ///
  /// Verified live: `GET /api/v1/events/stream?ticket=...` requires NO
  /// Authorization header — the single-use ticket is the only credential.
  Uri buildStreamUri(String ticket) =>
      _uri('/events/stream', {'ticket': ticket});
}
