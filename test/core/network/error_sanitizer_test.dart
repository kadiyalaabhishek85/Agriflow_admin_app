import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:agriflow_admin/core/network/error_sanitizer.dart';
import 'package:agriflow_admin/features/auth/domain/entities/auth_exception.dart';
import 'package:agriflow_admin/features/grain_sales/domain/entities/grain_sale_exception.dart';
import 'package:agriflow_admin/features/seed_purchase/domain/entities/seed_purchase_exception.dart';

void main() {
  group('ErrorSanitizer Tests (ISSUE-P2-02)', () {
    test('Maps SocketException and network errors to clean user message', () {
      const socketEx = SocketException('Failed host lookup: agriflow-backend-t8o4.onrender.com');
      final msg = ErrorSanitizer.sanitize(socketEx);
      expect(msg, 'Unable to connect. Please check your internet connection.');
      expect(msg, isNot(contains('SocketException')));
      expect(msg, isNot(contains('agriflow-backend-t8o4')));
    });

    test('Maps 401 / unauthorized to session expired message', () {
      final msg1 = ErrorSanitizer.sanitize('HTTP 401 Unauthorized');
      expect(msg1, 'Your session has expired. Please log in again.');

      const authEx = AuthException(message: 'session_expired', statusCode: 401);
      final msg2 = ErrorSanitizer.sanitize(authEx);
      expect(msg2, 'Your session has expired. Please log in again.');
    });

    test('Maps 403 / forbidden to permission denied message', () {
      final msg1 = ErrorSanitizer.sanitize('HTTP 403 Forbidden: access restricted');
      expect(msg1, "You don't have permission to perform this action.");

      const grainEx = GrainSaleForbiddenException();
      final msg2 = ErrorSanitizer.sanitize(grainEx);
      expect(msg2, "You don't have permission to perform this action.");
    });

    test('Maps 404 / not found to clean not found message', () {
      final msg = ErrorSanitizer.sanitize('Resource not found 404');
      expect(msg, 'The requested information could not be found.');
    });

    test('Maps 409 / conflict to conflict message', () {
      final msg = ErrorSanitizer.sanitize('Data conflict 409 state mismatch');
      expect(msg, 'This action conflicts with the current data.');
    });

    test('Maps 422 / validation to clean validation message', () {
      final msg = ErrorSanitizer.sanitize('422 Unprocessable Entity: validation error');
      expect(msg, 'Some information is invalid. Please check and try again.');
    });

    test('Maps 500 / 502 / 503 / 504 to clean server error message', () {
      expect(
        ErrorSanitizer.sanitize('500 Internal Server Error'),
        'Something went wrong on the server. Please try again.',
      );
      expect(
        ErrorSanitizer.sanitize('502 Bad Gateway'),
        'Something went wrong on the server. Please try again.',
      );
      expect(
        ErrorSanitizer.sanitize('503 Service Unavailable'),
        'Something went wrong on the server. Please try again.',
      );
    });

    test('Safely preserves human-friendly domain message when clean', () {
      const customEx = SeedPurchaseException('This seed lot has insufficient stock.');
      final msg = ErrorSanitizer.sanitize(customEx);
      expect(msg, 'This seed lot has insufficient stock.');
    });

    test('Never exposes raw stack traces or internal JSON to user', () {
      final rawError = '{"detail":[{"loc":["body","price"],"msg":"value is not a valid float","type":"type_error.float"}]}';
      final msg = ErrorSanitizer.sanitize(rawError);
      expect(msg, isNot(contains('{"detail"')));
      expect(msg, isNot(contains('type_error.float')));
      expect(msg, isNotEmpty);
    });
  });
}
