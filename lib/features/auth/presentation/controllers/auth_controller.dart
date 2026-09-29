import 'package:flutter/foundation.dart';
import '../../../../core/models/user_role.dart';
import '../../domain/entities/auth_exception.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

/// Presentation controller managing authentication lifecycle and UI states.
class AuthController extends ChangeNotifier {
  final AuthRepository repository;
  AuthRepository get _repository => repository;

  AuthState _state = AuthState.initial();
  AuthState get state => _state;

  AuthSession? get currentSession => _state.session;

  /// Resolves the role strictly from active session without silently defaulting unknown to Manager.
  UserRole? get currentRole {
    final role = _state.session?.role;
    if (role == null || !role.isSupported) return null;
    return role;
  }

  AuthController({required this.repository});



  void _setState(AuthState newState) {
    if (_state == newState) return;
    _state = newState;
    notifyListeners();
  }

  /// Initial session check on app launch (used by Splash Screen)
  Future<void> restoreSession() async {
    _setState(AuthState.sessionRestoring());
    try {
      final session = await _repository.restoreSession();
      if (session != null) {
        if (!session.role.isSupported) {
          _setState(AuthState.unsupportedRole(session.user.role.name));
        } else {
          _setState(AuthState.authenticated(session));
        }
      } else {
        _setState(AuthState.unauthenticated());
      }
    } catch (e) {
      _setState(AuthState.unauthenticated());
    }
  }

  /// Authenticate with 10-digit phone and password against FastAPI
  Future<bool> login({
    required String phone,
    required String password,
    bool rememberMe = true,
  }) async {
    _setState(AuthState.authenticating());
    try {
      final session = await _repository.login(
        phone: phone,
        password: password,
        rememberMe: rememberMe,
      );

      if (!session.role.isSupported) {
        _setState(AuthState.unsupportedRole(session.user.role.name));
        return false;
      }

      _setState(AuthState.authenticated(session));
      return true;
    } on AuthException catch (e) {
      if (e.errorCode == 'UNSUPPORTED_ROLE') {
        _setState(AuthState.unsupportedRole('Unauthorized'));
      } else {
        _setState(AuthState.authenticationFailure(e.message));
      }
      return false;
    } catch (e) {
      _setState(
        AuthState.authenticationFailure(
          'An unexpected error occurred during login. Please try again.',
        ),
      );
      return false;
    }
  }

  /// Clear authentication state and local session, transition to unauthenticated
  Future<void> logout() async {
    _setState(AuthState.loggingOut());
    try {
      await _repository.logout();
    } finally {
      _setState(AuthState.unauthenticated());
    }
  }

  /// Handle session expired event (e.g. from ApiClient 401 refresh failure)
  void handleSessionExpired() {
    _setState(AuthState.sessionExpired());
  }

  /// Trigger password reset OTP
  Future<void> requestPasswordResetOtp({required String phone}) async {
    await _repository.requestPasswordResetOtp(phone: phone);
  }

  /// Complete password reset with OTP
  Future<void> resetPasswordWithOtp({
    required String phone,
    required String code,
    required String newPassword,
  }) async {
    await _repository.resetPasswordWithOtp(
      phone: phone,
      code: code,
      newPassword: newPassword,
    );
  }

  /// Clear any error message without changing status
  void clearError() {
    if (_state.status == AuthStatus.authenticationFailure) {
      _setState(AuthState.unauthenticated());
    }
  }

  /// Apply a fresh [user] profile (returned by PATCH /api/v1/users/me) to the
  /// active session so every surface (shells, drawer header, account screen)
  /// rebuilds with the updated name/email.
  void applyUser(AuthUser user) {
    final session = _state.session;
    if (session == null) return;
    _setState(AuthState.authenticated(session.copyWith(user: user)));
  }
}
