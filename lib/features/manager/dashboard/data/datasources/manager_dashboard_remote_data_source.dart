import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:agriflow_admin/core/network/api_client.dart';
import 'package:agriflow_admin/features/auth/domain/entities/auth_exception.dart';
import 'package:agriflow_admin/features/dashboard/shared/presentation/widgets/dashboard_mandi_strip.dart';
import 'package:agriflow_admin/features/manager/dashboard/domain/entities/manager_dashboard_data.dart';

abstract class ManagerDashboardRemoteDataSource {
  Future<ManagerDashboardData> fetchDashboardData({required String accessToken});
}

class FastApiManagerDashboardRemoteDataSource implements ManagerDashboardRemoteDataSource {
  static const String defaultBaseUrl = ApiClient.defaultBaseUrl;
  static const String apiPrefix = '/api/v1';

  final String baseUrl;
  final http.Client client;

  FastApiManagerDashboardRemoteDataSource({
    String? baseUrl,
    http.Client? client,
  })  : baseUrl = baseUrl ?? defaultBaseUrl,
        client = client ?? http.Client();

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
  Future<ManagerDashboardData> fetchDashboardData({required String accessToken}) async {
    try {
      int pendingSeeds = 0;
      int todaySeeds = 0;
      int bookingsTotal = 0;
      int farmVisitsCount = 0;
      int visitsScheduled = 0;
      int grainSalesTotal = 0;
      double revenueMtd = 0.0;

      // 1. Seed Purchases
      try {
        final seedRes = await client
            .get(_uri('/seed-purchases'), headers: _headers(token: accessToken))
            .timeout(const Duration(seconds: 10));
        if (seedRes.statusCode == 200) {
          final sJson = jsonDecode(seedRes.body);
          final items = (sJson['data'] is List) ? sJson['data'] as List : [];
          if (sJson['pagination'] != null && sJson['pagination']['total'] != null) {
            pendingSeeds = (sJson['pagination']['total'] as num).toInt();
          } else {
            pendingSeeds = items.length;
          }
          final today = DateTime.now();
          todaySeeds = items.where((item) {
            if (item is! Map<String, dynamic>) return false;
            final created = DateTime.tryParse(item['created_at']?.toString() ?? '');
            if (created == null) return false;
            final local = created.toLocal();
            return local.year == today.year &&
                local.month == today.month &&
                local.day == today.day;
          }).length;
        }
      } catch (_) {}

      // 2. Bookings
      try {
        final bookRes = await client
            .get(_uri('/bookings'), headers: _headers(token: accessToken))
            .timeout(const Duration(seconds: 10));
        if (bookRes.statusCode == 200) {
          final bJson = jsonDecode(bookRes.body);
          if (bJson['pagination'] != null && bJson['pagination']['total'] != null) {
            bookingsTotal = (bJson['pagination']['total'] as num).toInt();
          } else if (bJson['data'] is List) {
            bookingsTotal = (bJson['data'] as List).length;
          }
        }
      } catch (_) {}

      // 3. Farm Visits
      try {
        final visitRes = await client
            .get(_uri('/farm-visits'), headers: _headers(token: accessToken))
            .timeout(const Duration(seconds: 10));
        if (visitRes.statusCode == 200) {
          final vJson = jsonDecode(visitRes.body);
          final items = (vJson['data'] is List) ? vJson['data'] as List : [];
          farmVisitsCount = items.length;
          visitsScheduled = items.where((v) => v['status'] == 'scheduled').length;
        }
      } catch (_) {}

      // 4. Grain Sales
      try {
        final saleRes = await client
            .get(_uri('/grain-sales'), headers: _headers(token: accessToken))
            .timeout(const Duration(seconds: 10));
        if (saleRes.statusCode == 200) {
          final gJson = jsonDecode(saleRes.body);
          if (gJson['pagination'] != null && gJson['pagination']['total'] != null) {
            grainSalesTotal = (gJson['pagination']['total'] as num).toInt();
          } else if (gJson['data'] is List) {
            grainSalesTotal = (gJson['data'] as List).length;
          }
        }
      } catch (_) {}

      // 5. Try /admin/dashboard for precise aggregated values if permitted
      try {
        final dashRes = await client
            .get(_uri('/admin/dashboard'), headers: _headers(token: accessToken))
            .timeout(const Duration(seconds: 6));
        if (dashRes.statusCode == 200) {
          final dJson = jsonDecode(dashRes.body);
          final d = dJson['data'] as Map<String, dynamic>? ?? dJson;
          if (d['active_bookings'] != null) bookingsTotal = (d['active_bookings'] as num).toInt();
          if (d['pending_grain_sales'] != null) grainSalesTotal = (d['pending_grain_sales'] as num).toInt();
          if (d['visits_today'] != null) farmVisitsCount = (d['visits_today'] as num).toInt();
          if (d['revenue_mtd'] != null) revenueMtd = double.tryParse(d['revenue_mtd'].toString()) ?? 0.0;
        }
      } catch (_) {}

      // 6. Mandi Rates
      List<MandiRateItem> mandiRates = [];
      try {
        final ratesRes = await client
            .get(_uri('/public/market-rates'))
            .timeout(const Duration(seconds: 8));
        if (ratesRes.statusCode == 200) {
          final rJson = jsonDecode(ratesRes.body);
          final list = (rJson is Map && rJson['data'] is List)
              ? rJson['data'] as List
              : (rJson is List ? rJson : []);
          mandiRates = list
              .map((i) => MandiRateItem.fromJson(i as Map<String, dynamic>))
              .toList();
        }
      } catch (_) {}

      // 7. Recent Notifications
      List<ManagerNotificationItem> notifications = [];
      try {
        final notifRes = await client
            .get(_uri('/notifications'), headers: _headers(token: accessToken))
            .timeout(const Duration(seconds: 8));
        if (notifRes.statusCode == 200) {
          final nJson = jsonDecode(notifRes.body);
          final list = (nJson['data'] is List) ? nJson['data'] as List : [];
          notifications = list
              .map((i) => ManagerNotificationItem.fromJson(i as Map<String, dynamic>))
              .toList();
        }
      } catch (_) {}

      return ManagerDashboardData(
        pendingSeedOrders: pendingSeeds,
        todaySeedOrders: todaySeeds,
        bookingsTotal: bookingsTotal,
        farmVisitsCount: farmVisitsCount,
        farmVisitsScheduled: visitsScheduled,
        grainSalesTotal: grainSalesTotal,
        revenueMtd: revenueMtd,
        mandiRates: mandiRates,
        recentNotifications: notifications,
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
}
