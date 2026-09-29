/// Typed exception hierarchy for Billing & Invoices domain.
class BillingException implements Exception {
  final String message;
  final int? statusCode;
  final bool isNetworkError;

  const BillingException({
    required this.message,
    this.statusCode,
    this.isNetworkError = false,
  });

  @override
  String toString() => message;
}

class BillingUnauthorizedException extends BillingException {
  const BillingUnauthorizedException({super.message = 'Session expired. Please log in again.'})
      : super(statusCode: 401);
}

class BillingForbiddenException extends BillingException {
  const BillingForbiddenException({super.message = 'You do not have permission to perform this action.'})
      : super(statusCode: 403);
}

class BillingNotFoundException extends BillingException {
  const BillingNotFoundException({super.message = 'Transaction or invoice not found.'})
      : super(statusCode: 404);
}

class BillingValidationException extends BillingException {
  const BillingValidationException({required super.message})
      : super(statusCode: 422);
}

class BillingConflictException extends BillingException {
  const BillingConflictException({super.message = 'This transaction has already been processed or settled.'})
      : super(statusCode: 409);
}

class BillingServerException extends BillingException {
  const BillingServerException({super.message = 'Backend server error. Please try again later.'})
      : super(statusCode: 500);
}
