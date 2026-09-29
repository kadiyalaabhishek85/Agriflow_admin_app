import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agriflow_admin/features/auth/domain/entities/auth_session.dart';
import 'package:agriflow_admin/features/auth/domain/entities/auth_user.dart';
import 'package:agriflow_admin/features/auth/domain/repositories/auth_repository.dart';
import 'package:agriflow_admin/features/auth/presentation/controllers/auth_controller.dart';
import 'package:agriflow_admin/features/auth/presentation/screens/splash_screen.dart';

class SplashTestAuthRepository implements AuthRepository {
  int restoreSessionCallCount = 0;
  Completer<AuthSession?>? completer;

  @override
  Future<AuthSession?> restoreSession() async {
    restoreSessionCallCount++;
    if (completer != null) {
      return completer!.future;
    }
    return null;
  }

  @override
  Future<AuthSession> login({
    required String phone,
    required String password,
    bool rememberMe = true,
  }) async {
    throw UnimplementedError();
  }

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
  Future<AuthUser> getCurrentUser({required String accessToken}) async {
    throw UnimplementedError();
  }
}

void main() {
  group('SplashScreen / Android Startup Screen Tests', () {
    testWidgets('Startup screen renders all approved visual elements with real logo', (tester) async {
      final repo = SplashTestAuthRepository();
      final controller = AuthController(repository: repo);

      await tester.pumpWidget(
        MaterialApp(
          home: SplashScreen(authController: controller),
        ),
      );

      // 1. Brand Title
      expect(find.text('Sri Siva Sai Seeds'), findsOneWidget);

      // 2. Admin Badge with Shield
      expect(find.text('ADMIN CONSOLE'), findsOneWidget);
      expect(find.byIcon(Icons.shield_outlined), findsOneWidget);

      // 3. Tap to continue hint
      expect(find.text('Tap anywhere to continue'), findsOneWidget);

      // 4. Exact logo asset verification
      final logoFinder = find.byWidgetPredicate((widget) {
        if (widget is Image && widget.image is AssetImage) {
          return (widget.image as AssetImage).assetName ==
              'assets/images/sri_siva_sai_seeds_logo.png';
        }
        return false;
      });
      expect(logoFinder, findsOneWidget);

      // 5. Generic leaf icon MUST NOT exist
      expect(find.byIcon(Icons.eco_rounded), findsNothing);
      expect(find.byIcon(Icons.eco), findsNothing);
    });

    testWidgets('No automatic session restoration occurs before interaction (no auto-bypass)', (tester) async {
      final repo = SplashTestAuthRepository();
      final controller = AuthController(repository: repo);

      await tester.pumpWidget(
        MaterialApp(
          home: SplashScreen(authController: controller),
        ),
      );

      // Wait frames without touching
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Startup remains mounted and no session restoration was triggered
      expect(find.text('Sri Siva Sai Seeds'), findsOneWidget);
      expect(repo.restoreSessionCallCount, 0);
    });

    testWidgets('Tapping startup screen triggers session restoration flow', (tester) async {
      final repo = SplashTestAuthRepository();
      final controller = AuthController(repository: repo);

      await tester.pumpWidget(
        MaterialApp(
          home: SplashScreen(authController: controller),
        ),
      );

      expect(repo.restoreSessionCallCount, 0);

      // User taps anywhere on the screen
      await tester.tap(find.byType(SplashScreen));
      await tester.pump();

      // Session restoration was called exactly once
      expect(repo.restoreSessionCallCount, 1);
    });

    testWidgets('Repeated taps do not trigger duplicate restoration while in progress', (tester) async {
      final repo = SplashTestAuthRepository();
      repo.completer = Completer<AuthSession?>(); // Keeps restoration pending
      final controller = AuthController(repository: repo);

      await tester.pumpWidget(
        MaterialApp(
          home: SplashScreen(authController: controller),
        ),
      );

      // First tap initiates restoration
      await tester.tap(find.byType(SplashScreen));
      await tester.pump();
      expect(repo.restoreSessionCallCount, 1);
      expect(controller.state.isSessionRestoring, isTrue);

      // Repeated taps while sessionRestoring
      await tester.tap(find.byType(SplashScreen));
      await tester.pump();
      await tester.tap(find.byType(SplashScreen));
      await tester.pump();

      // Call count must remain 1 (no duplicate calls)
      expect(repo.restoreSessionCallCount, 1);

      // Complete the pending restoration
      repo.completer!.complete(null);
      await tester.pumpAndSettle();
    });

    testWidgets('Session restoring state keeps Startup visible with progress indicator', (tester) async {
      final repo = SplashTestAuthRepository();
      repo.completer = Completer<AuthSession?>();
      final controller = AuthController(repository: repo);

      await tester.pumpWidget(
        MaterialApp(
          home: SplashScreen(authController: controller),
        ),
      );

      // Tap screen
      await tester.tap(find.byType(SplashScreen));
      await tester.pump();

      // Verify Startup screen remains visible and shows progress indicator
      expect(find.text('Sri Siva Sai Seeds'), findsOneWidget);
      expect(find.text('ADMIN CONSOLE'), findsOneWidget);
      expect(find.text('Session restoring...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Complete restoration
      repo.completer!.complete(null);
      await tester.pumpAndSettle();
    });
  });
}
