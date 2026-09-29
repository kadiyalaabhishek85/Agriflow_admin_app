/// Structured exception for authentication operations.
class AuthException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorCode;
  final bool isNetworkError;

  const AuthException({
    required this.message,
    this.statusCode,
    this.errorCode,
    this.isNetworkError = false,
  });

  bool get isInvalidCredentials =>
      statusCode == 401 || errorCode == 'UNAUTHORIZED';

  bool get isValidationError =>
      statusCode == 422 || errorCode == 'VALIDATION_ERROR';

  @override
  String toString() => message;
}
