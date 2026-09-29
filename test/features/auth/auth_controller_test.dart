import 'package:flutter_test/flutter_test.dart';
import 'package:agriflow_admin/core/models/user_role.dart';
import 'package:agriflow_admin/features/auth/domain/entities/auth_exception.dart';
import 'package:agriflow_admin/features/auth/domain/entities/auth_session.dart';
import 'package:agriflow_admin/features/auth/domain/entities/auth_user.dart';
import 'package:agriflow_admin/features/auth/domain/repositories/auth_repository.dart';
import 'package:agriflow_admin/features/auth/presentation/controllers/auth_controller.dart';
import 'package:agriflow_admin/features/auth/presentation/controllers/auth_state.dart';

class MockAuthRepository implements AuthRepository {
  AuthSession? mockSession;
  AuthException? mockError;
  bool logoutCalled = false;

  @override
  Future<AuthSession> login({
    required String phone,
    required String password,
    bool rememberMe = true,
  }) async {
    if (mockError != null) throw mockError!;
    return mockSession!;
  }

  @override
  Future<AuthSession?> restoreSession() async {
    if (mockError != null) throw mockError!;
    return mockSession;
  }

  @override
  Future<void> logout() async {
    logoutCalled = true;
    mockSession = null;
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
    return mockSession!.user;
  }
}

void main() {
  late MockAuthRepository mockRepo;
  late AuthController controller;

  final adminUser = AuthUser(
    id: 'user-admin-1',
    name: 'Siva Sai Admin',
    phone: '9999999999',
    role: UserRole.superAdmin,
    status: 'active',
  );

  final adminSession = AuthSession(
    accessToken: 'admin_jwt',
    refreshToken: 'admin_refresh',
    user: adminUser,
  );

  final farmerUser = AuthUser(
    id: 'user-farmer-1',
    name: 'Ramesh Farmer',
    phone: '9123456780',
    role: UserRole.unsupported,
    status: 'active',
  );

  final farmerSession = AuthSession(
    accessToken: 'farmer_jwt',
    refreshToken: 'farmer_refresh',
    user: farmerUser,
  );

  setUp(() {
    mockRepo = MockAuthRepository();
    controller = AuthController(repository: mockRepo);
  });

  group('AuthController State Machine Tests', () {
    test('initial state is AuthStatus.initial', () {
      expect(controller.state.status, equals(AuthStatus.initial));
      expect(controller.currentSession, isNull);
      expect(controller.currentRole, isNull);
    });

    test('restoreSession transitions to authenticated when valid session exists', () async {
      mockRepo.mockSession = adminSession;

      await controller.restoreSession();

      expect(controller.state.status, equals(AuthStatus.authenticated));
      expect(controller.currentSession, equals(adminSession));
      expect(controller.currentRole, equals(UserRole.superAdmin));
      expect(controller.currentRole!.isAdmin, isTrue);
    });

    test('restoreSession transitions to unauthenticated when no session exists', () async {
      mockRepo.mockSession = null;

      await controller.restoreSession();

      expect(controller.state.status, equals(AuthStatus.unauthenticated));
      expect(controller.currentSession, isNull);
    });

    test('restoreSession transitions to unsupportedRole if role is unauthorized (farmer)', () async {
      mockRepo.mockSession = farmerSession;

      await controller.restoreSession();

      expect(controller.state.status, equals(AuthStatus.unsupportedRole));
      expect(controller.currentRole, isNull); // Strict: No Manager access!
    });

    test('login transitions to authenticated upon valid credentials', () async {
      mockRepo.mockSession = adminSession;

      final success = await controller.login(
        phone: '9999999999',
        password: 'ValidPassword123',
      );

      expect(success, isTrue);
      expect(controller.state.status, equals(AuthStatus.authenticated));
      expect(controller.currentRole, equals(UserRole.superAdmin));
    });

    test('login transitions to authenticationFailure when backend returns 401', () async {
      mockRepo.mockError = const AuthException(
        message: 'Invalid phone number or password',
        statusCode: 401,
        errorCode: 'UNAUTHORIZED',
      );

      final success = await controller.login(
        phone: '9999999999',
        password: 'WrongPassword',
      );

      expect(success, isFalse);
      expect(controller.state.status, equals(AuthStatus.authenticationFailure));
      expect(controller.state.errorMessage, equals('Invalid phone number or password'));
      expect(controller.currentSession, isNull);
    });

    test('login transitions to unsupportedRole when user possesses unauthorized role', () async {
      mockRepo.mockSession = farmerSession;

      final success = await controller.login(
        phone: '9123456780',
        password: 'FarmerPassword123',
      );

      expect(success, isFalse);
      expect(controller.state.status, equals(AuthStatus.unsupportedRole));
      expect(controller.currentRole, isNull);
    });

    test('logout clears session and resets state to unauthenticated', () async {
      mockRepo.mockSession = adminSession;
      await controller.restoreSession();
      expect(controller.state.status, equals(AuthStatus.authenticated));

      await controller.logout();

      expect(mockRepo.logoutCalled, isTrue);
      expect(controller.state.status, equals(AuthStatus.unauthenticated));
      expect(controller.currentSession, isNull);
      expect(controller.currentRole, isNull);
    });
  });
}
