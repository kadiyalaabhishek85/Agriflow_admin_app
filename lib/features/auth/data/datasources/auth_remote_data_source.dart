import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../domain/entities/auth_exception.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/auth_user.dart';

/// Remote authentication data source calling the authoritative FastAPI backend.
abstract class AuthRemoteDataSource {
  Future<AuthSession> login({required String phone, required String password});
  Future<AuthUser> getMe({required String accessToken});
  Future<AuthSession> refreshToken({required String refreshToken});
  Future<void> logout({required String accessToken});
  Future<void> sendForgotPasswordOtp({required String phone});
  Future<void> resetPasswordWithOtp({
    required String phone,
    required String code,
    required String newPassword,
  });
}

class FastApiAuthRemoteDataSource implements AuthRemoteDataSource {
  static const String defaultBaseUrl = 'https://agriflow-backend-t8o4.onrender.com';
  static const String apiPrefix = '/api/v1';

  final String baseUrl;
  final http.Client client;

  FastApiAuthRemoteDataSource({
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

  @override
  Future<AuthSession> login({
    required String phone,
    required String password,
  }) async {
    try {
      final response = await client
          .post(
            _uri('/auth/login'),
            headers: _headers(),
            body: jsonEncode({
              'phone': phone.trim(),
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final json = _parseResponse(response);
      final data = json['data'] as Map<String, dynamic>? ?? json;
      return AuthSession.fromJson(data);
    } on SocketException catch (_) {
      throw const AuthException(
        message: 'Network connection unavailable. Please check your internet connection.',
        isNetworkError: true,
      );
    } on TimeoutException catch (_) {
      throw const AuthException(
        message: 'Server request timed out. Please try again later.',
        isNetworkError: true,
      );
    }
  }

  @override
  Future<AuthUser> getMe({required String accessToken}) async {
    try {
      final response = await client
          .get(
            _uri('/users/me'),
            headers: _headers(token: accessToken),
          )
          .timeout(const Duration(seconds: 12));

      final json = _parseResponse(response);
      final data = json['data'] as Map<String, dynamic>? ?? json;
      return AuthUser.fromJson(data);
    } on SocketException catch (_) {
      throw const AuthException(
        message: 'Network connection unavailable.',
        isNetworkError: true,
      );
    } on TimeoutException catch (_) {
      throw const AuthException(
        message: 'Session validation timed out.',
        isNetworkError: true,
      );
    }
  }

  @override
  Future<AuthSession> refreshToken({required String refreshToken}) async {
    try {
      final response = await client
          .post(
            _uri('/auth/refresh'),
            headers: _headers(),
            body: jsonEncode({'refresh_token': refreshToken}),
          )
          .timeout(const Duration(seconds: 12));

      final json = _parseResponse(response);
      final data = json['data'] as Map<String, dynamic>? ?? json;
      return AuthSession.fromJson(data);
    } on SocketException catch (_) {
      throw const AuthException(
        message: 'Network connection unavailable during token refresh.',
        isNetworkError: true,
      );
    }
  }

  @override
  Future<void> logout({required String accessToken}) async {
    try {
      final response = await client
          .post(
            _uri('/auth/logout'),
            headers: _headers(token: accessToken),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200 && response.statusCode != 401) {
        _parseResponse(response);
      }
    } catch (_) {
      // Server-side logout failed or timed out — local session will still be cleared.
    }
  }

  @override
  Future<void> sendForgotPasswordOtp({required String phone}) async {
    try {
      final response = await client
          .post(
            _uri('/auth/forgot-password/send-otp'),
            headers: _headers(),
            body: jsonEncode({'phone': phone.trim()}),
          )
          .timeout(const Duration(seconds: 12));

      _parseResponse(response);
    } on SocketException catch (_) {
      throw const AuthException(
        message: 'Network connection unavailable.',
        isNetworkError: true,
      );
    }
  }

  @override
  Future<void> resetPasswordWithOtp({
    required String phone,
    required String code,
    required String newPassword,
  }) async {
    try {
      final response = await client
          .post(
            _uri('/auth/forgot-password/reset'),
            headers: _headers(),
            body: jsonEncode({
              'phone': phone.trim(),
              'code': code.trim(),
              'new_password': newPassword,
            }),
          )
          .timeout(const Duration(seconds: 12));

      _parseResponse(response);
    } on SocketException catch (_) {
      throw const AuthException(
        message: 'Network connection unavailable.',
        isNetworkError: true,
      );
    }
  }

  Map<String, dynamic> _parseResponse(http.Response response) {
    Map<String, dynamic> json;
    try {
      json = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true};
      }
      throw AuthException(
        message: 'Server returned unexpected response (${response.statusCode})',
        statusCode: response.statusCode,
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json;
    }

    // Parse FastAPI error response
    String errorMessage = 'Authentication failed. Please try again.';
    String? errorCode;

    if (json.containsKey('error') && json['error'] is Map) {
      final errorMap = json['error'] as Map<String, dynamic>;
      errorMessage = errorMap['message'] as String? ?? errorMessage;
      errorCode = errorMap['code'] as String?;

      if (errorMap['details'] is Map &&
          errorMap['details']['errors'] is List &&
          (errorMap['details']['errors'] as List).isNotEmpty) {
        final firstErr = (errorMap['details']['errors'] as List).first;
        if (firstErr is Map && firstErr.containsKey('msg')) {
          errorMessage = firstErr['msg'].toString().replaceFirst('Value error, ', '');
        }
      }
    } else if (json.containsKey('detail')) {
      final detail = json['detail'];
      if (detail is String) {
        errorMessage = detail;
      } else if (detail is List && detail.isNotEmpty) {
        final first = detail.first;
        if (first is Map && first.containsKey('msg')) {
          errorMessage = first['msg'].toString().replaceFirst('Value error, ', '');
        }
      }
    }

    throw AuthException(
      message: errorMessage,
      statusCode: response.statusCode,
      errorCode: errorCode,
    );
  }
}
