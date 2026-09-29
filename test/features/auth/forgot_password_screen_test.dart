import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agriflow_admin/features/auth/domain/entities/auth_session.dart';
import 'package:agriflow_admin/features/auth/domain/entities/auth_user.dart';
import 'package:agriflow_admin/features/auth/domain/repositories/auth_repository.dart';
import 'package:agriflow_admin/features/auth/presentation/controllers/auth_controller.dart';
import 'package:agriflow_admin/features/auth/presentation/screens/forgot_password_screen.dart';

class MockAuthRepository implements AuthRepository {
  int sendOtpCallCount = 0;
  int resetPasswordCallCount = 0;
  String? lastSentPhone;

  @override
  Future<AuthSession> login({
    required String phone,
    required String password,
    bool rememberMe = true,
  }) =>
      throw UnimplementedError();

  @override
  Future<AuthSession?> restoreSession() async => null;

  @override
  Future<void> logout() async {}

  @override
  Future<void> requestPasswordResetOtp({required String phone}) async {
    sendOtpCallCount++;
    lastSentPhone = phone;
  }

  @override
  Future<void> resetPasswordWithOtp({
    required String phone,
    required String code,
    required String newPassword,
  }) async {
    resetPasswordCallCount++;
  }

  @override
  Future<AuthUser> getCurrentUser({required String accessToken}) =>
      throw UnimplementedError();
}

void main() {
  group('Forgot Password OTP Cooldown Persistence Tests (ISSUE-P2-04)', () {
    late MockAuthRepository mockRepo;
    late AuthController authController;

    setUp(() {
      mockRepo = MockAuthRepository();
      authController = AuthController(repository: mockRepo);
    });

    testWidgets('Initial send starts 60-second cooldown and persists timestamp in SharedPreferences', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        MaterialApp(
          home: ForgotPasswordScreen(
            authController: authController,
            initialPhone: '9876543210',
            prefs: prefs,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final sendBtn = find.text('Send Reset OTP Code');
      expect(sendBtn, findsOneWidget);

      await tester.tap(sendBtn);
      await tester.pumpAndSettle();

      expect(mockRepo.sendOtpCallCount, 1);
      expect(mockRepo.lastSentPhone, '9876543210');

      // Verify timestamp is persisted
      final savedTs = prefs.getInt(ForgotPasswordScreen.otpTimestampKey);
      expect(savedTs, isNotNull);

      // Verify cooldown text appears
      expect(find.textContaining('Resend OTP in'), findsOneWidget);
    });

    testWidgets('Screen re-entry preserves active cooldown and calculates remaining time', (tester) async {
      // Simulate that OTP was sent 20 seconds ago (40 seconds remaining)
      final twentySecondsAgo = DateTime.now().millisecondsSinceEpoch - 20000;
      SharedPreferences.setMockInitialValues({
        ForgotPasswordScreen.otpTimestampKey: twentySecondsAgo,
        ForgotPasswordScreen.otpPhoneKey: '9876543210',
      });
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        MaterialApp(
          home: ForgotPasswordScreen(
            authController: authController,
            prefs: prefs,
          ),
        ),
      );
      // Let _initCooldown complete
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Should show cooldown remaining (~39 or 40s) and resend should be disabled
      expect(find.textContaining('Resend OTP in 40s'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Resend OTP'), findsNothing);
    });

    testWidgets('Expired cooldown timestamp (> 60s) enables resend and clears stale timestamp', (tester) async {
      // Simulate that OTP was sent 90 seconds ago (expired)
      final ninetySecondsAgo = DateTime.now().millisecondsSinceEpoch - 90000;
      SharedPreferences.setMockInitialValues({
        ForgotPasswordScreen.otpTimestampKey: ninetySecondsAgo,
      });
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        MaterialApp(
          home: ForgotPasswordScreen(
            authController: authController,
            initialPhone: '9876543210',
            prefs: prefs,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Cooldown expired: Send button is enabled
      final sendBtn = find.text('Send Reset OTP Code');
      expect(sendBtn, findsOneWidget);

      // Expired timestamp is cleaned up from prefs
      expect(prefs.getInt(ForgotPasswordScreen.otpTimestampKey), isNull);
    });

    testWidgets('Corrupted or invalid timestamp is handled safely without crashing', (tester) async {
      // Timestamp in the distant future or negative
      SharedPreferences.setMockInitialValues({
        ForgotPasswordScreen.otpTimestampKey: -999999999,
      });
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        MaterialApp(
          home: ForgotPasswordScreen(
            authController: authController,
            initialPhone: '9876543210',
            prefs: prefs,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Screen opens normally and allows sending OTP
      final sendBtn = find.text('Send Reset OTP Code');
      expect(sendBtn, findsOneWidget);
    });
  });
}
