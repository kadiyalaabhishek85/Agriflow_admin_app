import 'package:agriflow_admin/core/network/api_exception.dart';

class BookingException implements AppApiException {
  @override
  final String message;
  @override
  final int statusCode;
  @override
  final bool isNetworkError;

  const BookingException(
    this.message, {
    this.statusCode = 0,
    this.isNetworkError = false,
  });

  @override
  String toString() => message;
}

class BookingConflictException extends BookingException {
  const BookingConflictException([
    super.message =
        'This booking changed on the server. Please refresh and try again.',
  ]) : super(statusCode: 409);
}
