import 'package:flutter_test/flutter_test.dart';
import 'package:agriflow_admin/core/models/user_role.dart';

void main() {
  group('Role Resolution & Mapping Tests', () {
    test('maps FastAPI super_admin role to superAdmin with admin privileges', () {
      final role = UserRole.fromString('super_admin');
      expect(role, equals(UserRole.superAdmin));
      expect(role.isAdmin, isTrue);
      expect(role.isSuperAdmin, isTrue);
      expect(role.isManager, isFalse);
      expect(role.isSupported, isTrue);
      expect(role.consoleTitle, equals('Admin Console'));
      expect(role.displayLabel, equals('Super Admin'));
    });

    test('maps FastAPI manager role to manager', () {
      final role = UserRole.fromString('manager');
      expect(role, equals(UserRole.manager));
      expect(role.isManager, isTrue);
      expect(role.isAdmin, isFalse);
      expect(role.isSuperAdmin, isFalse);
      expect(role.isSupported, isTrue);
      expect(role.consoleTitle, equals('Manager Console'));
      expect(role.displayLabel, equals('Manager'));
    });

    test('maps admin role to admin with administrative privileges', () {
      final role = UserRole.fromString('admin');
      expect(role, equals(UserRole.admin));
      expect(role.isAdmin, isTrue);
      expect(role.isManager, isFalse);
      expect(role.isSupported, isTrue);
      expect(role.consoleTitle, equals('Admin Console'));
    });

    test('explicitly marks farmer as unsupported for Admin/Manager console', () {
      final role = UserRole.fromString('farmer');
      expect(role, equals(UserRole.unsupported));
      expect(role.isSupported, isFalse);
      expect(role.isAdmin, isFalse);
      expect(role.isManager, isFalse);
      expect(role.consoleTitle, equals('Access Denied'));
    });

    test('explicitly marks null and unknown roles as unsupported without defaulting to Manager', () {
      expect(UserRole.fromString(null), equals(UserRole.unsupported));
      expect(UserRole.fromString(''), equals(UserRole.unsupported));
      expect(UserRole.fromString('guest'), equals(UserRole.unsupported));
      expect(UserRole.fromString('random_role'), equals(UserRole.unsupported));
      expect(UserRole.fromString(null).isManager, isFalse);
      expect(UserRole.fromString('unknown').isManager, isFalse);
    });
  });
}
