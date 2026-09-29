import '../../domain/entities/auth_session.dart';

/// Explicit status values for the authentication state machine.
enum AuthStatus {
  initial,
  sessionRestoring,
  unauthenticated,
  authenticating,
  authenticated,
  authenticationFailure,
  sessionExpired,
  loggingOut,
  unsupportedRole,
}

/// Immutable authentication state model.
class AuthState {
  final AuthStatus status;
  final AuthSession? session;
  final String? errorMessage;
  final String? unsupportedRoleName;

  const AuthState({
    required this.status,
    this.session,
    this.errorMessage,
    this.unsupportedRoleName,
  });

  factory AuthState.initial() => const AuthState(status: AuthStatus.initial);

  factory AuthState.sessionRestoring() =>
      const AuthState(status: AuthStatus.sessionRestoring);

  factory AuthState.unauthenticated([String? message]) => AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: message,
      );

  factory AuthState.authenticating() =>
      const AuthState(status: AuthStatus.authenticating);

  factory AuthState.authenticated(AuthSession session) => AuthState(
        status: AuthStatus.authenticated,
        session: session,
      );

  factory AuthState.authenticationFailure(String message) => AuthState(
        status: AuthStatus.authenticationFailure,
        errorMessage: message,
      );

  factory AuthState.sessionExpired() => const AuthState(
        status: AuthStatus.sessionExpired,
        errorMessage: 'Session expired. Please log in again.',
      );

  factory AuthState.loggingOut() =>
      const AuthState(status: AuthStatus.loggingOut);

  factory AuthState.unsupportedRole(String roleName) => AuthState(
        status: AuthStatus.unsupportedRole,
        unsupportedRoleName: roleName,
        errorMessage:
            'The role "$roleName" is not authorized to access the Admin/Manager mobile console.',
      );

  bool get isInitializing => status == AuthStatus.initial;
  bool get isSessionRestoring => status == AuthStatus.sessionRestoring;
  bool get isAuthenticating => status == AuthStatus.authenticating;
  bool get isAuthenticated => status == AuthStatus.authenticated && session != null;
  bool get isUnauthenticated =>
      status == AuthStatus.unauthenticated ||
      status == AuthStatus.authenticationFailure ||
      status == AuthStatus.sessionExpired;
  bool get isUnsupportedRole => status == AuthStatus.unsupportedRole;
  bool get isLoggingOut => status == AuthStatus.loggingOut;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthState &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          session == other.session &&
          errorMessage == other.errorMessage &&
          unsupportedRoleName == other.unsupportedRoleName;

  @override
  int get hashCode =>
      status.hashCode ^
      session.hashCode ^
      errorMessage.hashCode ^
      unsupportedRoleName.hashCode;
}
