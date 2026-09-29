import 'package:agriflow_admin/core/network/api_exception.dart';

/// Typed exception hierarchy for All Farmers domain.
class FarmerException implements AppApiException {
  @override
  final String message;
  @override
  final int? statusCode;
  @override
  final bool isNetworkError;

  const FarmerException({
    required this.message,
    this.statusCode,
    this.isNetworkError = false,
  });

  @override
  String toString() => message;
}

class FarmerUnauthorizedException extends FarmerException {
  const FarmerUnauthorizedException({super.message = 'Session expired. Please log in again.'})
      : super(statusCode: 401);
}

class FarmerForbiddenException extends FarmerException {
  const FarmerForbiddenException({super.message = 'You do not have permission to perform this action.'})
      : super(statusCode: 403);
}

class FarmerNotFoundException extends FarmerException {
  const FarmerNotFoundException({super.message = 'Farmer not found.'})
      : super(statusCode: 404);
}

class FarmerValidationException extends FarmerException {
  const FarmerValidationException({required super.message})
      : super(statusCode: 422);
}

class FarmerConflictException extends FarmerException {
  const FarmerConflictException({super.message = 'A conflict occurred with this farmer record.'})
      : super(statusCode: 409);
}

class FarmerServerException extends FarmerException {
  const FarmerServerException({super.message = 'Backend server error. Please try again later.'})
      : super(statusCode: 500);
}
