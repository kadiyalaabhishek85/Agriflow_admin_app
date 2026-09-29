/// Typed exception hierarchy for Seeds Inventory domain.
class SeedsInventoryException implements Exception {
  final String message;
  final int? statusCode;
  final bool isNetworkError;

  const SeedsInventoryException({
    required this.message,
    this.statusCode,
    this.isNetworkError = false,
  });

  @override
  String toString() => message;
}

class SeedsInventoryUnauthorizedException extends SeedsInventoryException {
  const SeedsInventoryUnauthorizedException({
    super.message = 'Session expired. Please log in again.',
  }) : super(statusCode: 401);
}

class SeedsInventoryForbiddenException extends SeedsInventoryException {
  const SeedsInventoryForbiddenException({
    super.message = 'You do not have administrative permission to modify seed inventory.',
  }) : super(statusCode: 403);
}

class SeedsInventoryNotFoundException extends SeedsInventoryException {
  const SeedsInventoryNotFoundException({
    super.message = 'Seed product not found in catalog.',
  }) : super(statusCode: 404);
}

class SeedsInventoryValidationException extends SeedsInventoryException {
  const SeedsInventoryValidationException({
    required super.message,
  }) : super(statusCode: 422);
}

class SeedsInventoryServerException extends SeedsInventoryException {
  const SeedsInventoryServerException({
    super.message = 'Backend server error. Please try again later.',
  }) : super(statusCode: 500);
}

class SeedsInventoryNetworkException extends SeedsInventoryException {
  const SeedsInventoryNetworkException({
    super.message = 'Network connection unavailable. Please check your internet connection.',
  }) : super(isNetworkError: true);
}
