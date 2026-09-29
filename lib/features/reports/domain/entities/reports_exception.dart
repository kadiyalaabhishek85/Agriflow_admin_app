/// Typed exception hierarchy for the Reports domain.
class ReportsException implements Exception {
  final String message;
  final int? statusCode;
  final bool isNetworkError;

  const ReportsException({
    required this.message,
    this.statusCode,
    this.isNetworkError = false,
  });

  @override
  String toString() => message;
}

class ReportsUnauthorizedException extends ReportsException {
  const ReportsUnauthorizedException({
    super.message = 'Session expired. Please log in again.',
  }) : super(statusCode: 401);
}

class ReportsForbiddenException extends ReportsException {
  const ReportsForbiddenException({
    super.message = 'You do not have permission to perform this action.',
  }) : super(statusCode: 403);
}

class ReportsValidationException extends ReportsException {
  const ReportsValidationException({required super.message})
      : super(statusCode: 422);
}

class ReportsServerException extends ReportsException {
  const ReportsServerException({
    super.message = 'Backend server error. Please try again later.',
  }) : super(statusCode: 500);
}
