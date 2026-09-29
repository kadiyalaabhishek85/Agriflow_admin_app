// LIVE end-to-end verification of the super_admin credentials through the
// Admin mobile app's OWN networking/parsing code (no mocks on the network layer).
//
// Run with:  flutter test scratch/live_admin_login_e2e_test.dart
//
// This file lives outside test/ on purpose so that the normal `flutter test`
// suite stays fully offline and deterministic.
import 'package:flutter_test/flutter_test.dart';
import 'package:agriflow_admin/core/models/user_role.dart';
import 'package:agriflow_admin/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:agriflow_admin/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:agriflow_admin/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:agriflow_admin/features/auth/domain/entities/auth_exception.dart';
import 'package:agriflow_admin/features/auth/domain/entities/auth_session.dart';
import 'package:agriflow_admin/features/auth/domain/entities/auth_user.dart';
import 'package:agriflow_admin/features/auth/presentation/controllers/auth_controller.dart';

/// In-memory stand-in for SharedPreferencesAuthLocalDataSource.
class InMemoryAuthLocalDataSource implements AuthLocalDataSource {
  AuthSession? _session;
  bool _remembered = true;

  @override
  Future<void> saveSession(AuthSession session, {bool rememberMe = true}) async {
    _session = session;
    _remembered = rememberMe;
  }

  @override
  Future<AuthSession?> getSession() async => _session;

  @override
  Future<String?> getAccessToken() async => _session?.accessToken;

  @override
  Future<String?> getRefreshToken() async => _session?.refreshToken;

  @override
  Future<void> updateTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _session = _session?.copyWith(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  @override
  Future<void> updateUser(AuthUser user) async {
    _session = _session?.copyWith(user: user);
  }

  @override
  Future<void> clearSession() async {
    _session = null;
  }

  @override
  Future<bool> isRemembered() async => _remembered;
}

void main() {
  // Credentials supplied by the backend developer for the mobile app.
  const phone = '9999900000';
  const password = 'Admin12345';

  final remote = FastApiAuthRemoteDataSource();
  final local = InMemoryAuthLocalDataSource();
  final repository = AuthRepositoryImpl(
    localDataSource: local,
    remoteDataSource: remote,
  );

  group('LIVE backend: super_admin login through the app code path', () {
    test('POST /api/v1/auth/login authenticates 9999900000 / Admin12345', () async {
      final session = await remote.login(phone: phone, password: password);

      expect(session.accessToken, isNotEmpty);
      expect(session.refreshToken, isNotEmpty);
      expect(session.tokenType.toLowerCase(), equals('bearer'));
      expect(session.expiresIn, greaterThan(0));

      // User payload assertions
      expect(session.user.id, isNotEmpty);
      expect(session.user.phone, equals(phone));
      expect(session.user.role, equals(UserRole.superAdmin));
      expect(session.user.role.isSupported, isTrue);
      expect(session.user.role.isAdmin, isTrue);
      expect(session.user.role.isSuperAdmin, isTrue);

      // ignore: avoid_print
      print('[LIVE] role=${session.user.role.name} '
          'displayLabel=${session.user.role.displayLabel} '
          'console=${session.user.role.consoleTitle} '
          'name=${session.user.name} email=${session.user.email} '
          'status=${session.user.status} firstLogin=${session.user.firstLogin} '
          'createdAt=${session.user.createdAt} expiresIn=${session.expiresIn}s');
    });

    test('repository login persists session locally and controller routes to Admin console', () async {
      final controller = AuthController(repository: repository);
      final ok = await controller.login(phone: phone, password: password);

      expect(ok, isTrue, reason: 'login() should succeed for the supplied super_admin credentials');
      expect(controller.currentRole, equals(UserRole.superAdmin));
      expect(controller.currentRole!.consoleTitle, equals('Admin Console'));

      // Session was persisted locally and is restorable.
      final persisted = await local.getSession();
      expect(persisted, isNotNull);
      expect(persisted!.user.phone, equals(phone));
      expect(persisted.user.role, equals(UserRole.superAdmin));
      expect(persisted.accessToken, isNotEmpty);
    });

    test('GET /api/v1/users/me validates the issued access token', () async {
      final session = await remote.login(phone: phone, password: password);
      final me = await remote.getMe(accessToken: session.accessToken);

      expect(me.phone, equals(phone));
      expect(me.role, equals(UserRole.superAdmin));
      expect(me.role.isSupported, isTrue);

      // ignore: avoid_print
      print('[LIVE] /users/me -> id=${me.id} role=${me.role.name} status=${me.status}');
    });

    test('wrong password is rejected with 401 UNAUTHORIZED', () async {
      await expectLater(
        remote.login(phone: phone, password: 'DefinitelyWrong123'),
        throwsA(
          isA<AuthException>()
              .having((e) => e.statusCode, 'statusCode', 401)
              .having((e) => e.errorCode, 'errorCode', 'UNAUTHORIZED'),
        ),
      );
    });
  });
}
