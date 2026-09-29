import 'package:flutter_test/flutter_test.dart';
import 'package:agriflow_admin/core/models/user_role.dart';
import 'package:agriflow_admin/features/auth/domain/entities/auth_exception.dart';
import 'package:agriflow_admin/features/auth/domain/entities/auth_session.dart';
import 'package:agriflow_admin/features/auth/domain/entities/auth_user.dart';
import 'package:agriflow_admin/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:agriflow_admin/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:agriflow_admin/features/auth/data/repositories/auth_repository_impl.dart';

class MockLocalDataSource implements AuthLocalDataSource {
  String? accessToken = 'valid_token';
  String? refreshToken = 'valid_refresh';
  AuthSession? session = const AuthSession(
    accessToken: 'valid_token',
    refreshToken: 'valid_refresh',
    tokenType: 'bearer',
    user: AuthUser(
      id: '1',
      name: 'User',
      phone: '9876543210',
      role: UserRole.admin,
      status: 'active',
    ),
  );
  int clearCallCount = 0;

  @override
  Future<void> clearSession() async {
    clearCallCount++;
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
  Future<bool> isRemembered() async => true;

  @override
  Future<void> saveSession(AuthSession s, {bool rememberMe = true}) async {
    session = s;
  }

  @override
  Future<void> updateTokens({required String accessToken, required String refreshToken}) async {}

  @override
  Future<void> updateUser(AuthUser user) async {}
}

class FakeRemoteDataSource implements AuthRemoteDataSource {
  final Future<void> Function(String token)? onLogout;

  FakeRemoteDataSource({this.onLogout});

  @override
  Future<void> logout({required String accessToken}) async {
    if (onLogout != null) {
      await onLogout!(accessToken);
    }
  }

  @override
  Future<AuthSession> login({required String phone, required String password}) =>
      throw UnimplementedError();

  @override
  Future<AuthUser> getMe({required String accessToken}) => throw UnimplementedError();

  @override
  Future<AuthSession> refreshToken({required String refreshToken}) =>
      throw UnimplementedError();

  @override
  Future<void> sendForgotPasswordOtp({required String phone}) =>
      throw UnimplementedError();

  @override
  Future<void> resetPasswordWithOtp({
    required String phone,
    required String code,
    required String newPassword,
  }) =>
      throw UnimplementedError();
}

void main() {
  group('Logout Token Purge Tests (ISSUE-P2-05)', () {
    test('Backend logout success clears local session and tokens', () async {
      final local = MockLocalDataSource();
      final remote = FakeRemoteDataSource(onLogout: (token) async {});
      final repo = AuthRepositoryImpl(remoteDataSource: remote, localDataSource: local);

      await repo.logout();

      expect(local.clearCallCount, 1);
      expect(local.accessToken, isNull);
      expect(local.refreshToken, isNull);
      expect(local.session, isNull);
    });

    test('Backend logout failure (500) STILL clears local tokens in finally block', () async {
      final local = MockLocalDataSource();
      final remote = FakeRemoteDataSource(
        onLogout: (token) async {
          throw const AuthException(message: 'Server error 500', statusCode: 500);
        },
      );
      final repo = AuthRepositoryImpl(remoteDataSource: remote, localDataSource: local);

      await repo.logout();

      // Tokens MUST be cleared even when server threw an error
      expect(local.clearCallCount, 1);
      expect(local.accessToken, isNull);
      expect(local.refreshToken, isNull);
      expect(local.session, isNull);
    });

    test('Offline network error (SocketException) STILL clears local tokens in finally block', () async {
      final local = MockLocalDataSource();
      final remote = FakeRemoteDataSource(
        onLogout: (token) async {
          throw const AuthException(
            message: 'Unable to connect to server',
            isNetworkError: true,
          );
        },
      );
      final repo = AuthRepositoryImpl(remoteDataSource: remote, localDataSource: local);

      await repo.logout();

      // Tokens MUST be cleared even when offline
      expect(local.clearCallCount, 1);
      expect(local.accessToken, isNull);
      expect(local.refreshToken, isNull);
      expect(local.session, isNull);
    });
  });
}
