import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:agriflow_admin/core/network/api_client.dart';
import 'package:agriflow_admin/features/auth/domain/entities/auth_exception.dart';
import 'package:agriflow_admin/features/dashboard/shared/presentation/widgets/dashboard_chart_card.dart';
import 'package:agriflow_admin/features/dashboard/shared/presentation/widgets/dashboard_mandi_strip.dart';
import 'package:agriflow_admin/features/admin/dashboard/domain/entities/admin_dashboard_data.dart';

abstract class AdminDashboardRemoteDataSource {
  Future<AdminDashboardData> fetchDashboardData({required String accessToken});
}

class FastApiAdminDashboardRemoteDataSource implements AdminDashboardRemoteDataSource {
  static const String defaultBaseUrl = ApiClient.defaultBaseUrl;
  static const String apiPrefix = '/api/v1';

  final String baseUrl;
  final http.Client client;
  final ApiClient? apiClient;

  FastApiAdminDashboardRemoteDataSource({
    String? baseUrl,
    http.Client? client,
    this.apiClient,
  })  : baseUrl = baseUrl ?? defaultBaseUrl,
        client = client ?? http.Client();

  Future<http.Response> _get(
    String path, {
    required String accessToken,
    Map<String, dynamic>? queryParams,
    Duration timeout = const Duration(seconds: 20),
    bool authenticated = true,
  }) async {
    final uri = _uri(path, queryParams);
    final authClient = apiClient;
    if (authenticated && authClient != null) {
      return authClient.get(uri, timeout: timeout);
    }
    return client
        .get(
          uri,
          headers: authenticated ? _headers(token: accessToken) : null,
        )
        .timeout(timeout);
  }

  Uri _uri(String path, [Map<String, dynamic>? queryParams]) {
    final base = Uri.parse('$baseUrl$apiPrefix$path');
    if (queryParams != null && queryParams.isNotEmpty) {
      return base.replace(queryParameters: queryParams);
    }
    return base;
  }

  Map<String, String> _headers({required String token}) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

  @override
  Future<AdminDashboardData> fetchDashboardData({required String accessToken}) async {
    try {
      // 1. Fetch Primary Admin Dashboard KPI Metrics
      final dashboardResponse = await _get(
        '/admin/dashboard',
        accessToken: accessToken,
        timeout: const Duration(seconds: 25),
      );

      final dashboardJson = _parseResponse(dashboardResponse);
      final summaryData = (dashboardJson['data'] as Map<String, dynamic>?) ?? dashboardJson;

      final sectionWarnings = <String>[];

      // 2. Fetch Mandi Rates
      List<MandiRateItem> mandiRates = [];
      try {
        final ratesResponse = await client
            .get(_uri('/public/market-rates'))
            .timeout(const Duration(seconds: 8));
        if (ratesResponse.statusCode == 200) {
          final ratesJson = jsonDecode(ratesResponse.body);
          final list = (ratesJson is Map && ratesJson['data'] is List)
              ? ratesJson['data'] as List
              : (ratesJson is List ? ratesJson : []);
          mandiRates = list
              .map((item) => MandiRateItem.fromJson(item as Map<String, dynamic>))
              .toList();
        } else {
          sectionWarnings.add('Mandi rates unavailable (HTTP ${ratesResponse.statusCode})');
        }
      } catch (_) {
        sectionWarnings.add('Mandi rates unavailable');
      }

      // 3. Fetch Monthly Reports for Trend Chart (current & past 5 months)
      List<MonthlyChartPoint> monthlyPoints = [];
      bool sawUnauthorized = false;
      try {
        final now = DateTime.now();
        final List<String> months = [];
        for (int i = 5; i >= 0; i--) {
          final d = DateTime(now.year, now.month - i, 1);
          final monthStr = '${d.year}-${d.month.toString().padLeft(2, '0')}';
          months.add(monthStr);
        }

        final reportFutures = months.map((m) async {
          try {
            final repRes = await _get(
              '/admin/reports/monthly',
              accessToken: accessToken,
              queryParams: {'month': m},
              timeout: const Duration(seconds: 8),
            );
            if (repRes.statusCode == 401) {
              sawUnauthorized = true;
              return null;
            }
            if (repRes.statusCode == 200) {
              final repJson = jsonDecode(repRes.body);
              final rData = repJson['data'] as Map<String, dynamic>? ?? {};
              final seedAmt = double.tryParse((rData['total_seed_purchases_amount'] ?? '0').toString()) ?? 0.0;
              final grainAmt = double.tryParse((rData['total_grain_sales_amount'] ?? '0').toString()) ?? 0.0;
              final totalMonthRevenue = seedAmt + grainAmt;
              final monthLabel = _formatMonthLabel(m);
              return MonthlyChartPoint(label: monthLabel, value: totalMonthRevenue);
            }
          } catch (_) {
            // Skip individual month failure
          }
          return null;
        });

        final results = await Future.wait(reportFutures);
        if (sawUnauthorized) {
          throw const AuthException(
            message: 'Session expired. Please log in again.',
            statusCode: 401,
          );
        }
        for (final pt in results) {
          if (pt != null) {
            monthlyPoints.add(pt);
          }
        }
      } on AuthException {
        rethrow;
      } catch (_) {
        // Recorded below if no points returned
      }

      if (monthlyPoints.isEmpty) {
        sectionWarnings.add('Monthly trend chart unavailable');
      }

      // 4. Fetch Total Visits count from /farm-visits
      int totalVisitsCount = 0;
      bool visitsFetchFailed = false;
      try {
        final visitsRes = await _get(
          '/farm-visits',
          accessToken: accessToken,
          timeout: const Duration(seconds: 10),
        );
        if (visitsRes.statusCode == 401) {
          throw const AuthException(
            message: 'Session expired. Please log in again.',
            statusCode: 401,
          );
        }
        if (visitsRes.statusCode == 200) {
          final vJson = jsonDecode(visitsRes.body);
          if (vJson['pagination'] != null && vJson['pagination']['total'] != null) {
            totalVisitsCount = (vJson['pagination']['total'] as num).toInt();
          } else if (vJson['data'] is List) {
            totalVisitsCount = (vJson['data'] as List).length;
          }
        } else {
          visitsFetchFailed = true;
          sectionWarnings.add('Farm visits count unavailable (HTTP ${visitsRes.statusCode})');
        }
      } on AuthException {
        rethrow;
      } catch (_) {
        visitsFetchFailed = true;
        sectionWarnings.add('Farm visits count unavailable');
      }

      // 5. Fetch Active Warehouses count
      int warehousesCount = 0;
      bool warehousesFetchFailed = false;
      try {
        final whRes = await _get(
          '/warehouses',
          accessToken: accessToken,
          timeout: const Duration(seconds: 10),
        );
        if (whRes.statusCode == 401) {
          throw const AuthException(
            message: 'Session expired. Please log in again.',
            statusCode: 401,
          );
        }
        if (whRes.statusCode == 200) {
          final whJson = jsonDecode(whRes.body);
          if (whJson['data'] is List) {
            warehousesCount = (whJson['data'] as List).length;
          }
        } else {
          warehousesFetchFailed = true;
          sectionWarnings.add('Warehouse count unavailable (HTTP ${whRes.statusCode})');
        }
      } on AuthException {
        rethrow;
      } catch (_) {
        warehousesFetchFailed = true;
        sectionWarnings.add('Warehouse count unavailable');
      }

      // 6. Fetch Recent Audit Logs
      List<AdminAuditItem> auditLogs = [];
      try {
        final auditRes = await _get(
          '/admin/audit-logs',
          accessToken: accessToken,
          queryParams: {'page': '1', 'page_size': '5'},
          timeout: const Duration(seconds: 10),
        );
        if (auditRes.statusCode == 401) {
          throw const AuthException(
            message: 'Session expired. Please log in again.',
            statusCode: 401,
          );
        }
        if (auditRes.statusCode == 200) {
          final aJson = jsonDecode(auditRes.body);
          final items = (aJson['data'] is List) ? aJson['data'] as List : [];
          auditLogs = items
              .map((item) => AdminAuditItem.fromJson(item as Map<String, dynamic>))
              .toList();
        } else {
          sectionWarnings.add('Recent activity unavailable (HTTP ${auditRes.statusCode})');
        }
      } on AuthException {
        rethrow;
      } catch (_) {
        sectionWarnings.add('Recent activity unavailable');
      }

      return AdminDashboardData.fromJson(
        summaryJson: summaryData,
        monthlyPoints: monthlyPoints,
        mandiRates: mandiRates,
        recentAuditLogs: auditLogs,
        totalVisits: totalVisitsCount,
        activeWarehouses: warehousesCount,
        sectionWarnings: sectionWarnings,
        visitsFetchFailed: visitsFetchFailed,
        warehousesFetchFailed: warehousesFetchFailed,
      );
    } on SocketException catch (_) {
      throw const AuthException(
        message: 'Network connection unavailable. Please check your internet connection.',
        isNetworkError: true,
      );
    } on TimeoutException catch (_) {
      throw const AuthException(
        message: 'Server request timed out. Please try again later.',
        isNetworkError: true,
      );
    }
  }

  String _formatMonthLabel(String yyyyMm) {
    try {
      final parts = yyyyMm.split('-');
      if (parts.length == 2) {
        final m = int.tryParse(parts[1]) ?? 1;
        const monthNames = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        return monthNames[m];
      }
    } catch (_) {}
    return yyyyMm;
  }

  Map<String, dynamic> _parseResponse(http.Response response) {
    Map<String, dynamic> jsonBody;
    try {
      jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      throw AuthException(
        message: 'Unexpected server response (HTTP ${response.statusCode})',
        statusCode: response.statusCode,
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonBody;
    }

    final errorObj = jsonBody['error'];
    String message = 'Dashboard request failed (HTTP ${response.statusCode})';
    String? code;

    if (errorObj is Map<String, dynamic>) {
      message = errorObj['message']?.toString() ?? message;
      code = errorObj['code']?.toString();
    } else if (jsonBody['message'] != null) {
      message = jsonBody['message'].toString();
    }

    throw AuthException(
      message: message,
      errorCode: code,
      statusCode: response.statusCode,
    );
  }
}
