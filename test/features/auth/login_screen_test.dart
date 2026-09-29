import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agriflow_admin/features/auth/domain/entities/auth_exception.dart';
import 'package:agriflow_admin/features/auth/domain/entities/auth_session.dart';
import 'package:agriflow_admin/features/auth/domain/entities/auth_user.dart';
import 'package:agriflow_admin/features/auth/domain/repositories/auth_repository.dart';
import 'package:agriflow_admin/features/auth/presentation/controllers/auth_controller.dart';
import 'package:agriflow_admin/features/auth/presentation/screens/login_screen.dart';

class TestAuthRepository implements AuthRepository {
  AuthException? errorToThrow;
  String? lastPhone;
  String? lastPassword;

  @override
  Future<AuthSession> login({
    required String phone,
    required String password,
    bool rememberMe = true,
  }) async {
    lastPhone = phone;
    lastPassword = password;
    if (errorToThrow != null) throw errorToThrow!;
    throw UnimplementedError();
  }

  @override
  Future<AuthSession?> restoreSession() async => null;

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
  late TestAuthRepository testRepo;
  late AuthController controller;

  setUp(() {
    testRepo = TestAuthRepository();
    controller = AuthController(repository: testRepo);
  });

  Widget buildLoginScreen() {
    return MaterialApp(
      home: LoginScreen(authController: controller),
    );
  }

  group('LoginScreen UI & Validation Widget Tests', () {
    testWidgets('renders all expected HTML #flow-login visual components with approved logo', (tester) async {
      await tester.pumpWidget(buildLoginScreen());

      // 1. Text elements
      expect(find.text('Sri Siva Sai Seeds Admin Console'), findsOneWidget);
      expect(find.text('Sign in to manage operations for Sri Siva Sai Seeds'), findsOneWidget);
      expect(find.text('Mobile number'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Remember me on this device'), findsOneWidget);
      expect(find.text('Log in'), findsOneWidget);
      expect(find.text('Forgot password? Call us for help'), findsOneWidget);

      // 2. Approved Sri Siva Sai Seeds logo asset
      final logoFinder = find.byWidgetPredicate((widget) {
        if (widget is Image && widget.image is AssetImage) {
          return (widget.image as AssetImage).assetName ==
              'assets/images/sri_siva_sai_seeds_logo.png';
        }
        return false;
      });
      expect(logoFinder, findsOneWidget);

      // 3. Generic leaf icons MUST NOT exist as branding
      expect(find.byIcon(Icons.eco_rounded), findsNothing);
      expect(find.byIcon(Icons.eco), findsNothing);
    });

    testWidgets('validates empty inputs on submit', (tester) async {
      await tester.pumpWidget(buildLoginScreen());

      await tester.tap(find.text('Log in'));
      await tester.pumpAndSettle();

      expect(find.text('Mobile number is required.'), findsOneWidget);
      expect(find.text('Password is required.'), findsOneWidget);
    });

    testWidgets('validates 10-digit mobile number format strictly matching FastAPI contract', (tester) async {
      await tester.pumpWidget(buildLoginScreen());

      final inputs = find.byType(TextFormField);
      await tester.enterText(inputs.first, '12345'); // invalid length
      await tester.enterText(inputs.last, 'Password123');

      await tester.tap(find.text('Log in'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid 10-digit mobile number.'), findsOneWidget);
    });

    testWidgets('validates password minimum length of 6 characters', (tester) async {
      await tester.pumpWidget(buildLoginScreen());

      final inputs = find.byType(TextFormField);
      await tester.enterText(inputs.first, '9876543210');
      await tester.enterText(inputs.last, '123'); // < 6 chars

      await tester.tap(find.text('Log in'));
      await tester.pumpAndSettle();

      expect(find.text('Password must be at least 6 characters.'), findsOneWidget);
    });

    testWidgets('toggles password visibility when eye icon is clicked', (tester) async {
      await tester.pumpWidget(buildLoginScreen());

      // Find eye icon
      final eyeButton = find.byIcon(Icons.visibility_outlined);
      expect(eyeButton, findsOneWidget);

      await tester.tap(eyeButton);
      await tester.pump();

      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });

    testWidgets('displays error banner cleanly when authentication fails', (tester) async {
      testRepo.errorToThrow = const AuthException(
        message: 'Invalid phone number or password',
        statusCode: 401,
        errorCode: 'UNAUTHORIZED',
      );

      await tester.pumpWidget(buildLoginScreen());

      final inputs = find.byType(TextFormField);
      await tester.enterText(inputs.first, '9999999999');
      await tester.enterText(inputs.last, 'WrongPassword123');

      await tester.tap(find.text('Log in'));
      await tester.pumpAndSettle();

      expect(find.text('Invalid phone number or password'), findsOneWidget);
    });
  });
}
