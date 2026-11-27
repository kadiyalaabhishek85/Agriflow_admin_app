import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agriflow_admin/app.dart';
import 'package:agriflow_admin/core/models/user_role.dart';
import 'package:agriflow_admin/core/widgets/custom_drawer.dart';
import 'package:agriflow_admin/core/widgets/module_placeholder_screen.dart';
import 'package:agriflow_admin/features/admin/presentation/admin_shell.dart';
import 'package:agriflow_admin/features/manager/presentation/manager_shell.dart';
import 'package:agriflow_admin/features/auth/domain/entities/auth_session.dart';
import 'package:agriflow_admin/features/auth/domain/entities/auth_user.dart';
import 'package:agriflow_admin/features/auth/domain/repositories/auth_repository.dart';
import 'package:agriflow_admin/features/auth/presentation/controllers/auth_controller.dart';
import 'package:agriflow_admin/features/auth/presentation/screens/unsupported_role_screen.dart';
import 'package:agriflow_admin/features/admin/dashboard/presentation/screens/admin_dashboard_view.dart';
import 'package:agriflow_admin/features/manager/dashboard/presentation/screens/manager_dashboard_view.dart';
import 'package:agriflow_admin/features/grain_sales/presentation/screens/grain_sale_screen.dart';
import 'package:agriflow_admin/features/warehouse/presentation/screens/warehouse_screen.dart';
import 'package:agriflow_admin/features/billing/presentation/screens/billing_screen.dart';
import 'package:agriflow_admin/features/market_rates/presentation/screens/market_rates_screen.dart';
import 'package:agriflow_admin/features/managers/presentation/screens/manager_screen.dart';
import 'package:agriflow_admin/features/reports/presentation/screens/report_screen.dart';
import 'package:agriflow_admin/features/event_logs/presentation/screens/event_log_screen.dart';
import 'package:agriflow_admin/features/settings/presentation/screens/settings_screen.dart';
import 'package:agriflow_admin/features/help/presentation/screens/help_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAuthRepository implements AuthRepository {
  AuthSession? sessionToReturn;
  bool logoutCalled = false;

  @override
  Future<AuthSession> login({
    required String phone,
    required String password,
    bool rememberMe = true,
  }) async {
    return sessionToReturn!;
  }

  @override
  Future<AuthSession?> restoreSession() async => sessionToReturn;

  @override
  Future<void> logout() async {
    logoutCalled = true;
  }

  @override
  Future<void> requestPasswordResetOtp({required String phone}) async {}

  @override
  Future<void> resetPasswordWithOtp({
    required String phone,
    required String code,
    required String newPassword,
  }) async {}

  @override
  Future<AuthUser> getCurrentUser({required String accessToken}) async {
    return sessionToReturn!.user;
  }
}

AuthSession _createSession(UserRole role) {
  return AuthSession(
    accessToken: 'test_access_token',
    refreshToken: 'test_refresh_token',
    user: AuthUser(
      id: 'usr_1',
      name: role.isAdmin ? 'Admin User' : 'Manager User',
      phone: '9876543210',
      role: role,
      email: role.isAdmin ? 'admin@agriflow.in' : 'manager@agriflow.in',
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Milestone 3 — Role Routing Tests', () {
    testWidgets('super_admin routes to AdminShell', (tester) async {
      tester.view.physicalSize = const Size(412, 860);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = _FakeAuthRepository();
      repo.sessionToReturn = _createSession(UserRole.superAdmin);
      final controller = AuthController(repository: repo);

      await tester.pumpWidget(AgriFlowApp(authController: controller));
      await controller.restoreSession();
      await tester.pumpAndSettle();

      expect(find.byType(AdminShell), findsOneWidget);
      expect(find.byType(ManagerShell), findsNothing);
      expect(find.byType(AdminDashboardView), findsOneWidget);
    });

    testWidgets('manager routes to ManagerShell', (tester) async {
      tester.view.physicalSize = const Size(412, 860);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = _FakeAuthRepository();
      repo.sessionToReturn = _createSession(UserRole.manager);
      final controller = AuthController(repository: repo);

      await tester.pumpWidget(AgriFlowApp(authController: controller));
      await controller.restoreSession();
      await tester.pumpAndSettle();

      expect(find.byType(ManagerShell), findsOneWidget);
      expect(find.byType(AdminShell), findsNothing);
      expect(find.byType(ManagerDashboardView), findsOneWidget);
    });

    testWidgets('farmer / unauthorized role routes to UnsupportedRoleScreen', (tester) async {
      tester.view.physicalSize = const Size(412, 860);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = _FakeAuthRepository();
      repo.sessionToReturn = _createSession(UserRole.unsupported);
      final controller = AuthController(repository: repo);

      await tester.pumpWidget(AgriFlowApp(authController: controller));
      await controller.restoreSession();
      await tester.pumpAndSettle();

      expect(find.byType(UnsupportedRoleScreen), findsOneWidget);
      expect(find.byType(AdminShell), findsNothing);
      expect(find.byType(ManagerShell), findsNothing);
      expect(find.text('Access Restricted'), findsOneWidget);
    });
  });

  group('Milestone 3 — Admin Navigation Shell Tests', () {
    testWidgets('AdminShell renders 4 bottom tabs matching HTML specification', (tester) async {
      tester.view.physicalSize = const Size(412, 860);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final session = _createSession(UserRole.superAdmin);
      await tester.pumpWidget(
        MaterialApp(
          home: AdminShell(session: session, onLogout: () {}),
        ),
      );
      await tester.pumpAndSettle();

      // Verify the 4 bottom tabs
      expect(find.text('Seed Purchase'), findsWidgets);
      expect(find.text('Booking Slot'), findsWidgets);
      expect(find.text('Farm Visits'), findsWidgets);
      expect(find.text('Grain Sales'), findsWidgets);

      // Verify Account tab is NOT present in Admin bottom tabs (only in Manager)
      expect(find.text('Account'), findsNothing);
    });

    testWidgets('Tapping Admin bottom tab switches to GrainSaleScreen', (tester) async {
      tester.view.physicalSize = const Size(412, 860);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final session = _createSession(UserRole.superAdmin);
      await tester.pumpWidget(
        MaterialApp(
          home: AdminShell(session: session, onLogout: () {}),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on Grain Sales tab
      await tester.tap(find.text('Grain Sales').first);
      await tester.pumpAndSettle();

      expect(find.byType(GrainSaleScreen), findsOneWidget);
    });

    testWidgets('Tapping Event Logs in Admin drawer switches to EventLogScreen', (tester) async {
      tester.view.physicalSize = const Size(412, 860);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final session = _createSession(UserRole.superAdmin);
      await tester.pumpWidget(
        MaterialApp(
          home: AdminShell(session: session, onLogout: () {}),
        ),
      );
      await tester.pumpAndSettle();

      // Open drawer using hamburger icon
      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      final drawerFinder = find.byType(CustomDrawer);
      final eventLogsItem = find.descendant(of: drawerFinder, matching: find.text('Event Logs'));
      await tester.ensureVisible(eventLogsItem);
      await tester.pumpAndSettle();
      await tester.tap(eventLogsItem);
      await tester.pumpAndSettle();

      expect(find.byType(EventLogScreen), findsOneWidget);
      expect(find.byType(ModulePlaceholderScreen), findsNothing);

      // Tap the back chevron in the Event Logs header
      await tester.tap(find.byIcon(Icons.chevron_left_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(EventLogScreen), findsNothing);
      expect(find.byType(AdminDashboardView), findsOneWidget);
    });

    testWidgets('Tapping Managers in Admin drawer switches to ManagerScreen', (tester) async {
      tester.view.physicalSize = const Size(412, 860);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final session = _createSession(UserRole.superAdmin);
      await tester.pumpWidget(
        MaterialApp(
          home: AdminShell(session: session, onLogout: () {}),
        ),
      );
      await tester.pumpAndSettle();

      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      final drawerFinder = find.byType(CustomDrawer);
      final managersItem = find.descendant(of: drawerFinder, matching: find.text('Managers'));
      await tester.ensureVisible(managersItem);
      await tester.pumpAndSettle();
      await tester.tap(managersItem);
      await tester.pumpAndSettle();

      expect(find.byType(ManagerScreen), findsOneWidget);
      expect(find.byType(ModulePlaceholderScreen), findsNothing);

      await tester.tap(find.byIcon(Icons.chevron_left_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(ManagerScreen), findsNothing);
      expect(find.byType(AdminDashboardView), findsOneWidget);
    });

    testWidgets('Tapping Reports & Analytics in Admin drawer switches to ReportScreen', (tester) async {
      tester.view.physicalSize = const Size(412, 860);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final session = _createSession(UserRole.superAdmin);
      await tester.pumpWidget(
        MaterialApp(
          home: AdminShell(session: session, onLogout: () {}),
        ),
      );
      await tester.pumpAndSettle();

      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      final drawerFinder = find.byType(CustomDrawer);
      final reportsItem = find.descendant(of: drawerFinder, matching: find.text('Reports & Analytics'));
      await tester.ensureVisible(reportsItem);
      await tester.pumpAndSettle();
      await tester.tap(reportsItem);
      await tester.pumpAndSettle();

      expect(find.byType(ReportScreen), findsOneWidget);
      expect(find.byType(ModulePlaceholderScreen), findsNothing);

      // Use the explicit back key — the month navigator has its own
      // chevron_left icon, so find.byIcon would be ambiguous.
      await tester.tap(find.byKey(const Key('report_back_btn')));
      await tester.pumpAndSettle();

      expect(find.byType(ReportScreen), findsNothing);
      expect(find.byType(AdminDashboardView), findsOneWidget);
    });

    testWidgets('Tapping Billing & Invoices in Admin drawer switches to BillingScreen', (tester) async {
      tester.view.physicalSize = const Size(412, 860);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final session = _createSession(UserRole.superAdmin);
      await tester.pumpWidget(
        MaterialApp(
          home: AdminShell(session: session, onLogout: () {}),
        ),
      );
      await tester.pumpAndSettle();

      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      final drawerFinder = find.byType(CustomDrawer);
      await tester.tap(find.descendant(of: drawerFinder, matching: find.text('Billing & Invoices')));
      await tester.pumpAndSettle();

      expect(find.byType(BillingScreen), findsOneWidget);
    });

    testWidgets('Tapping Market Rates in Admin drawer switches to MarketRatesScreen with Set Rate action', (tester) async {
      tester.view.physicalSize = const Size(412, 860);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final session = _createSession(UserRole.superAdmin);
      await tester.pumpWidget(
        MaterialApp(
          home: AdminShell(session: session, onLogout: () {}),
        ),
      );
      await tester.pumpAndSettle();

      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      final drawerFinder = find.byType(CustomDrawer);
      await tester.tap(find.descendant(of: drawerFinder, matching: find.text('Market Rates')));
      await tester.pumpAndSettle();

      expect(find.byType(MarketRatesScreen), findsOneWidget);
      // Admin role may create rates — Set Rate action is present.
      expect(find.byKey(const ValueKey('market-rates-set-rate')), findsOneWidget);
    });

    testWidgets('Tapping Warehouse in Admin drawer switches to WarehouseScreen', (tester) async {
      tester.view.physicalSize = const Size(412, 860);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final session = _createSession(UserRole.superAdmin);
      await tester.pumpWidget(
        MaterialApp(
          home: AdminShell(session: session, onLogout: () {}),
        ),
      );
      await tester.pumpAndSettle();

      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      final drawerFinder = find.byType(CustomDrawer);
      await tester.tap(find.descendant(of: drawerFinder, matching: find.text('Warehouse')));
      await tester.pumpAndSettle();

      expect(find.byType(WarehouseScreen), findsOneWidget);
    });

    testWidgets('Admin Drawer contains Administration section and items', (tester) async {
      tester.view.physicalSize = const Size(412, 860);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final session = _createSession(UserRole.superAdmin);
      await tester.pumpWidget(
        MaterialApp(
          home: AdminShell(session: session, onLogout: () {}),
        ),
      );
      await tester.pumpAndSettle();

      // Open drawer using hamburger icon
      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      final drawerFinder = find.byType(CustomDrawer);
      expect(drawerFinder, findsOneWidget);

      expect(find.descendant(of: drawerFinder, matching: find.text('ADMINISTRATION')), findsOneWidget);
      expect(find.descendant(of: drawerFinder, matching: find.text('Managers')), findsOneWidget);
      expect(find.descendant(of: drawerFinder, matching: find.text('Credits')), findsOneWidget);
      expect(find.descendant(of: drawerFinder, matching: find.text('Cache Management')), findsOneWidget);
      expect(find.descendant(of: drawerFinder, matching: find.text('Reports & Analytics')), findsOneWidget);
      expect(find.descendant(of: drawerFinder, matching: find.text('Log out')), findsOneWidget);
    });
  });

  group('Milestone 3 — Manager Navigation Shell Tests', () {
    testWidgets('ManagerShell renders 5 bottom tabs matching HTML specification', (tester) async {
      tester.view.physicalSize = const Size(412, 860);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final session = _createSession(UserRole.manager);
      await tester.pumpWidget(
        MaterialApp(
          home: ManagerShell(session: session, onLogout: () {}),
        ),
      );
      await tester.pumpAndSettle();

      // Verify the 5 bottom tabs
      expect(find.text('Seed Purchase'), findsWidgets);
      expect(find.text('Booking Slot'), findsWidgets);
      expect(find.text('Farm Visits'), findsWidgets);
      expect(find.text('Grain Sales'), findsWidgets);
      expect(find.text('Account'), findsWidgets);
    });

    testWidgets('Manager Drawer does NOT contain Administration section (Role Isolation)', (tester) async {
      tester.view.physicalSize = const Size(412, 860);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final session = _createSession(UserRole.manager);
      await tester.pumpWidget(
        MaterialApp(
          home: ManagerShell(session: session, onLogout: () {}),
        ),
      );
      await tester.pumpAndSettle();

      // Open drawer
      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      final drawerFinder = find.byType(CustomDrawer);
      expect(drawerFinder, findsOneWidget);

      // Confirm Administration section and Admin-only items are absent in Drawer
      expect(find.descendant(of: drawerFinder, matching: find.text('ADMINISTRATION')), findsNothing);
      expect(find.descendant(of: drawerFinder, matching: find.text('Managers')), findsNothing);
      expect(find.descendant(of: drawerFinder, matching: find.text('Credits')), findsNothing);
      expect(find.descendant(of: drawerFinder, matching: find.text('Cache Management')), findsNothing);
      expect(find.descendant(of: drawerFinder, matching: find.text('Reports & Analytics')), findsNothing);
    });

    testWidgets('Tapping Settings in Manager drawer shows the real SettingsScreen (M10)', (tester) async {
      tester.view.physicalSize = const Size(412, 860);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final session = _createSession(UserRole.manager);
      await tester.pumpWidget(
        MaterialApp(
          home: ManagerShell(session: session, onLogout: () {}),
        ),
      );
      await tester.pumpAndSettle();

      // Open drawer
      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      // Tap on Settings in Drawer
      final drawerFinder = find.byType(CustomDrawer);
      final settingsItem = find.descendant(of: drawerFinder, matching: find.text('Settings'));
      await tester.ensureVisible(settingsItem);
      await tester.pumpAndSettle();
      await tester.tap(settingsItem);
      await tester.pumpAndSettle();

      // M10: real Settings screen (not the old placeholder)
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.byType(ModulePlaceholderScreen), findsNothing);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Push notifications'), findsOneWidget);
      expect(find.text('Terms of service'), findsOneWidget);
    });

    testWidgets('Tapping Settings in Admin drawer shows the real SettingsScreen (M10)', (tester) async {
      tester.view.physicalSize = const Size(412, 860);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final session = _createSession(UserRole.superAdmin);
      await tester.pumpWidget(
        MaterialApp(
          home: AdminShell(session: session, onLogout: () {}),
        ),
      );
      await tester.pumpAndSettle();

      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      final drawerFinder = find.byType(CustomDrawer);
      final settingsItem = find.descendant(of: drawerFinder, matching: find.text('Settings'));
      await tester.ensureVisible(settingsItem);
      await tester.pumpAndSettle();
      await tester.tap(settingsItem);
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.byType(ModulePlaceholderScreen), findsNothing);
      expect(find.text('Privacy policy'), findsOneWidget);
      expect(
        find.text('Sri Siva Sai Seeds Admin Console v1.0.0'),
        findsOneWidget,
      );
    });

    testWidgets('Tapping Help in Manager drawer shows the real HelpScreen (M10)', (tester) async {
      tester.view.physicalSize = const Size(412, 860);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final session = _createSession(UserRole.manager);
      await tester.pumpWidget(
        MaterialApp(
          home: ManagerShell(session: session, onLogout: () {}),
        ),
      );
      await tester.pumpAndSettle();

      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      final drawerFinder = find.byType(CustomDrawer);
      final helpItem = find.descendant(of: drawerFinder, matching: find.text('Help & Support'));
      await tester.ensureVisible(helpItem);
      await tester.pumpAndSettle();
      await tester.tap(helpItem);
      await tester.pumpAndSettle();

      expect(find.byType(HelpScreen), findsOneWidget);
      expect(find.byType(ModulePlaceholderScreen), findsNothing);
      expect(find.text('Contact Support'), findsOneWidget);
      expect(find.textContaining('+91 9502662924'), findsOneWidget);
    });

    testWidgets('Tapping Billing & Invoices in Manager drawer switches to BillingScreen', (tester) async {
      tester.view.physicalSize = const Size(412, 860);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final session = _createSession(UserRole.manager);
      await tester.pumpWidget(
        MaterialApp(
          home: ManagerShell(session: session, onLogout: () {}),
        ),
      );
      await tester.pumpAndSettle();

      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      final drawerFinder = find.byType(CustomDrawer);
      await tester.tap(find.descendant(of: drawerFinder, matching: find.text('Billing & Invoices')));
      await tester.pumpAndSettle();

      expect(find.byType(BillingScreen), findsOneWidget);
    });

    testWidgets('Tapping Market Rates in Manager drawer shows MarketRatesScreen without Set Rate action', (tester) async {
      tester.view.physicalSize = const Size(412, 860);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final session = _createSession(UserRole.manager);
      await tester.pumpWidget(
        MaterialApp(
          home: ManagerShell(session: session, onLogout: () {}),
        ),
      );
      await tester.pumpAndSettle();

      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      final drawerFinder = find.byType(CustomDrawer);
      await tester.tap(find.descendant(of: drawerFinder, matching: find.text('Market Rates')));
      await tester.pumpAndSettle();

      expect(find.byType(MarketRatesScreen), findsOneWidget);
      // Manager is read-only — no Set Rate action is rendered.
      expect(find.byKey(const ValueKey('market-rates-set-rate')), findsNothing);
    });

    testWidgets('Tapping Warehouse in Manager drawer switches to WarehouseScreen', (tester) async {
      tester.view.physicalSize = const Size(412, 860);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final session = _createSession(UserRole.manager);
      await tester.pumpWidget(
        MaterialApp(
          home: ManagerShell(session: session, onLogout: () {}),
        ),
      );
      await tester.pumpAndSettle();

      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      final drawerFinder = find.byType(CustomDrawer);
      await tester.tap(find.descendant(of: drawerFinder, matching: find.text('Warehouse')));
      await tester.pumpAndSettle();

      expect(find.byType(WarehouseScreen), findsOneWidget);
    });
  });

  group('Milestone 3 — Logout Integration Tests', () {
    testWidgets('Tapping Logout in Drawer triggers logout callback', (tester) async {
      tester.view.physicalSize = const Size(412, 860);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool logoutTriggered = false;
      final session = _createSession(UserRole.superAdmin);

      await tester.pumpWidget(
        MaterialApp(
          home: AdminShell(
            session: session,
            onLogout: () {
              logoutTriggered = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open drawer
      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      // Tap Log out button in drawer footer
      await tester.tap(find.text('Log out'));
      await tester.pumpAndSettle();

      expect(logoutTriggered, isTrue);
    });

    testWidgets('AdminShell back navigation returns to previously opened screen before Home', (tester) async {
      tester.view.physicalSize = const Size(412, 860);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final session = _createSession(UserRole.superAdmin);
      await tester.pumpWidget(
        MaterialApp(
          home: AdminShell(session: session, onLogout: () {}),
        ),
      );
      await tester.pumpAndSettle();

      // Open Reports & Analytics via drawer
      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();
      final reportsItem = find.descendant(
        of: find.byType(CustomDrawer),
        matching: find.text('Reports & Analytics'),
      );
      await tester.ensureVisible(reportsItem);
      await tester.pumpAndSettle();
      await tester.tap(reportsItem);
      await tester.pumpAndSettle();
      expect(find.byType(ReportScreen), findsOneWidget);

      // Navigate from Reports to Grain Sales bottom tab
      await tester.tap(find.text('Grain Sales').last);
      await tester.pumpAndSettle();
      expect(find.byType(GrainSaleScreen), findsOneWidget);

      // Back from Grain Sales returns to Reports & Analytics (not Home!)
      await tester.tap(find.byIcon(Icons.arrow_back_rounded).first);
      await tester.pumpAndSettle();
      expect(find.byType(ReportScreen), findsOneWidget);

      // Back from Reports & Analytics returns to Home Dashboard
      await tester.tap(find.byKey(const Key('report_back_btn')));
      await tester.pumpAndSettle();
      expect(find.byType(AdminDashboardView), findsOneWidget);
    });
  });
}
