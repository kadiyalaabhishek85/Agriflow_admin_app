import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:agriflow_admin/core/network/api_client.dart';
import 'package:agriflow_admin/features/auth/domain/entities/auth_exception.dart';
import 'package:agriflow_admin/features/auth/domain/entities/auth_session.dart';
import 'package:agriflow_admin/features/auth/domain/entities/auth_user.dart';
import 'package:agriflow_admin/features/auth/data/datasources/auth_local_data_source.dart';

class MockAuthLocalDataSource implements AuthLocalDataSource {
  String? accessToken;
  String? refreshToken;
  AuthSession? session;
  bool remembered = true;
  int clearSessionCallCount = 0;
  int saveSessionCallCount = 0;

  MockAuthLocalDataSource({
    this.accessToken = 'old_access_token',
    this.refreshToken = 'valid_refresh_token',
  });

  @override
  Future<void> clearSession() async {
    clearSessionCallCount++;
    accessToken = null;
    refreshToken = null;
    session = null;
  }

  @override
  Future<String?> getAccessToken() async => accessToken;

  @override
  Future<String?> getRefreshToken() async => refreshToken;

  @override
  Future<AuthSession?> getSession() async => session;

  @override
  Future<bool> isRemembered() async => remembered;

  @override
  Future<void> saveSession(AuthSession newSession, {bool rememberMe = true}) async {
    saveSessionCallCount++;
    session = newSession;
    accessToken = newSession.accessToken;
    refreshToken = newSession.refreshToken;
    remembered = rememberMe;
  }

  @override
  Future<void> updateTokens({required String accessToken, required String refreshToken}) async {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
  }

  @override
  Future<void> updateUser(AuthUser user) async {}
}

class FakeHttpClient extends http.BaseClient {
  final Future<http.Response> Function(http.BaseRequest request) handler;

  FakeHttpClient(this.handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await handler(request);
    return http.StreamedResponse(
      Stream.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
      request: request,
    );
  }
}

void main() {
  group('ApiClient Token Expiry & 401 Handling Tests (ISSUE-P0-01)', () {
    test('401 -> refresh -> retry succeeds and updates tokens', () async {
      final localDataSource = MockAuthLocalDataSource(
        accessToken: 'initial_token',
        refreshToken: 'valid_refresh',
      );

      int resourceCallCount = 0;
      int refreshCallCount = 0;

      final fakeClient = FakeHttpClient((request) async {
        final path = request.url.path;

        if (path.contains('/auth/refresh')) {
          refreshCallCount++;
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'access_token': 'new_refreshed_access_token',
                'refresh_token': 'new_refresh_token',
                'token_type': 'bearer',
                'user': {
                  'id': 'user-1',
                  'name': 'Test Admin',
                  'phone': '9876543210',
                  'role': 'super_admin',
                  'status': 'active',
                }
              }
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (path.contains('/protected-resource')) {
          resourceCallCount++;
          final authHeader = request.headers['Authorization'] ?? request.headers['authorization'];
          if (authHeader == 'Bearer initial_token') {
            return http.Response('{"detail":"Unauthorized"}', 401);
          } else if (authHeader == 'Bearer new_refreshed_access_token') {
            return http.Response('{"data":"resource_data"}', 200);
          }
          return http.Response('{"detail":"Unauthorized"}', 401);
        }

        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(
        baseUrl: 'https://test.agriflow.com',
        httpClient: fakeClient,
        localDataSource: localDataSource,
      );

      final response = await apiClient.get('/protected-resource');

      expect(response.statusCode, 200);
      expect(response.body, contains('resource_data'));
      expect(resourceCallCount, 2); // Initial 401 + 1 retry
      expect(refreshCallCount, 1);
      expect(localDataSource.accessToken, 'new_refreshed_access_token');
      expect(localDataSource.saveSessionCallCount, 1);
    });

    test('401 -> refresh fails -> clears session, calls onSessionExpired, and throws AuthException', () async {
      final localDataSource = MockAuthLocalDataSource(
        accessToken: 'expired_token',
        refreshToken: 'invalid_refresh',
      );

      bool sessionExpiredCalled = false;

      final fakeClient = FakeHttpClient((request) async {
        if (request.url.path.contains('/auth/refresh')) {
          return http.Response('{"detail":"Refresh token expired"}', 401);
        }
        return http.Response('{"detail":"Unauthorized"}', 401);
      });

      final apiClient = ApiClient(
        baseUrl: 'https://test.agriflow.com',
        httpClient: fakeClient,
        localDataSource: localDataSource,
        onSessionExpired: () {
          sessionExpiredCalled = true;
        },
      );

      await expectLater(
        () => apiClient.get('/protected-resource'),
        throwsA(isA<AuthException>().having((e) => e.statusCode, 'statusCode', 401)),
      );

      // Local session must be purged
      expect(localDataSource.clearSessionCallCount, 1);
      expect(localDataSource.accessToken, isNull);
      expect(sessionExpiredCalled, isTrue);
    });

    test('Retries original request exactly ONCE (does not enter infinite refresh loop)', () async {
      final localDataSource = MockAuthLocalDataSource(
        accessToken: 'token_1',
        refreshToken: 'valid_refresh',
      );

      int resourceCallCount = 0;
      int refreshCallCount = 0;

      final fakeClient = FakeHttpClient((request) async {
        if (request.url.path.contains('/auth/refresh')) {
          refreshCallCount++;
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'access_token': 'refreshed_token_2',
                'refresh_token': 'new_refresh',
                'token_type': 'bearer',
                'user': {
                  'id': 'u1',
                  'name': 'Admin',
                  'phone': '9876543210',
                  'role': 'super_admin',
                  'status': 'active',
                }
              }
            }),
            200,
          );
        }

        // Protected endpoint always returns 401, even after refresh
        resourceCallCount++;
        return http.Response('{"detail":"Still unauthorized"}', 401);
      });

      final apiClient = ApiClient(
        baseUrl: 'https://test.agriflow.com',
        httpClient: fakeClient,
        localDataSource: localDataSource,
      );

      final response = await apiClient.get('/protected-resource');

      // Returns the second 401 response without an infinite loop
      expect(response.statusCode, 401);
      expect(resourceCallCount, 2); // exactly original + 1 retry
      expect(refreshCallCount, 1);
    });

    test('Concurrent 401 requests execute only ONE refresh HTTP call (no refresh storm)', () async {
      final localDataSource = MockAuthLocalDataSource(
        accessToken: 'stale_token',
        refreshToken: 'valid_refresh',
      );

      int refreshCallCount = 0;

      final fakeClient = FakeHttpClient((request) async {
        if (request.url.path.contains('/auth/refresh')) {
          refreshCallCount++;
          // Simulate slight network delay
          await Future.delayed(const Duration(milliseconds: 50));
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'access_token': 'new_token_mutex',
                'refresh_token': 'new_refresh_mutex',
                'token_type': 'bearer',
                'user': {
                  'id': 'u1',
                  'name': 'Admin',
                  'phone': '9876543210',
                  'role': 'super_admin',
                  'status': 'active',
                }
              }
            }),
            200,
          );
        }

        final authHeader = request.headers['Authorization'] ?? request.headers['authorization'];
        if (authHeader == 'Bearer new_token_mutex') {
          return http.Response('{"data":"ok"}', 200);
        }
        return http.Response('{"detail":"Unauthorized"}', 401);
      });

      final apiClient = ApiClient(
        baseUrl: 'https://test.agriflow.com',
        httpClient: fakeClient,
        localDataSource: localDataSource,
      );

      // Fire 5 concurrent requests simultaneously
      final futures = [
        apiClient.get('/res-1'),
        apiClient.get('/res-2'),
        apiClient.get('/res-3'),
        apiClient.get('/res-4'),
        apiClient.get('/res-5'),
      ];

      final responses = await Future.wait(futures);

      for (final res in responses) {
        expect(res.statusCode, 200);
      }

      // Exactly ONE refresh request was made despite 5 concurrent 401s
      expect(refreshCallCount, 1);
      expect(localDataSource.accessToken, 'new_token_mutex');
    });

    test('defaultBaseUrl uses deployed Render HTTPS host without /api/v1 suffix', () {
      expect(ApiClient.defaultBaseUrl, 'https://agriflow-backend-760e.onrender.com');
      expect(ApiClient.defaultBaseUrl, isNot(contains('/api/v1')));
    });

    test('GET safely retries once after transient network error and succeeds', () async {
      final localDataSource = MockAuthLocalDataSource(accessToken: 'valid_token');
      var calls = 0;

      final fakeClient = FakeHttpClient((request) async {
        calls++;
        if (calls == 1) {
          throw const SocketException('Temporary drop');
        }
        return http.Response('{"data":"ok"}', 200);
      });

      final apiClient = ApiClient(
        baseUrl: 'https://test.agriflow.com',
        httpClient: fakeClient,
        localDataSource: localDataSource,
      );

      final res = await apiClient.get('/admin/dashboard');
      expect(res.statusCode, 200);
      expect(calls, 2);
    });

    test('POST does NOT retry automatically after TimeoutException', () async {
      final localDataSource = MockAuthLocalDataSource(accessToken: 'valid_token');
      var calls = 0;

      final fakeClient = FakeHttpClient((request) async {
        calls++;
        throw TimeoutException('Slow backend');
      });

      final apiClient = ApiClient(
        baseUrl: 'https://test.agriflow.com',
        httpClient: fakeClient,
        localDataSource: localDataSource,
      );

      await expectLater(
        () => apiClient.post('/transactions/tx-1/pay', body: '{}'),
        throwsA(
          isA<AuthException>()
              .having((e) => e.isNetworkError, 'isNetworkError', isTrue)
              .having((e) => e.message, 'message', contains('taking too long')),
        ),
      );
      expect(calls, 1, reason: 'Writes/payments must never be auto-resubmitted on timeout');
    });
  });
}
