import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../features/auth/domain/entities/auth_exception.dart';
import '../../features/auth/domain/entities/auth_session.dart';
import '../../features/auth/data/datasources/auth_local_data_source.dart';

/// Centralized authenticated HTTP client wrapper for AgriFlow Admin & Manager mobile app.
///
/// Implements:
/// 1. Automatic 401 interception:
///    - When a request receives 401, attempts a silent token refresh via `POST /api/v1/auth/refresh`.
///    - Mutex/lock ensures only one refresh request runs even if multiple calls fail with 401 concurrently.
///    - On successful refresh: updates stored tokens in `AuthLocalDataSource` and retries original request exactly once.
///    - On refresh failure (or 401 on refresh): clears local storage, triggers `onSessionExpired` callback, and throws `AuthException`.
/// 2. Request deduplication/lock preventing infinite refresh loops.
/// 3. Centralized header management with automatic Bearer token injection.
class ApiClient {
  static const String defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://agriflow-backend-t8o4.onrender.com',
  );
  static const String apiPrefix = '/api/v1';

  final String baseUrl;
  final http.Client _httpClient;
  final AuthLocalDataSource localDataSource;
  final void Function()? onSessionExpired;

  // Mutex lock for token refreshing
  Completer<String?>? _refreshCompleter;

  ApiClient({
    String? baseUrl,
    http.Client? httpClient,
    required this.localDataSource,
    this.onSessionExpired,
  })  : baseUrl = baseUrl ?? defaultBaseUrl,
        _httpClient = httpClient ?? http.Client();

  Uri buildUri(String path, [Map<String, dynamic>? queryParams]) {
    final base = Uri.parse('$baseUrl$apiPrefix$path');
    if (queryParams != null && queryParams.isNotEmpty) {
      final sanitized = <String, dynamic>{};
      queryParams.forEach((key, value) {
        if (value != null && value.toString().isNotEmpty) {
          sanitized[key] = value.toString();
        }
      });
      return base.replace(queryParameters: sanitized);
    }
    return base;
  }

  Uri _resolveUri(dynamic url) {
    if (url is Uri) return url;
    if (url is String) {
      if (url.startsWith('http://') || url.startsWith('https://')) {
        return Uri.parse(url);
      }
      return buildUri(url);
    }
    throw ArgumentError('url must be Uri or String');
  }

  /// Executes an HTTP GET request with automatic Bearer token injection and 401 refresh handling.
  Future<http.Response> get(
    dynamic url, {
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final uri = _resolveUri(url);
    return _sendWithRetry(
      () async => _httpClient.get(
        uri,
        headers: await _buildHeaders(headers),
      ),
      timeout: timeout,
    );
  }

  /// Executes an HTTP POST request with automatic Bearer token injection and 401 refresh handling.
  Future<http.Response> post(
    dynamic url, {
    Map<String, String>? headers,
    Object? body,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final uri = _resolveUri(url);
    return _sendWithRetry(
      () async => _httpClient.post(
        uri,
        headers: await _buildHeaders(headers),
        body: body,
      ),
      timeout: timeout,
    );
  }

  /// Executes an HTTP PATCH request with automatic Bearer token injection and 401 refresh handling.
  Future<http.Response> patch(
    dynamic url, {
    Map<String, String>? headers,
    Object? body,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final uri = _resolveUri(url);
    return _sendWithRetry(
      () async => _httpClient.patch(
        uri,
        headers: await _buildHeaders(headers),
        body: body,
      ),
      timeout: timeout,
    );
  }

  /// Executes an HTTP DELETE request with automatic Bearer token injection and 401 refresh handling.
  Future<http.Response> delete(
    dynamic url, {
    Map<String, String>? headers,
    Object? body,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final uri = _resolveUri(url);
    return _sendWithRetry(
      () async => _httpClient.delete(
        uri,
        headers: await _buildHeaders(headers),
        body: body,
      ),
      timeout: timeout,
    );
  }

  Future<Map<String, String>> _buildHeaders(Map<String, String>? customHeaders) async {
    final token = await localDataSource.getAccessToken();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    if (customHeaders != null) {
      headers.addAll(customHeaders);
    }
    return headers;
  }

  Future<http.Response> _sendWithRetry(
    Future<http.Response> Function() requestFn, {
    required Duration timeout,
  }) async {
    http.Response response;
    try {
      response = await requestFn().timeout(timeout);
    } on SocketException catch (_) {
      throw const AuthException(
        message: 'Unable to connect. Please check your internet connection.',
        isNetworkError: true,
      );
    } on TimeoutException catch (_) {
      throw const AuthException(
        message: 'Server request timed out. Please try again.',
        isNetworkError: true,
      );
    }

    if (response.statusCode == 401) {
      // 401 received: Attempt silent token refresh
      final refreshResult = await _refreshTokenWithLock();

      if (refreshResult.isSuccess && refreshResult.accessToken != null) {
        // Retry the original request exactly once with new token
        try {
          return await requestFn().timeout(timeout);
        } on SocketException catch (_) {
          throw const AuthException(
            message: 'Unable to connect. Please check your internet connection.',
            isNetworkError: true,
          );
        } on TimeoutException catch (_) {
          throw const AuthException(
            message: 'Server request timed out. Please try again.',
            isNetworkError: true,
          );
        }
      } else if (refreshResult.isExpired) {
        // Refresh explicitly rejected (401/403/422 or empty token): session expired
        await _handleSessionExpired();
        throw const AuthException(
          message: 'Your session has expired. Please log in again.',
          statusCode: 401,
          errorCode: 'SESSION_EXPIRED',
        );
      } else {
        // Refresh failed due to network/server transient error: DO NOT wipe session
        throw AuthException(
          message: refreshResult.errorMessage ?? 'Unable to refresh session. Please try again.',
          isNetworkError: refreshResult.isNetworkError,
          statusCode: refreshResult.statusCode,
        );
      }
    }

    return response;
  }

  /// Thread-safe / concurrent-safe token refresh mutex.
  /// If multiple requests hit 401 simultaneously, only ONE refresh HTTP call is made.
  Future<_RefreshOutcome> _refreshTokenWithLock() async {
    if (_refreshCompleter != null) {
      // Another refresh request is already running; await its result.
      final token = await _refreshCompleter!.future;
      if (token != null && token.isNotEmpty) {
        return _RefreshOutcome.success(token);
      }
      return const _RefreshOutcome.networkError('Concurrent refresh completed without token.');
    }

    _refreshCompleter = Completer<String?>();

    try {
      final currentRefreshToken = await localDataSource.getRefreshToken();
      if (currentRefreshToken == null || currentRefreshToken.isEmpty) {
        _refreshCompleter!.complete(null);
        return const _RefreshOutcome.expired('No refresh token available.');
      }

      final refreshUri = Uri.parse('$baseUrl$apiPrefix/auth/refresh');
      final refreshRes = await _httpClient
          .post(
            refreshUri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'refresh_token': currentRefreshToken}),
          )
          .timeout(const Duration(seconds: 12));

      if (refreshRes.statusCode >= 200 && refreshRes.statusCode < 300) {
        final decoded = jsonDecode(refreshRes.body);
        final data = decoded is Map<String, dynamic>
            ? (decoded['data'] as Map<String, dynamic>? ?? decoded)
            : null;

        if (data != null) {
          final newSession = AuthSession.fromJson(data);
          final isRemembered = await localDataSource.isRemembered();
          await localDataSource.saveSession(newSession, rememberMe: isRemembered);
          _refreshCompleter!.complete(newSession.accessToken);
          return _RefreshOutcome.success(newSession.accessToken);
        }
      }

      // Explicit authentication rejections: token expired or invalid
      if (refreshRes.statusCode == 401 ||
          refreshRes.statusCode == 403 ||
          refreshRes.statusCode == 422 ||
          refreshRes.statusCode == 400) {
        _refreshCompleter!.complete(null);
        return const _RefreshOutcome.expired('Refresh token invalid or expired.');
      }

      // Server 5xx or unexpected status
      _refreshCompleter!.complete(null);
      return _RefreshOutcome.serverError(
        'Server temporarily unavailable during refresh.',
        refreshRes.statusCode,
      );
    } on SocketException catch (_) {
      _refreshCompleter?.complete(null);
      return const _RefreshOutcome.networkError('No internet connection during token refresh.');
    } on TimeoutException catch (_) {
      _refreshCompleter?.complete(null);
      return const _RefreshOutcome.networkError('Token refresh request timed out.');
    } catch (_) {
      _refreshCompleter?.complete(null);
      return const _RefreshOutcome.networkError('Unexpected error during token refresh.');
    } finally {
      _refreshCompleter = null;
    }
  }

  Future<void> _handleSessionExpired() async {
    await localDataSource.clearSession();
    onSessionExpired?.call();
  }
}

class _RefreshOutcome {
  final bool isSuccess;
  final bool isExpired;
  final bool isNetworkError;
  final String? accessToken;
  final String? errorMessage;
  final int? statusCode;

  const _RefreshOutcome._({
    required this.isSuccess,
    required this.isExpired,
    required this.isNetworkError,
    this.accessToken,
    this.errorMessage,
    this.statusCode,
  });

  factory _RefreshOutcome.success(String token) => _RefreshOutcome._(
        isSuccess: true,
        isExpired: false,
        isNetworkError: false,
        accessToken: token,
      );

  const _RefreshOutcome.expired(String reason)
      : this._(
          isSuccess: false,
          isExpired: true,
          isNetworkError: false,
          errorMessage: reason,
          statusCode: 401,
        );

  const _RefreshOutcome.networkError(String message)
      : this._(
          isSuccess: false,
          isExpired: false,
          isNetworkError: true,
          errorMessage: message,
        );

  factory _RefreshOutcome.serverError(String message, int statusCode) =>
      _RefreshOutcome._(
        isSuccess: false,
        isExpired: false,
        isNetworkError: false,
        errorMessage: message,
        statusCode: statusCode,
      );
}
