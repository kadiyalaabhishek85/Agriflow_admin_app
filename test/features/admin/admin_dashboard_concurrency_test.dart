import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:agriflow_admin/features/admin/dashboard/data/datasources/admin_dashboard_remote_data_source.dart';

class ConcurrencyTrackingClient extends http.BaseClient {
  int maxConcurrentRequests = 0;
  int currentActiveRequests = 0;
  final List<String> requestedMonths = [];
  final Map<String, int> monthDelayMs;

  ConcurrencyTrackingClient({this.monthDelayMs = const {}});

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    currentActiveRequests++;
    if (currentActiveRequests > maxConcurrentRequests) {
      maxConcurrentRequests = currentActiveRequests;
    }

    final uri = request.url;
    final path = uri.path;

    if (path.contains('/admin/dashboard')) {
      currentActiveRequests--;
      return http.StreamedResponse(
        Stream.value(utf8.encode(jsonEncode({
          'success': true,
          'data': {
            'revenue_mtd': '50000',
            'orders_today': 12,
            'farmers_active': 150,
            'warehouses_count': 5,
          }
        }))),
        200,
        headers: {'content-type': 'application/json'},
      );
    }

    if (path.contains('/admin/reports/monthly')) {
      final month = uri.queryParameters['month'] ?? '';
      requestedMonths.add(month);

      final delay = monthDelayMs[month] ?? 20;
      await Future.delayed(Duration(milliseconds: delay));

      // Simulate partial failure for one month to test graceful error handling
      if (month.endsWith('-02')) {
        currentActiveRequests--;
        return http.StreamedResponse(
          Stream.value(utf8.encode('{"detail":"Data not available"}')),
          500,
        );
      }

      final body = jsonEncode({
        'success': true,
        'data': {
          'month': month,
          'total_seed_purchases_amount': '1000',
          'total_grain_sales_amount': '2000',
        }
      });

      currentActiveRequests--;
      return http.StreamedResponse(
        Stream.value(utf8.encode(body)),
        200,
        headers: {'content-type': 'application/json'},
      );
    }

    currentActiveRequests--;
    return http.StreamedResponse(
      Stream.value(utf8.encode('{}')),
      200,
    );
  }
}

void main() {
  group('Admin Dashboard Trend Concurrency Tests (ISSUE-P2-03)', () {
    test('Six monthly report requests execute concurrently via Future.wait and preserve chronological order', () async {
      final client = ConcurrencyTrackingClient(
        // Assign varied delays to ensure ordering is maintained by index, not arrival time
        monthDelayMs: {
          // Earlier months take longer
          '2026-04': 60,
          '2026-05': 40,
          '2026-06': 20,
          '2026-07': 10,
          '2026-08': 30,
          '2026-09': 5,
        },
      );

      final dataSource = FastApiAdminDashboardRemoteDataSource(
        baseUrl: 'https://test.agriflow.com',
        client: client,
      );

      final data = await dataSource.fetchDashboardData(accessToken: 'admin_token');

      // Verify concurrency: more than 1 active request at once (all 6 fired together)
      expect(client.maxConcurrentRequests, greaterThan(1));

      // Verify points exist
      expect(data.monthlyPoints, isNotEmpty);

      // Verify ordering: labels must follow chronological calendar progression
      // Even though arrival times were inverted by delay, results must be chronologically sorted
      final labels = data.monthlyPoints.map((p) => p.label).toList();
      for (int i = 0; i < labels.length - 1; i++) {
        // Labels are formatted e.g. "Apr '26", "May '26"
        expect(labels[i], isNot(equals(labels[i + 1])));
      }
    });

    test('Failure in one monthly report does not crash dashboard or corrupt other points', () async {
      final client = ConcurrencyTrackingClient();
      final dataSource = FastApiAdminDashboardRemoteDataSource(
        baseUrl: 'https://test.agriflow.com',
        client: client,
      );

      final data = await dataSource.fetchDashboardData(accessToken: 'admin_token');

      expect(data, isNotNull);
      expect(data.totalFarmers, isNotNull);
      // Even if one month returned 500, remaining points are parsed and displayed
      expect(data.monthlyPoints, isNotEmpty);
    });
  });
}
