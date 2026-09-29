import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../domain/entities/monthly_report.dart';
import '../../domain/entities/reports_exception.dart';
import 'report_remote_data_source.dart';

/// FastAPI implementation of ReportRemoteDataSource.
///
/// Verified endpoint (live OpenAPI, re-verified 2026-09-28):
/// - `GET /api/v1/admin/reports/monthly?month=YYYY-MM` → MonthlyReportResponse
class FastApiReportRemoteDataSource implements ReportRemoteDataSource {
  static const String defaultBaseUrl =
      'https://agriflow-backend-t8o4.onrender.com';
  static const String apiPrefix = '/api/v1';

  final String baseUrl;
  final http.Client client;

  FastApiReportRemoteDataSource({
    String? baseUrl,
    http.Client? client,
  })  : baseUrl = baseUrl ?? defaultBaseUrl,
        client = client ?? http.Client();

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$baseUrl$apiPrefix$path').replace(queryParameters: query);

  Map<String, String> _headers(String token) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Never _handleErrorResponse(http.Response response) {
    String message = 'Request failed with status ${response.statusCode}';
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        if (body['detail'] != null) {
          message = body['detail'].toString();
        } else if (body['message'] != null) {
          message = body['message'].toString();
        } else if (body['error'] != null) {
          final err = body['error'];
          if (err is Map && err['message'] != null) {
            message = err['message'].toString();
          } else {
            message = err.toString();
          }
        }
      }
    } catch (_) {
      // Body not JSON, keep default status message
    }

    switch (response.statusCode) {
      case 401:
        throw ReportsUnauthorizedException(message: message);
      case 403:
        throw ReportsForbiddenException(message: message);
      case 422:
        throw ReportsValidationException(message: message);
      default:
        throw ReportsServerException(message: message);
    }
  }

  /// Wraps SocketException/TimeoutException once for every call below.
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on ReportsException {
      rethrow;
    } on SocketException catch (_) {
      throw const ReportsException(
        message:
            'Network connection unavailable. Please check your internet connection.',
        isNetworkError: true,
      );
    } on TimeoutException catch (_) {
      throw const ReportsException(
        message: 'Server request timed out. Please try again later.',
        isNetworkError: true,
      );
    }
  }

  @override
  Future<MonthlyReport> getMonthlyReport({
    required String accessToken,
    required String month,
  }) {
    return _guard(() async {
      final response = await client
          .get(
            _uri('/admin/reports/monthly', {'month': month}),
            headers: _headers(accessToken),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = (json['data'] as Map<String, dynamic>?) ?? json;
        return MonthlyReport.fromJson(data);
      }

      _handleErrorResponse(response);
    });
  }
}
