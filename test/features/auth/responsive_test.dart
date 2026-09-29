import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agriflow_admin/features/auth/domain/entities/auth_session.dart';
import 'package:agriflow_admin/features/auth/domain/entities/auth_user.dart';
import 'package:agriflow_admin/features/auth/domain/repositories/auth_repository.dart';
import 'package:agriflow_admin/features/auth/presentation/controllers/auth_controller.dart';
import 'package:agriflow_admin/features/auth/presentation/screens/splash_screen.dart';
import 'package:agriflow_admin/features/auth/presentation/screens/login_screen.dart';

class MockAuthRepo implements AuthRepository {
  @override
  Future<AuthSession?> restoreSession() async => null;

  @override
  Future<AuthSession> login({
    required String phone,
    required String password,
    bool rememberMe = true,
  }) async => throw UnimplementedError();

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
  Future<AuthUser> getCurrentUser({required String accessToken}) async => throw UnimplementedError();
}

void main() {
  group('Android Form-Factor & Responsive Layout Tests', () {
    final phoneDimensions = [
      {'name': 'Small Android (360x640)', 'size': const Size(360, 640)},
      {'name': 'Standard Android (412x860)', 'size': const Size(412, 860)},
      {'name': 'Tall Android (412x960)', 'size': const Size(412, 960)},
      {'name': 'Compact Android (320x568)', 'size': const Size(320, 568)},
    ];

    for (final dim in phoneDimensions) {
      testWidgets('Startup screen renders cleanly without overflow on ${dim['name']}', (tester) async {
        final size = dim['size'] as Size;
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final controller = AuthController(repository: MockAuthRepo());

        await tester.pumpWidget(
          MaterialApp(
            home: SplashScreen(authController: controller),
          ),
        );
        await tester.pump();

        // Verify elements are visible
        expect(find.text('Sri Siva Sai Seeds'), findsOneWidget);
        expect(find.text('ADMIN CONSOLE'), findsOneWidget);
        expect(find.text('Tap anywhere to continue'), findsOneWidget);

        // Verify no RenderFlex overflow
        expect(tester.takeException(), isNull);
      });

      testWidgets('Login screen renders cleanly without overflow on ${dim['name']}', (tester) async {
        final size = dim['size'] as Size;
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final controller = AuthController(repository: MockAuthRepo());

        await tester.pumpWidget(
          MaterialApp(
            home: LoginScreen(authController: controller),
          ),
        );
        await tester.pump();

        // Verify elements are visible
        expect(find.text('Sri Siva Sai Seeds Admin Console'), findsOneWidget);
        expect(find.text('Log in'), findsOneWidget);

        // Verify no RenderFlex overflow
        expect(tester.takeException(), isNull);
      });
    }
  });
}
