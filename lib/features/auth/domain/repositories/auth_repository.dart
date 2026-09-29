import '../entities/auth_session.dart';
import '../entities/auth_user.dart';

/// Abstract domain contract for authentication and session management.
/// Grounded strictly in the production FastAPI backend contract.
abstract class AuthRepository {
  /// Authenticate using phone and password against FastAPI POST /api/v1/auth/login.
  Future<AuthSession> login({
    required String phone,
    required String password,
    bool rememberMe = true,
  });

  /// Check local storage and validate token against FastAPI GET /api/v1/users/me.
  /// If expired, attempts refresh via POST /api/v1/auth/refresh.
  Future<AuthSession?> restoreSession();

  /// Server-side logout via POST /api/v1/auth/logout and clears local session.
  Future<void> logout();

  /// Send password reset OTP via POST /api/v1/auth/forgot-password/send-otp.
  Future<void> requestPasswordResetOtp({required String phone});

  /// Complete password reset with OTP via POST /api/v1/auth/forgot-password/reset.
  Future<void> resetPasswordWithOtp({
    required String phone,
    required String code,
    required String newPassword,
  });

  /// Fetch latest user profile via GET /api/v1/users/me using active token.
  Future<AuthUser> getCurrentUser({required String accessToken});
}
