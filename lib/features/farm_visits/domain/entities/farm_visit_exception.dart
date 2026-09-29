import 'package:agriflow_admin/core/network/api_exception.dart';

/// Domain exceptions for Farm Visits
abstract class FarmVisitException implements AppApiException {
  @override
  final String message;
  @override
  final int? statusCode;

  const FarmVisitException(this.message, [this.statusCode]);

  @override
  bool get isNetworkError => statusCode == 0;

  @override
  String toString() => message;
}

class FarmVisitNetworkException extends FarmVisitException {
  const FarmVisitNetworkException([
    String message = 'Network connection failed. Please check your internet connection.',
  ]) : super(message, 0);
}

class FarmVisitAuthException extends FarmVisitException {
  const FarmVisitAuthException([
    String message = 'Session expired. Please log in again.',
  ]) : super(message, 401);
}

class FarmVisitPermissionException extends FarmVisitException {
  const FarmVisitPermissionException([
    String message = 'You do not have permission to perform this action.',
  ]) : super(message, 403);
}

class FarmVisitNotFoundException extends FarmVisitException {
  const FarmVisitNotFoundException([
    String message = 'The requested farm visit could not be found.',
  ]) : super(message, 404);
}

class FarmVisitConflictException extends FarmVisitException {
  const FarmVisitConflictException([
    String message =
        'This farm visit changed on the server. Please refresh and try again.',
  ]) : super(message, 409);
}

class FarmVisitValidationException extends FarmVisitException {
  const FarmVisitValidationException(
    super.message, [
    super.statusCode = 422,
  ]);
}

class FarmVisitServerException extends FarmVisitException {
  const FarmVisitServerException([
    super.message = 'An unexpected server error occurred.',
    super.statusCode = 500,
  ]);
}
