import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agriflow_admin/core/models/user_role.dart';
import 'package:agriflow_admin/core/widgets/squircle_icon_button.dart';
import 'package:agriflow_admin/features/account/presentation/screens/account_screen.dart';
import 'package:agriflow_admin/features/auth/domain/entities/auth_session.dart';
import 'package:agriflow_admin/features/auth/domain/entities/auth_user.dart';
import 'package:agriflow_admin/features/auth/domain/repositories/auth_repository.dart';
import 'package:agriflow_admin/features/auth/presentation/controllers/auth_controller.dart';
import 'package:agriflow_admin/features/help/presentation/screens/help_screen.dart';
import 'package:agriflow_admin/features/settings/presentation/screens/settings_screen.dart';

class _FakeAuthRepository implements AuthRepository {
  AuthSession? session;

  @override
  Future<AuthSession> login({
    required String phone,
    required String password,
    bool rememberMe = true,
  }) async =>
      session!;

  @override
  Future<AuthSession?> restoreSession() async => session;

  @override
  Future<void> logout() async {}

  @override
  Future<void> requestPasswordResetOtp({required String phone}) async {}

  @override
  Future<void> resetPasswordWithOtp({
    required String phone,
    required String code,
    required String newPassword,
  }) async {}

  @override
  Future<AuthUser> getCurrentUser({required String accessToken}) async =>
      session!.user;
}

AuthSession _session() => AuthSession(
      accessToken: 'test_access_token',
      refreshToken: 'test_refresh_token',
      user: const AuthUser(
        id: 'usr_1',
        name: 'Admin User',
        phone: '9876543210',
        email: 'admin@agriflow.in',
        role: UserRole.admin,
        status: 'active',
      ),
    );

String _userResponseBody({String name = 'Renamed Admin', String? email}) =>
    jsonEncode({
      'data': {
        'id': 'usr_1',
        'name': name,
        'phone': '9876543210',
        'email': email,
        'role': 'admin',
        'status': 'active',
        'first_login': false,
        'created_at': '2026-01-01T00:00:00Z',
      },
    });

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  void setPhoneSize(WidgetTester tester) {
    tester.view.physicalSize = const Size(412, 860);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());
  }

  Future<AuthController> restoredController() async {
    final repo = _FakeAuthRepository()..session = _session();
    final controller = AuthController(repository: repo);
    await controller.restoreSession();
    return controller;
  }

  group('AuthController.applyUser (M10 session propagation)', () {
    test('Replaces the session user and notifies listeners', () async {
      final controller = await restoredController();
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.applyUser(
        const AuthUser(
          id: 'usr_1',
          name: 'Renamed Admin',
          phone: '9876543210',
          role: UserRole.admin,
        ),
      );

      expect(controller.state.session!.user.name, 'Renamed Admin');
      expect(notifications, 1);
    });

    test('Without an authenticated session it is a no-op', () {
      final controller = AuthController(repository: _FakeAuthRepository());
      controller.applyUser(
        const AuthUser(
          id: 'usr_1',
          name: 'Renamed Admin',
          phone: '9876543210',
          role: UserRole.admin,
        ),
      );
      expect(controller.state.session, isNull);
      expect(controller.state.isAuthenticated, isFalse);
    });
  });

  group('AccountScreen M10 menu rows', () {
    testWidgets('Shows edit profile, settings and help rows', (tester) async {
      setPhoneSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: AccountScreen(session: _session(), onLogout: () {}),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Edit profile details'), findsOneWidget);
      expect(find.text('Settings & preferences'), findsOneWidget);
      expect(find.text('Help & support'), findsOneWidget);
    });

    testWidgets('Settings and help rows push their screens', (tester) async {
      setPhoneSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: AccountScreen(session: _session(), onLogout: () {}),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Settings & preferences'));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.text('Push notifications'), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byType(SettingsScreen),
          matching: find.byType(SquircleIconButton),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsNothing);

      await tester.tap(find.text('Help & support'));
      await tester.pumpAndSettle();
      expect(find.byType(HelpScreen), findsOneWidget);
      expect(find.text('Contact Support'), findsOneWidget);
    });
  });

  group('Edit profile sheet (PATCH /api/v1/users/me)', () {
    Future<void> openSheet(WidgetTester tester, {http.Client? client, AuthController? controller}) async {
      setPhoneSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: AccountScreen(
            session: _session(),
            onLogout: () {},
            httpClient: client,
            authController: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit profile details'));
      await tester.pumpAndSettle();
    }

    testWidgets('Shows contract-scoped fields: name + email editable, phone read-only', (tester) async {
      await openSheet(tester);

      final sheet = find.byType(Form);
      expect(sheet, findsOneWidget);
      expect(find.descendant(of: sheet, matching: find.text('Edit Profile')), findsOneWidget);
      expect(
        find.descendant(of: sheet, matching: find.widgetWithText(TextFormField, 'Admin User')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: sheet, matching: find.widgetWithText(TextFormField, 'admin@agriflow.in')),
        findsOneWidget,
      );
      expect(find.descendant(of: sheet, matching: find.text('Save changes')), findsOneWidget);
      // Phone read-only with honest backend note; zone/branch not present.
      expect(find.descendant(of: sheet, matching: find.text('9876543210')), findsOneWidget);
      expect(
        find.descendant(
          of: sheet,
          matching: find.text('Phone changes: Backend API required — to be supplied by Syed.'),
        ),
        findsOneWidget,
      );
      expect(find.text('Zone / Branch'), findsNothing);
    });

    testWidgets('Validates required name, minimum length and email format', (tester) async {
      final client = MockClient(
        (_) async => http.Response('{"detail":"unexpected"}', 500),
      );
      await openSheet(tester, client: client);

      final nameField = find.byType(TextFormField).at(0);
      final emailField = find.byType(TextFormField).at(1);
      final saveButton = find.widgetWithText(ElevatedButton, 'Save changes');

      await tester.enterText(nameField, '');
      await tester.tap(saveButton);
      await tester.pump();
      expect(find.text('Name is required.'), findsOneWidget);

      await tester.enterText(nameField, 'A');
      await tester.tap(saveButton);
      await tester.pump();
      expect(find.text('Name must be at least 2 characters.'), findsOneWidget);

      await tester.enterText(nameField, 'Valid Name');
      await tester.enterText(emailField, 'not-an-email');
      await tester.tap(saveButton);
      await tester.pump();
      expect(find.text('Enter a valid email address.'), findsOneWidget);
      // Validation kept the sheet open — no request was sent.
      expect(find.text('Edit Profile'), findsOneWidget);
    });

    testWidgets('Successful save PATCHes {name, email} only and refreshes display + session', (tester) async {
      http.Request? captured;
      final client = MockClient((request) async {
        captured = request;
        return http.Response(
          _userResponseBody(name: 'Renamed Admin', email: 'renamed@agriflow.in'),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final controller = await restoredController();

      await openSheet(tester, client: client, controller: controller);

      final nameField = find.byType(TextFormField).at(0);
      final emailField = find.byType(TextFormField).at(1);
      await tester.enterText(nameField, 'Renamed Admin');
      await tester.enterText(emailField, 'renamed@agriflow.in');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save changes'));
      await tester.pumpAndSettle();

      // Contract: PATCH /users/me with ONLY {name, email}.
      expect(captured, isNotNull);
      expect(captured!.method, 'PATCH');
      expect(captured!.url.path, endsWith('/api/v1/users/me'));
      expect(captured!.url.path, contains('/api/v1/users/me'));
      final body = jsonDecode(captured!.body) as Map<String, dynamic>;
      expect(body.keys.toSet(), {'name', 'email'});
      expect(body['name'], 'Renamed Admin');
      expect(body['email'], 'renamed@agriflow.in');

      // Sheet closed, account display + auth session refreshed.
      expect(find.text('Edit Profile'), findsNothing);
      expect(find.text('Renamed Admin'), findsWidgets);
      expect(controller.state.session!.user.name, 'Renamed Admin');
      expect(controller.state.session!.user.email, 'renamed@agriflow.in');
      expect(find.text('Profile updated successfully'), findsOneWidget);
      // Drain the AppToast auto-dismiss timer so it isn't pending at teardown.
      await tester.pump(const Duration(milliseconds: 3000));
      await tester.pumpAndSettle();
    });

    testWidgets('Empty email sends null (contract allows nullable email)', (tester) async {
      http.Request? captured;
      final client = MockClient((request) async {
        captured = request;
        return http.Response(
          _userResponseBody(name: 'Admin User', email: null),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      await openSheet(tester, client: client);

      final emailField = find.byType(TextFormField).at(1);
      await tester.enterText(emailField, '');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save changes'));
      await tester.pumpAndSettle();

      expect(captured, isNotNull);
      final body = jsonDecode(captured!.body) as Map<String, dynamic>;
      expect(body.containsKey('email'), isTrue);
      expect(body['email'], isNull);
      // Drain the AppToast auto-dismiss timer so it isn't pending at teardown.
      await tester.pump(const Duration(milliseconds: 3000));
      await tester.pumpAndSettle();
    });

    testWidgets('Server validation error surfaces in the sheet without closing it', (tester) async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'detail': [
              {'msg': 'Name is already taken'},
            ],
          }),
          422,
          headers: {'content-type': 'application/json'},
        ),
      );

      await openSheet(tester, client: client);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Save changes'));
      await tester.pumpAndSettle();

      expect(find.text('Name is already taken'), findsOneWidget);
      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.text('Save changes'), findsOneWidget);
    });

    testWidgets('Network failure surfaces a clean message and keeps the sheet open', (tester) async {
      final client = MockClient((_) async => throw http.ClientException('connection reset'));

      await openSheet(tester, client: client);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Save changes'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.textContaining('Unable to connect'), findsOneWidget);
    });
  });
}
