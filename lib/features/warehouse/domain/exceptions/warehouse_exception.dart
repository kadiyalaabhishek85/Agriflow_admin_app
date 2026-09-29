/// Typed exception hierarchy for the Warehouse Management domain.
class WarehouseException implements Exception {
  final String message;
  final int? statusCode;
  final bool isNetworkError;

  const WarehouseException({
    required this.message,
    this.statusCode,
    this.isNetworkError = false,
  });

  @override
  String toString() => message;
}

class WarehouseUnauthorizedException extends WarehouseException {
  const WarehouseUnauthorizedException({
    super.message = 'Session expired. Please log in again.',
  }) : super(statusCode: 401);
}

class WarehouseForbiddenException extends WarehouseException {
  const WarehouseForbiddenException({
    super.message = 'You do not have administrative permission to perform this warehouse action.',
  }) : super(statusCode: 403);
}

class WarehouseNotFoundException extends WarehouseException {
  const WarehouseNotFoundException({
    super.message = 'Warehouse or requested resource not found.',
  }) : super(statusCode: 404);
}

class WarehouseConflictException extends WarehouseException {
  const WarehouseConflictException({
    super.message = 'Operation conflicts with existing warehouse or booking state.',
  }) : super(statusCode: 409);
}

class WarehouseValidationException extends WarehouseException {
  const WarehouseValidationException({
    required super.message,
  }) : super(statusCode: 422);
}

class WarehouseServerException extends WarehouseException {
  const WarehouseServerException({
    super.message = 'Backend server error. Please try again later.',
  }) : super(statusCode: 500);
}

class WarehouseNetworkException extends WarehouseException {
  const WarehouseNetworkException({
    super.message = 'Network connection unavailable. Please check your internet connection.',
  }) : super(isNetworkError: true);
}
