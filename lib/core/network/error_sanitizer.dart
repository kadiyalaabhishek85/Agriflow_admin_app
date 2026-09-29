/// Centralized user-facing error message sanitization.
///
/// Maps raw exceptions (SocketException, 401, 403, 404, 409, 422, 500, etc.)
/// into clean, professional user messages.
/// NEVER exposes raw technical details or stack traces to end users.
class ErrorSanitizer {
  static const String networkErrorMessage =
      'Unable to connect. Please check your internet connection.';

  static const String sessionExpiredMessage =
      'Your session has expired. Please log in again.';

  static const String permissionDeniedMessage =
      "You don't have permission to perform this action.";

  static const String notFoundMessage =
      'The requested information could not be found.';

  static const String conflictMessage =
      'This action conflicts with the current data.';

  static const String validationMessage =
      'Some information is invalid. Please check and try again.';

  static const String serverErrorMessage =
      'Something went wrong on the server. Please try again.';

  static const String genericErrorMessage =
      'Something went wrong. Please try again.';

  /// Sanitizes any caught exception [error] into a safe, user-friendly message.
  static String sanitize(dynamic error, {String? defaultAction}) {
    if (error == null) return genericErrorMessage;

    final errStr = error.toString().toLowerCase();

    // Network / Socket failures
    if (errStr.contains('socketexception') ||
        errStr.contains('connection refused') ||
        errStr.contains('network') ||
        errStr.contains('failed host lookup') ||
        errStr.contains('handshake') ||
        errStr.contains('clientexception') ||
        errStr.contains('timeout')) {
      return networkErrorMessage;
    }

    // Check status codes if present as property on domain exceptions
    try {
      final code = (error as dynamic).statusCode;
      if (code == 401) return sessionExpiredMessage;
      if (code == 403) return permissionDeniedMessage;
      if (code == 404) return notFoundMessage;
      if (code == 409) return conflictMessage;
      if (code == 422) return validationMessage;
      if (code is int && code >= 500 && code <= 599) return serverErrorMessage;
    } catch (_) {}

    // Check status codes if present in string representation
    if (errStr.contains('401') || errStr.contains('unauthorized') || errStr.contains('session_expired')) {
      return sessionExpiredMessage;
    }

    if (errStr.contains('403') ||
        errStr.contains('forbidden') ||
        errStr.contains('permission') ||
        errStr.contains('access restricted')) {
      return permissionDeniedMessage;
    }

    if (errStr.contains('404') || errStr.contains('not found')) {
      return notFoundMessage;
    }

    if (errStr.contains('409') || errStr.contains('conflict')) {
      return conflictMessage;
    }

    if (errStr.contains('422') || errStr.contains('validation') || errStr.contains('unprocessable')) {
      return validationMessage;
    }

    if (errStr.contains('500') ||
        errStr.contains('502') ||
        errStr.contains('503') ||
        errStr.contains('504') ||
        errStr.contains('server error') ||
        errStr.contains('internal server')) {
      return serverErrorMessage;
    }

    // If it's a domain exception with a user-friendly message, extract message safely
    try {
      final message = (error as dynamic).message;
      if (message is String &&
          message.isNotEmpty &&
          !message.toLowerCase().contains('exception') &&
          !message.toLowerCase().contains('http') &&
          !message.toLowerCase().contains('stack') &&
          !message.contains('{') &&
          !message.contains('}')) {
        return message;
      }
    } catch (_) {}

    return defaultAction != null
        ? '$defaultAction failed. Please try again.'
        : genericErrorMessage;
  }
}
