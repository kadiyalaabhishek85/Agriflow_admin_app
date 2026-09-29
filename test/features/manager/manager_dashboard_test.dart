import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agriflow_admin/core/constants/app_colors.dart';
import 'package:agriflow_admin/core/models/user_role.dart';
import 'package:agriflow_admin/features/auth/domain/entities/auth_session.dart';
import 'package:agriflow_admin/features/auth/domain/entities/auth_user.dart';
import 'package:agriflow_admin/features/dashboard/shared/presentation/widgets/dashboard_chart_card.dart';
import 'package:agriflow_admin/features/dashboard/shared/presentation/widgets/dashboard_mandi_strip.dart';
import 'package:agriflow_admin/features/dashboard/shared/presentation/widgets/dashboard_metric_card.dart';
import 'package:agriflow_admin/features/dashboard/shared/presentation/widgets/dashboard_state_views.dart';
import 'package:agriflow_admin/features/dashboard/shared/presentation/widgets/dashboard_summary_strip.dart';
import 'package:agriflow_admin/features/manager/dashboard/domain/entities/manager_dashboard_data.dart';
import 'package:agriflow_admin/features/manager/dashboard/domain/repositories/manager_dashboard_repository.dart';
import 'package:agriflow_admin/features/manager/dashboard/presentation/controllers/manager_dashboard_controller.dart';
import 'package:agriflow_admin/features/manager/dashboard/presentation/screens/manager_dashboard_view.dart';

class _MockManagerDashboardRepository implements ManagerDashboardRepository {
  ManagerDashboardData? dataToReturn;
  Exception? errorToThrow;
  int getDashboardDataCallCount = 0;

  @override
  Future<ManagerDashboardData> getManagerDashboard({
    required String accessToken,
  }) async {
    getDashboardDataCallCount++;
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return dataToReturn!;
  }
}

ManagerDashboardData _createSampleManagerData() {
  return ManagerDashboardData(
    pendingSeedOrders: 12,
    todaySeedOrders: 4,
    bookingsTotal: 14,
    farmVisitsCount: 4,
    farmVisitsScheduled: 1,
    grainSalesTotal: 8,
    revenueMtd: 12000.0,
    mandiRates: const [
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
    recentNotifications: [
      ManagerNotificationItem(
        id: 'n1',
        title: 'New Booking Assigned',
        message: 'Farmer John booked 10 bags of Cotton seed.',
        createdAt: DateTime.parse('2026-09-23T08:30:00Z'),
        isRead: false,
      ),
      ManagerNotificationItem(
        id: 'n2',
        title: 'Low Stock Alert',
        message: 'Warehouse Cotton seed is below 2000kg threshold.',
        createdAt: DateTime.parse('2026-09-23T07:15:00Z'),
        isRead: true,
      ),
    ],
  );
}

void main() {
  const testManagerUser = AuthUser(
    id: '10',
    name: 'Field Manager Ravi',
    phone: '9888800000',
    role: UserRole.manager,
    status: 'active',
  );

  const testSession = AuthSession(
    user: testManagerUser,
    accessToken: 'test_manager_token',
    refreshToken: 'test_refresh_token',
  );

  group('ManagerDashboardData Entity Tests', () {
    test('Constructs correctly with defaults and formats time ago', () {
      final item = ManagerNotificationItem(
        id: 'notif_1',
        title: 'Test Notification',
        message: 'Test message',
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      );

      expect(item.id, 'notif_1');
      expect(item.isRead, isFalse);
      expect(item.timeAgo, '5m ago');
    });

    test('Empty factory provides zeros and empty lists', () {
      final empty = ManagerDashboardData.empty();
      expect(empty.pendingSeedOrders, 0);
      expect(empty.bookingsTotal, 0);
      expect(empty.mandiRates, isEmpty);
      expect(empty.recentNotifications, isEmpty);
    });
  });

  group('ManagerDashboardController State Transitions', () {
    late _MockManagerDashboardRepository mockRepo;
    late ManagerDashboardController controller;

    setUp(() {
      mockRepo = _MockManagerDashboardRepository();
      controller = ManagerDashboardController(
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
      mockRepo.dataToReturn = _createSampleManagerData();

      final future = controller.loadDashboard();
      expect(controller.state.isLoading, isTrue);

      await future;

      expect(controller.state.isSuccess, isTrue);
      expect(controller.state.data, isNotNull);
      expect(controller.state.data!.farmVisitsCount, 4);
      expect(mockRepo.getDashboardDataCallCount, 1);
    });

    test('loadDashboard() transitions to error on failure', () async {
      mockRepo.errorToThrow = Exception('Manager API 403 Forbidden');

      await controller.loadDashboard();

      expect(controller.state.isError, isTrue);
      expect(controller.state.errorMessage, "You don't have permission to perform this action.");
    });

    test('refreshDashboard() maintains data during refresh', () async {
      mockRepo.dataToReturn = _createSampleManagerData();
      await controller.loadDashboard();

      final refreshFuture = controller.refreshDashboard();
      expect(controller.state.isRefreshing, isTrue);

      await refreshFuture;

      expect(controller.state.isSuccess, isTrue);
      expect(mockRepo.getDashboardDataCallCount, 2);
    });
  });

  group('ManagerDashboardView Widget & UI Tests', () {
    late _MockManagerDashboardRepository mockRepo;
    late ManagerDashboardController controller;

    setUp(() {
      mockRepo = _MockManagerDashboardRepository();
      controller = ManagerDashboardController(
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
            body: ManagerDashboardView(
              session: testSession,
              controller: controller,
              onTabSelected: (_) {},
              onNavigate: (_) {},
            ),
          ),
        ),
      );
    }

    testWidgets('Renders loading skeleton initially', (tester) async {
      mockRepo.dataToReturn = _createSampleManagerData();

      await tester.pumpWidget(createTestWidget());
      expect(find.byType(DashboardLoadingView), findsOneWidget);
    });

    testWidgets('Renders error view on network failure and handles retry', (tester) async {
      mockRepo.errorToThrow = Exception('Network error');
      await controller.loadDashboard();

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(DashboardErrorView), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);

      mockRepo.errorToThrow = null;
      mockRepo.dataToReturn = _createSampleManagerData();

      await tester.tap(find.text('Try Again'));
      await tester.pumpAndSettle();

      expect(find.byType(DashboardErrorView), findsNothing);
      expect(find.byType(DashboardSummaryStrip), findsOneWidget);
    });

    testWidgets('Renders complete Manager dashboard layout with operational focus', (tester) async {
      mockRepo.dataToReturn = _createSampleManagerData();
      await controller.loadDashboard();

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // 1. Header greeting & role badge
      expect(find.textContaining('Field Manager Ravi'), findsOneWidget);
      expect(find.text('FIELD MANAGER'), findsOneWidget);

      // 2. Operational Summary strip — revenue is month-to-date (contract
      //    exposes revenue_mtd only), never labelled "Today's".
      expect(find.byType(DashboardSummaryStrip), findsOneWidget);
      expect(find.text('Revenue (month-to-date)'), findsOneWidget);
      expect(find.text("Today's Revenue"), findsNothing);

      // 3. Operational KPI Stat Cards — honest labels, no fabricated deltas
      expect(find.byType(DashboardMetricCard), findsWidgets);
      expect(find.text('Pending seed orders'), findsOneWidget);
      expect(find.text('Bookings'), findsOneWidget);
      expect(find.text('Farm visits'), findsOneWidget);
      expect(find.text('Grain sales'), findsOneWidget);
      expect(find.text('Bookings today'), findsNothing);
      expect(find.text('Farm visits today'), findsNothing);
      expect(find.text('Grain sales today'), findsNothing);
      // P1-02: VisitStatus enum has no "in_progress" — scheduled count only.
      expect(find.text('1 scheduled'), findsOneWidget);
      expect(find.textContaining('in progress'), findsNothing);
      expect(find.textContaining('slots left'), findsNothing);
      expect(find.textContaining('vs yesterday'), findsNothing);
      expect(find.textContaining('new today'), findsNothing);

      // 4. Mandi Rates Strip
      expect(find.byType(DashboardMandiStrip), findsOneWidget);
      expect(find.text('Live Mandi Rates'), findsOneWidget);

      // 5. Operational Quick Actions
      expect(find.text('Quick Actions'), findsOneWidget);
      expect(find.text('Seed Requests'), findsOneWidget);
      expect(find.text('Farm Visits'), findsOneWidget);
      expect(find.text('Grain Sales'), findsOneWidget);

      // 6. Operational Tools
      expect(find.text('More Tools'), findsOneWidget);
      expect(find.text('Inventory'), findsOneWidget);
      expect(find.text('Warehouse'), findsOneWidget);
      expect(find.text('Billing'), findsOneWidget);

      // 7. Recent Notifications List
      expect(find.text('Recent Notifications'), findsOneWidget);
      expect(find.text('New Booking Assigned'), findsOneWidget);
      expect(find.text('Low Stock Alert'), findsOneWidget);
    });

    testWidgets('Strict Role Isolation: Admin financials, charts, and audit logs are NOT shown to Manager', (tester) async {
      mockRepo.dataToReturn = _createSampleManagerData();
      await controller.loadDashboard();

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Ensure Financial / Admin chart is strictly absent
      expect(find.byType(DashboardChartCard), findsNothing);
      expect(find.text('Procurement Trend'), findsNothing);

      // Ensure Admin audit logs header is absent
      expect(find.text('Recent System Activity'), findsNothing);
      expect(find.text('Recent Activity'), findsNothing);

      // Ensure Admin badge is absent and Manager badge is present
      expect(find.text('SUPER ADMIN'), findsNothing);
      expect(find.text('FIELD MANAGER'), findsOneWidget);
    });

    testWidgets('Zero RenderFlex overflows across diverse Android screen sizes', (tester) async {
      mockRepo.dataToReturn = _createSampleManagerData();
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

        expect(tester.takeException(), isNull, reason: 'Overflow occurred on size $size');
        expect(find.byType(ManagerDashboardView), findsOneWidget);
      }
    });
  });
}
