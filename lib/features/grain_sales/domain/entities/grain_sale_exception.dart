import 'package:agriflow_admin/core/network/api_exception.dart';

/// Typed exception hierarchy for Grain Sales domain.
class GrainSaleException implements AppApiException {
  @override
  final String message;
  @override
  final int? statusCode;
  @override
  final bool isNetworkError;

  const GrainSaleException({
    required this.message,
    this.statusCode,
    this.isNetworkError = false,
  });

  @override
  String toString() => message;
}

class GrainSaleUnauthorizedException extends GrainSaleException {
  const GrainSaleUnauthorizedException({super.message = 'Session expired. Please log in again.'})
      : super(statusCode: 401);
}

class GrainSaleForbiddenException extends GrainSaleException {
  const GrainSaleForbiddenException({super.message = 'You do not have permission to perform this action.'})
      : super(statusCode: 403);
}

class GrainSaleNotFoundException extends GrainSaleException {
  const GrainSaleNotFoundException({super.message = 'Grain sale not found.'})
      : super(statusCode: 404);
}

class GrainSaleValidationException extends GrainSaleException {
  const GrainSaleValidationException({required super.message})
      : super(statusCode: 422);
}

class GrainSaleConflictException extends GrainSaleException {
  const GrainSaleConflictException({super.message = 'This grain sale has already been settled.'})
      : super(statusCode: 409);
}

class GrainSaleServerException extends GrainSaleException {
  const GrainSaleServerException({super.message = 'Backend server error. Please try again later.'})
      : super(statusCode: 500);
}
