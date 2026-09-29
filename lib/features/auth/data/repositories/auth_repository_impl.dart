import '../../domain/entities/auth_exception.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';

/// Concrete AuthRepository coordinating local session storage and FastAPI backend.
class AuthRepositoryImpl implements AuthRepository {
  final AuthLocalDataSource localDataSource;
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  @override
  Future<AuthSession> login({
    required String phone,
    required String password,
    bool rememberMe = true,
  }) async {
    // 1. Authenticate with FastAPI
    final session = await remoteDataSource.login(
      phone: phone,
      password: password,
    );

    // 2. Strict Role Verification: Ensure role is authorized for Admin/Manager mobile app
    if (!session.role.isSupported) {
      // Clear any leftover storage
      await localDataSource.clearSession();
      throw AuthException(
        message: 'Access restricted: Only Admin and Manager accounts are authorized to sign in to this application.',
        statusCode: 403,
        errorCode: 'UNSUPPORTED_ROLE',
      );
    }

    // 3. Persist session locally without storing passwords
    if (rememberMe) {
      await localDataSource.saveSession(session, rememberMe: true);
    } else {
      await localDataSource.saveSession(session, rememberMe: false);
    }

    return session;
  }

  @override
  Future<AuthSession?> restoreSession() async {
    final cachedSession = await localDataSource.getSession();
    if (cachedSession == null) return null;

    // Strict Role Verification for cached session
    if (!cachedSession.role.isSupported) {
      await localDataSource.clearSession();
      return null;
    }

    try {
      // Validate session with live FastAPI backend
      final freshUser = await remoteDataSource.getMe(
        accessToken: cachedSession.accessToken,
      );

      if (!freshUser.role.isSupported) {
        await localDataSource.clearSession();
        return null;
      }

      await localDataSource.updateUser(freshUser);
      return cachedSession.copyWith(user: freshUser);
    } on AuthException catch (e) {
      // If unauthorized (401), attempt token refresh
      if (e.statusCode == 401 && cachedSession.refreshToken.isNotEmpty) {
        try {
          final refreshed = await remoteDataSource.refreshToken(
            refreshToken: cachedSession.refreshToken,
          );

          if (!refreshed.role.isSupported) {
            await localDataSource.clearSession();
            return null;
          }

          final isRemembered = await localDataSource.isRemembered();
          await localDataSource.saveSession(refreshed, rememberMe: isRemembered);
          return refreshed;
        } on AuthException catch (refreshErr) {
          // If refresh token is explicitly rejected (401, 403, 422, 400), clear session
          if (refreshErr.statusCode == 401 ||
              refreshErr.statusCode == 403 ||
              refreshErr.statusCode == 422 ||
              refreshErr.statusCode == 400) {
            await localDataSource.clearSession();
            return null;
          }
          // If refresh failed due to network error or server 5xx, do NOT clear session
          return cachedSession;
        } catch (_) {
          return cachedSession;
        }
      }

      // If network is offline or server returned 5xx, maintain local session
      if (e.isNetworkError || (e.statusCode != null && e.statusCode! >= 500)) {
        return cachedSession;
      }

      // Explicit authentication rejections (401 without refresh, 403) clear session
      if (e.statusCode == 401 || e.statusCode == 403) {
        await localDataSource.clearSession();
        return null;
      }

      return cachedSession;
    } catch (_) {
      // Network/socket/timeout failure -> maintain cached session so user is not logged out
      return cachedSession;
    }
  }

  @override
  Future<void> logout() async {
    try {
      final token = await localDataSource.getAccessToken();
      if (token != null && token.isNotEmpty) {
        await remoteDataSource.logout(accessToken: token);
      }
    } catch (_) {
      // Regardless of backend error/offline status, proceed to clear local tokens
    } finally {
      await localDataSource.clearSession();
    }
  }

  @override
  Future<void> requestPasswordResetOtp({required String phone}) async {
    await remoteDataSource.sendForgotPasswordOtp(phone: phone);
  }

  @override
  Future<void> resetPasswordWithOtp({
    required String phone,
    required String code,
    required String newPassword,
  }) async {
    await remoteDataSource.resetPasswordWithOtp(
      phone: phone,
      code: code,
      newPassword: newPassword,
    );
  }

  @override
  Future<AuthUser> getCurrentUser({required String accessToken}) async {
    return await remoteDataSource.getMe(accessToken: accessToken);
  }
}
