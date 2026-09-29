import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agriflow_admin/core/models/user_role.dart';
import 'package:agriflow_admin/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:agriflow_admin/features/auth/domain/entities/auth_session.dart';
import 'package:agriflow_admin/features/auth/domain/entities/auth_user.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late SharedPreferencesAuthLocalDataSource dataSource;

  final testUser = AuthUser(
    id: '123e4567-e89b-12d3-a456-426614174000',
    name: 'Admin User',
    phone: '9999999999',
    email: 'admin@srisivasaiseeds.com',
    role: UserRole.superAdmin,
    status: 'active',
  );

  final testSession = AuthSession(
    accessToken: 'test_access_jwt',
    refreshToken: 'test_refresh_jwt',
    tokenType: 'bearer',
    expiresIn: 3600,
    user: testUser,
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    dataSource = SharedPreferencesAuthLocalDataSource(prefs);
  });

  group('AuthLocalDataSource Tests', () {
    test('saveSession persists tokens and user session data', () async {
      await dataSource.saveSession(testSession, rememberMe: true);

      expect(await dataSource.getAccessToken(), equals('test_access_jwt'));
      expect(await dataSource.getRefreshToken(), equals('test_refresh_jwt'));
      expect(await dataSource.isRemembered(), isTrue);

      final restored = await dataSource.getSession();
      expect(restored, isNotNull);
      expect(restored!.accessToken, equals('test_access_jwt'));
      expect(restored.user.name, equals('Admin User'));
      expect(restored.user.role, equals(UserRole.superAdmin));
    });

    test('clearSession removes all stored auth data', () async {
      await dataSource.saveSession(testSession);
      await dataSource.clearSession();

      expect(await dataSource.getAccessToken(), isNull);
      expect(await dataSource.getRefreshToken(), isNull);
      expect(await dataSource.getSession(), isNull);
    });

    test('updateTokens modifies access and refresh tokens without corrupting user info', () async {
      await dataSource.saveSession(testSession);
      await dataSource.updateTokens(
        accessToken: 'new_access_jwt',
        refreshToken: 'new_refresh_jwt',
      );

      final updated = await dataSource.getSession();
      expect(updated!.accessToken, equals('new_access_jwt'));
      expect(updated.refreshToken, equals('new_refresh_jwt'));
      expect(updated.user.name, equals('Admin User'));
    });

    test('security verification: plaintext passwords are never persisted in SharedPreferences', () async {
      await dataSource.saveSession(testSession);

      final allKeys = prefs.getKeys();
      for (final key in allKeys) {
        final val = prefs.get(key).toString().toLowerCase();
        expect(val.contains('password'), isFalse);
      }
    });
  });
}
