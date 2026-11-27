import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:agriflow_admin/core/network/api_client.dart';
import 'package:agriflow_admin/features/auth/domain/entities/auth_exception.dart';

import '../../domain/entities/monthly_report.dart';
import '../../domain/entities/reports_exception.dart';
import 'report_remote_data_source.dart';

/// FastAPI implementation of ReportRemoteDataSource.
///
/// Verified endpoint:
/// - `GET /api/v1/admin/reports/monthly?month=YYYY-MM` → MonthlyReportResponse
class FastApiReportRemoteDataSource implements ReportRemoteDataSource {
  static const String defaultBaseUrl = ApiClient.defaultBaseUrl;
  static const String apiPrefix = '/api/v1';

  final String baseUrl;
  final http.Client client;
  final ApiClient? apiClient;

  FastApiReportRemoteDataSource({
    String? baseUrl,
    http.Client? client,
    this.apiClient,
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
      final uri = _uri('/admin/reports/monthly', {'month': month});
      final http.Response response;
      try {
        final authClient = apiClient;
        if (authClient != null) {
          response = await authClient.get(uri, timeout: const Duration(seconds: 25));
        } else {
          response = await client
              .get(uri, headers: _headers(accessToken))
              .timeout(const Duration(seconds: 25));
        }
      } on AuthException catch (e) {
        throw ReportsUnauthorizedException(message: e.message);
      }

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = (json['data'] as Map<String, dynamic>?) ?? json;
        return MonthlyReport.fromJson(data);
      }

      _handleErrorResponse(response);
    });
  }
}
