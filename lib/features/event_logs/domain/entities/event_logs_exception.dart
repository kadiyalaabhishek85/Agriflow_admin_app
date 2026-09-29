/// Typed exception hierarchy for the Event Logs domain.
class EventLogsException implements Exception {
  final String message;
  final int? statusCode;
  final bool isNetworkError;

  const EventLogsException({
    required this.message,
    this.statusCode,
    this.isNetworkError = false,
  });

  @override
  String toString() => message;
}

class EventLogsUnauthorizedException extends EventLogsException {
  const EventLogsUnauthorizedException({
    super.message = 'Session expired. Please log in again.',
  }) : super(statusCode: 401);
}

class EventLogsForbiddenException extends EventLogsException {
  const EventLogsForbiddenException({
    super.message = 'You do not have permission to perform this action.',
  }) : super(statusCode: 403);
}

class EventLogsServerException extends EventLogsException {
  const EventLogsServerException({
    super.message = 'Backend server error. Please try again later.',
  }) : super(statusCode: 500);
}
