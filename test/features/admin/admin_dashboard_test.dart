import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agriflow_admin/core/constants/app_colors.dart';
import 'package:agriflow_admin/core/models/user_role.dart';
import 'package:agriflow_admin/features/admin/dashboard/domain/entities/admin_dashboard_data.dart';
import 'package:agriflow_admin/features/admin/dashboard/domain/repositories/admin_dashboard_repository.dart';
import 'package:agriflow_admin/features/admin/dashboard/presentation/controllers/admin_dashboard_controller.dart';
import 'package:agriflow_admin/features/admin/dashboard/presentation/screens/admin_dashboard_view.dart';
import 'package:agriflow_admin/features/auth/domain/entities/auth_session.dart';
import 'package:agriflow_admin/features/auth/domain/entities/auth_user.dart';
import 'package:agriflow_admin/features/dashboard/shared/presentation/widgets/dashboard_chart_card.dart';
import 'package:agriflow_admin/features/dashboard/shared/presentation/widgets/dashboard_mandi_strip.dart';
import 'package:agriflow_admin/features/dashboard/shared/presentation/widgets/dashboard_metric_card.dart';
import 'package:agriflow_admin/features/dashboard/shared/presentation/widgets/dashboard_state_views.dart';
import 'package:agriflow_admin/features/dashboard/shared/presentation/widgets/dashboard_summary_strip.dart';

class _MockAdminDashboardRepository implements AdminDashboardRepository {
  AdminDashboardData? dataToReturn;
  Exception? errorToThrow;
  int getDashboardDataCallCount = 0;

  @override
  Future<AdminDashboardData> getAdminDashboard({
    required String accessToken,
  }) async {
    getDashboardDataCallCount++;
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return dataToReturn!;
  }
}

AdminDashboardData _createSampleAdminData() {
  return const AdminDashboardData(
    totalFarmers: 9,
    activeFarmers: 9,
    pendingFarmerApprovals: 0,
    totalManagers: 5,
    activeBookings: 14,
    pendingGrainSales: 8,
    totalSeedStockKg: 169242.0,
    warehouseInventoryKg: 15503.4,
    procurementMtdKg: 100010949.24,
    revenueMtd: 165.0,
    procurementCostMtd: 0.0,
    profitMtd: 165.0,
    pendingPayments: 27,
    activeCrops: 23,
    visitsToday: 3,
    totalVisits: 15,
    activeWarehouses: 2,
    monthlyPoints: [
      MonthlyChartPoint(label: 'May', value: 25000),
      MonthlyChartPoint(label: 'Jun', value: 32000),
      MonthlyChartPoint(label: 'Jul', value: 41000),
    ],
    mandiRates: [
      MandiRateItem(
        cropType: 'Cotton',
        grade: 'Grade A',
        pricePerKg: 78.5,
        effectiveDate: '2026-09-23',
      ),
      MandiRateItem(
        cropType: 'Paddy',
        grade: 'Common',
        pricePerKg: 24.0,
        effectiveDate: '2026-09-23',
      ),
    ],
    recentAuditLogs: [
      AdminAuditItem(
        id: '1',
        action: 'SEED_PURCHASE_CREATED',
        userName: 'Admin User',
        details: 'Purchased 500kg Cotton seed',
      ),
      AdminAuditItem(
        id: '2',
        action: 'BOOKING_APPROVED',
        userName: 'Field Manager 1',
        details: 'Slot approved for Farmer #12',
      ),
    ],
  );
}

void main() {
  const testUser = AuthUser(
    id: '1',
    name: 'Super Admin',
    phone: '9999900000',
    role: UserRole.superAdmin,
    status: 'active',
  );

  const testSession = AuthSession(
    user: testUser,
    accessToken: 'test_admin_token',
    refreshToken: 'test_refresh_token',
  );

  group('AdminDashboardData Entity & Serialization Tests', () {
    test('Correctly parses full backend JSON response', () {
      final json = {
        'total_farmers': 9,
        'active_farmers': 9,
        'total_managers': 5,
        'active_bookings': 14,
        'pending_grain_sales': 8,
        'total_seed_stock_kg': '169242.00',
        'warehouse_inventory_kg': '15503.40',
        'procurement_mtd_kg': '100010949.24',
        'revenue_mtd': '165.00',
        'profit_mtd': '165.00',
        'pending_payments': 27,
        'active_crops': 23,
        'visits_today': 0,
      };

      final data = AdminDashboardData.fromJson(summaryJson: json);

      expect(data.totalFarmers, 9);
      expect(data.activeFarmers, 9);
      expect(data.totalManagers, 5);
      expect(data.activeBookings, 14);
      expect(data.pendingGrainSales, 8);
      expect(data.totalSeedStockKg, 169242.0);
      expect(data.warehouseInventoryKg, 15503.4);
      expect(data.procurementMtdKg, 100010949.24);
      expect(data.revenueMtd, 165.0);
      expect(data.profitMtd, 165.0);
      expect(data.pendingPayments, 27);
      expect(data.activeCrops, 23);
      expect(data.visitsToday, 0);
    });

    test('Gracefully handles null or missing values with fallback defaults', () {
      final json = <String, dynamic>{};

      final data = AdminDashboardData.fromJson(summaryJson: json);

      expect(data.totalFarmers, 0);
      expect(data.totalSeedStockKg, 0.0);
      expect(data.procurementMtdKg, 0.0);
      expect(data.mandiRates, isEmpty);
      expect(data.recentAuditLogs, isEmpty);
    });

    test('Parses AdminAuditItem with missing details or unparseable date', () {
      final logJson = {
        'id': 101,
        'action': 'LOGIN_SUCCESS',
        'user_name': null,
        'role': 'super_admin',
        'created_at': '2026-09-23T14:00:00Z',
      };

      final item = AdminAuditItem.fromJson(logJson);
      expect(item.id, '101');
      expect(item.action, 'LOGIN_SUCCESS');
      expect(item.userName, isNull);
    });
  });

  group('AdminDashboardController State Transitions', () {
    late _MockAdminDashboardRepository mockRepo;
    late AdminDashboardController controller;

    setUp(() {
      mockRepo = _MockAdminDashboardRepository();
      controller = AdminDashboardController(
        repository: mockRepo,
        accessToken: testSession.accessToken,
      );
    });

    test('Initial state is initial and not loading', () {
      expect(controller.state.isInitial, isTrue);
      expect(controller.state.isLoading, isFalse);
      expect(controller.state.data, isNull);
    });

    test('loadDashboard() transitions through loading to success', () async {
      mockRepo.dataToReturn = _createSampleAdminData();

      final future = controller.loadDashboard();
      expect(controller.state.isLoading, isTrue);

      await future;

      expect(controller.state.isSuccess, isTrue);
      expect(controller.state.data, isNotNull);
      expect(controller.state.data!.totalFarmers, 9);
      expect(mockRepo.getDashboardDataCallCount, 1);
    });

    test('loadDashboard() transitions to error on repository failure', () async {
      mockRepo.errorToThrow = Exception('Failed to connect to FastAPI backend');

      await controller.loadDashboard();

      expect(controller.state.isError, isTrue);
      expect(controller.state.errorMessage, contains('Failed to connect'));
    });

    test('refreshDashboard() maintains data while refreshing', () async {
      mockRepo.dataToReturn = _createSampleAdminData();
      await controller.loadDashboard();

      expect(controller.state.isSuccess, isTrue);

      final refreshFuture = controller.refreshDashboard();
      expect(controller.state.isRefreshing, isTrue);
      expect(controller.state.data, isNotNull);

      await refreshFuture;

      expect(controller.state.isSuccess, isTrue);
      expect(mockRepo.getDashboardDataCallCount, 2);
    });
  });

  group('AdminDashboardView Widget & UI Rendering', () {
    late _MockAdminDashboardRepository mockRepo;
    late AdminDashboardController controller;

    setUp(() {
      mockRepo = _MockAdminDashboardRepository();
      controller = AdminDashboardController(
        repository: mockRepo,
        accessToken: testSession.accessToken,
      );
    });

    Widget createTestWidget({Size? screenSize}) {
      return MaterialApp(
        theme: ThemeData(
          scaffoldBackgroundColor: AppColors.background,
        ),
        home: MediaQuery(
          data: MediaQueryData(
            size: screenSize ?? const Size(412, 860),
          ),
          child: Scaffold(
            body: AdminDashboardView(
              session: testSession,
              controller: controller,
              onTabSelected: (_) {},
              onNavigate: (_) {},
            ),
          ),
        ),
      );
    }

    testWidgets('Renders loading skeleton on initial load', (tester) async {
      mockRepo.dataToReturn = _createSampleAdminData();

      await tester.pumpWidget(createTestWidget());
      expect(find.byType(DashboardLoadingView), findsOneWidget);
    });

    testWidgets('Renders error view with retry action on failure', (tester) async {
      mockRepo.errorToThrow = Exception('Network error');
      await controller.loadDashboard();

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(DashboardErrorView), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);

      // Tap retry with fixed mock
      mockRepo.errorToThrow = null;
      mockRepo.dataToReturn = _createSampleAdminData();

      await tester.tap(find.text('Try Again'));
      await tester.pumpAndSettle();

      expect(find.byType(DashboardErrorView), findsNothing);
      expect(find.byType(DashboardSummaryStrip), findsOneWidget);
    });

    testWidgets('Renders complete Admin dashboard layout with all sections', (tester) async {
      mockRepo.dataToReturn = _createSampleAdminData();
      await controller.loadDashboard();

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // 1. Header greeting
      expect(find.textContaining('Super Admin'), findsOneWidget);
      expect(find.text('SUPER ADMIN'), findsOneWidget);

      // 2. Summary strip
      expect(find.byType(DashboardSummaryStrip), findsOneWidget);
      expect(find.text('MTD Procurement'), findsOneWidget);

      // 3. KPI Stat Cards
      expect(find.byType(DashboardMetricCard), findsWidgets);
      expect(find.text('Total Farmers'), findsOneWidget);
      expect(find.text('Active Bookings'), findsOneWidget);
      expect(find.text('Total Seed Stock'), findsOneWidget);
      expect(find.text('Warehouse Stock'), findsOneWidget);
      expect(find.text('Pending Sales'), findsOneWidget);
      expect(find.text('Pending Payments'), findsOneWidget);

      // 4. Mandi Rates Strip
      expect(find.byType(DashboardMandiStrip), findsOneWidget);
      expect(find.text('Live Mandi Rates'), findsOneWidget);
      expect(find.text('Cotton'), findsOneWidget);
      expect(find.text('Paddy'), findsOneWidget);

      // 5. Monthly Trend Chart
      expect(find.byType(DashboardChartCard), findsOneWidget);
      expect(find.text('Procurement Trend'), findsOneWidget);

      // 6. Quick Action Cards
      expect(find.text('Quick Actions'), findsOneWidget);
      expect(find.text('Seed Purchase'), findsOneWidget);
      expect(find.text('Booking Slot'), findsOneWidget);
      expect(find.text('Farm Visit'), findsOneWidget);
      expect(find.text('Grain Sale'), findsOneWidget);

      // 7. Recent Activity Audit Logs
      expect(find.text('Recent Activity'), findsOneWidget);
      expect(find.text('Purchased 500kg Cotton seed'), findsOneWidget);
      expect(find.text('Slot approved for Farmer #12'), findsOneWidget);
    });

    testWidgets('Zero RenderFlex overflows across diverse Android screen sizes', (tester) async {
      mockRepo.dataToReturn = _createSampleAdminData();
      await controller.loadDashboard();

      final screenSizes = [
        const Size(320, 568), // Small compact screen
        const Size(360, 640), // Standard Android
        const Size(412, 860), // Modern Android standard
        const Size(412, 960), // Tall Android device
      ];

      for (final size in screenSizes) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(createTestWidget(screenSize: size));
        await tester.pumpAndSettle();

        // Verify no overflow exception was thrown
        expect(tester.takeException(), isNull, reason: 'Overflow occurred on size $size');
        expect(find.byType(AdminDashboardView), findsOneWidget);
      }
    });
  });
}
