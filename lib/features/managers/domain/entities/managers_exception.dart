/// Typed exception hierarchy for the Managers domain.
class ManagersException implements Exception {
  final String message;
  final int? statusCode;
  final bool isNetworkError;

  const ManagersException({
    required this.message,
    this.statusCode,
    this.isNetworkError = false,
  });

  @override
  String toString() => message;
}

class ManagersUnauthorizedException extends ManagersException {
  const ManagersUnauthorizedException({
    super.message = 'Session expired. Please log in again.',
  }) : super(statusCode: 401);
}

class ManagersForbiddenException extends ManagersException {
  const ManagersForbiddenException({
    super.message = 'You do not have permission to perform this action.',
  }) : super(statusCode: 403);
}

class ManagersNotFoundException extends ManagersException {
  const ManagersNotFoundException({
    super.message = 'Manager not found.',
  }) : super(statusCode: 404);
}

class ManagersValidationException extends ManagersException {
  const ManagersValidationException({required super.message})
      : super(statusCode: 422);
}

class ManagersServerException extends ManagersException {
  const ManagersServerException({
    super.message = 'Backend server error. Please try again later.',
  }) : super(statusCode: 500);
}
