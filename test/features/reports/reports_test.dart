import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:agriflow_admin/features/reports/data/datasources/fast_api_report_remote_data_source.dart';
import 'package:agriflow_admin/features/reports/data/datasources/report_remote_data_source.dart';
import 'package:agriflow_admin/features/reports/data/repositories/report_repository_impl.dart';
import 'package:agriflow_admin/features/reports/domain/entities/monthly_report.dart';
import 'package:agriflow_admin/features/reports/domain/entities/reports_exception.dart';
import 'package:agriflow_admin/features/reports/domain/repositories/report_repository.dart';
import 'package:agriflow_admin/features/reports/presentation/controllers/report_controller.dart';
import 'package:agriflow_admin/features/reports/presentation/screens/report_screen.dart';

// ---------------------------------------------------------------------------
// Mock Remote Data Source for Controller / Widget Testing
// ---------------------------------------------------------------------------

class _MockReportRemoteDataSource implements ReportRemoteDataSource {
  Exception? errorToThrow;
  int callCount = 0;
  String? lastMonth;

  @override
  Future<MonthlyReport> getMonthlyReport({
    required String accessToken,
    required String month,
  }) async {
    callCount++;
    lastMonth = month;
    if (errorToThrow != null) throw errorToThrow!;

    return MonthlyReport(
      month: month,
      totalSeedPurchasesAmount: '125000',
      totalGrainSalesAmount: '80000',
      totalBookings: 12,
      newFarmers: 5,
    );
  }
}

Widget _buildTestApp(Widget child, {Size? mediaSize}) {
  return MaterialApp(
    home: mediaSize != null
        ? MediaQuery(
            data: MediaQueryData(size: mediaSize),
            child: child,
          )
        : child,
  );
}

void main() {
  group('MonthlyReport Entity Tests', () {
    test('fromJson parses contract fields', () {
      final report = MonthlyReport.fromJson({
        'month': '2026-08',
        'total_seed_purchases_amount': '125000.00',
        'total_grain_sales_amount': '80000.50',
        'total_bookings': 12,
        'new_farmers': 5,
      });

      expect(report.month, '2026-08');
      expect(report.totalSeedPurchasesAmount, '125000.00');
      expect(report.totalGrainSalesAmount, '80000.50');
      expect(report.totalBookings, 12);
      expect(report.newFarmers, 5);
      expect(report.seedPurchasesValue, 125000);
      expect(report.grainSalesValue, closeTo(80000.5, 0.001));
    });

    test('fromJson tolerates missing numeric fields', () {
      final report = MonthlyReport.fromJson({'month': '2026-01'});

      expect(report.month, '2026-01');
      expect(report.totalSeedPurchasesAmount, '0');
      expect(report.totalGrainSalesAmount, '0');
      expect(report.totalBookings, 0);
      expect(report.newFarmers, 0);
    });

    test('formatAmount applies Indian grouping', () {
      expect(MonthlyReport.formatAmount('125000'), '₹1,25,000');
      expect(MonthlyReport.formatAmount('1000'), '₹1,000');
      expect(MonthlyReport.formatAmount('500'), '₹500');
      expect(MonthlyReport.formatAmount('0'), '₹0');
      expect(MonthlyReport.formatAmount('1234.56'), '₹1,234.56');
      expect(MonthlyReport.formatAmount('-2500'), '₹-2,500');
      expect(MonthlyReport.formatAmount('12345678'), '₹1,23,45,678');
      expect(MonthlyReport.formatAmount('not-a-number'), 'not-a-number');
    });
  });

  group('FastApiReportRemoteDataSource HTTP Tests', () {
    test('getMonthlyReport sends month param and parses data', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/api/v1/admin/reports/monthly');
        expect(request.url.queryParameters['month'], '2026-08');
        expect(request.headers['Authorization'], 'Bearer test-token');

        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'month': '2026-08',
              'total_seed_purchases_amount': '125000',
              'total_grain_sales_amount': '80000',
              'total_bookings': 12,
              'new_farmers': 5,
            },
          }),
          200,
        );
      });

      final ds = FastApiReportRemoteDataSource(
        baseUrl: 'https://test-api.agriflow.com',
        client: mockClient,
      );

      final report = await ds.getMonthlyReport(
        accessToken: 'test-token',
        month: '2026-08',
      );

      expect(report.month, '2026-08');
      expect(report.totalBookings, 12);
      expect(report.newFarmers, 5);
    });

    test('HTTP error statuses throw typed ReportsException subclasses',
        () async {
      for (final code in [401, 403, 422, 500]) {
        final mockClient = MockClient((request) async {
          return http.Response(jsonEncode({'detail': 'Error $code'}), code);
        });

        final ds = FastApiReportRemoteDataSource(
          baseUrl: 'https://test-api.agriflow.com',
          client: mockClient,
        );

        expect(
          () => ds.getMonthlyReport(accessToken: 'token', month: '2026-08'),
          throwsA(predicate((e) {
            if (code == 401) return e is ReportsUnauthorizedException;
            if (code == 403) return e is ReportsForbiddenException;
            if (code == 422) return e is ReportsValidationException;
            return e is ReportsServerException;
          })),
        );
      }
    });
  });

  group('ReportController State Tests', () {
    late _MockReportRemoteDataSource mockDs;
    late ReportRepository repo;
    late ReportController controller;

    String formatMonth(int year, int month) =>
        '$year-${month.toString().padLeft(2, '0')}';

    setUp(() {
      mockDs = _MockReportRemoteDataSource();
      repo = ReportRepositoryImpl(remoteDataSource: mockDs);
      controller = ReportController(repository: repo, accessToken: 'token');
    });

    test('starts on the current month with a readable label', () {
      final now = DateTime.now();
      expect(controller.month, formatMonth(now.year, now.month));
      expect(controller.monthLabel, contains('${now.year}'));
    });

    test('loadReport fetches and stores the report', () async {
      final future = controller.loadReport();
      expect(controller.isLoading, isTrue);
      await future;

      expect(controller.isLoading, isFalse);
      expect(controller.report, isNotNull);
      expect(controller.errorMessage, isNull);
      expect(mockDs.callCount, 1);
      expect(mockDs.lastMonth, controller.month);
    });

    test('goToPreviousMonth shifts month backwards and reloads', () async {
      await controller.loadReport();
      final before = DateTime.parse('${controller.month}-01');

      await controller.goToPreviousMonth();

      final after = DateTime.parse('${controller.month}-01');
      expect(after.month, before.month == 1 ? 12 : before.month - 1);
      expect(after.year, before.month == 1 ? before.year - 1 : before.year);
      expect(mockDs.callCount, 2);
      expect(mockDs.lastMonth, controller.month);
      expect(controller.report!.month, controller.month);
    });

    test('goToNextMonth shifts month forward and reloads', () async {
      await controller.loadReport();
      final before = DateTime.parse('${controller.month}-01');

      await controller.goToNextMonth();

      final after = DateTime.parse('${controller.month}-01');
      expect(after.month, before.month == 12 ? 1 : before.month + 1);
      expect(after.year, before.month == 12 ? before.year + 1 : before.year);
      expect(mockDs.callCount, 2);
    });

    test('loadReport handles error correctly', () async {
      mockDs.errorToThrow =
          const ReportsServerException(message: 'Report unavailable');

      await controller.loadReport();

      expect(controller.isLoading, isFalse);
      expect(controller.errorMessage, 'Report unavailable');
      expect(controller.report, isNull);
    });
  });

  group('Report Widget Tests', () {
    late _MockReportRemoteDataSource mockDs;
    late ReportController controller;

    setUp(() {
      mockDs = _MockReportRemoteDataSource();
      controller = ReportController(
        repository: ReportRepositoryImpl(remoteDataSource: mockDs),
        accessToken: 'token',
      );
    });

    testWidgets('ReportScreen shows stat cards with formatted values',
        (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        _buildTestApp(
          ReportScreen(controller: controller, onBack: () {}),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('report_screen')), findsOneWidget);
      expect(find.byKey(const Key('report_seed_purchases')), findsOneWidget);
      expect(find.text('₹1,25,000'), findsOneWidget);
      expect(find.byKey(const Key('report_grain_sales')), findsOneWidget);
      expect(find.text('₹80,000'), findsOneWidget);
      expect(find.byKey(const Key('report_bookings')), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.byKey(const Key('report_new_farmers')), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('SEED PURCHASES'), findsOneWidget);
      expect(find.text('GRAIN SALES'), findsOneWidget);
    });

    testWidgets('Export control is present but backend-blocked',
        (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        _buildTestApp(
          ReportScreen(controller: controller, onBack: () {}),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('report_export_btn')), findsOneWidget);
      expect(
        find.byTooltip(
            'PDF/CSV export: Backend API required — to be supplied by Syed.'),
        findsOneWidget,
      );
      expect(
        find.text(
            'PDF/CSV report export: Backend API required — to be supplied by Syed.'),
        findsOneWidget,
      );
    });

    testWidgets('Prev/next month buttons reload for adjacent months',
        (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        _buildTestApp(
          ReportScreen(controller: controller, onBack: () {}),
        ),
      );
      await tester.pumpAndSettle();
      expect(mockDs.callCount, 1);

      final initialLabel = controller.monthLabel;

      await tester.tap(find.byKey(const Key('report_prev_month_btn')));
      await tester.pumpAndSettle();

      expect(mockDs.callCount, 2);
      expect(controller.monthLabel, isNot(initialLabel));

      final prevLabel = controller.monthLabel;
      await tester.tap(find.byKey(const Key('report_next_month_btn')));
      await tester.pumpAndSettle();

      expect(mockDs.callCount, 3);
      expect(controller.monthLabel, initialLabel);
      expect(prevLabel, isNot(initialLabel));
    });

    testWidgets('Error state shows message and retry button', (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      mockDs.errorToThrow =
          const ReportsServerException(message: 'Report unavailable');

      await tester.pumpWidget(
        _buildTestApp(
          ReportScreen(controller: controller, onBack: () {}),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Report unavailable'), findsOneWidget);
      expect(find.byKey(const Key('report_retry_btn')), findsOneWidget);

      // Recover on retry
      mockDs.errorToThrow = null;
      await tester.tap(find.byKey(const Key('report_retry_btn')));
      await tester.pumpAndSettle();

      expect(controller.report, isNotNull);
      expect(find.text('₹1,25,000'), findsOneWidget);
    });
  });
}
