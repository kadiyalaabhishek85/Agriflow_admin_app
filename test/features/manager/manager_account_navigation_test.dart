import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agriflow_admin/core/models/user_role.dart';
import 'package:agriflow_admin/core/widgets/module_placeholder_screen.dart';
import 'package:agriflow_admin/features/account/presentation/screens/account_screen.dart';
import 'package:agriflow_admin/features/auth/domain/entities/auth_session.dart';
import 'package:agriflow_admin/features/auth/domain/entities/auth_user.dart';
import 'package:agriflow_admin/features/manager/presentation/manager_shell.dart';

void main() {
  group('Manager Account Navigation Tests (ISSUE-P1-03)', () {
    const testSession = AuthSession(
      accessToken: 'test_token',
      refreshToken: 'test_refresh',
      tokenType: 'bearer',
      user: AuthUser(
        id: 'mgr-1',
        name: 'Manager Ravi',
        phone: '9876543210',
        email: 'ravi@agriflow.com',
        role: UserRole.manager,
        status: 'active',
      ),
    );

    testWidgets('Tapping Account bottom navigation tab resolves to AccountScreen, NOT placeholder', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ManagerShell(
            session: testSession,
            onLogout: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find Account tab in bottom nav (5th item, index 4)
      final accountTab = find.byIcon(Icons.person_outline_rounded);
      expect(accountTab, findsOneWidget);

      await tester.tap(accountTab);
      await tester.pumpAndSettle();

      // Must resolve to real AccountScreen
      expect(find.byType(AccountScreen), findsOneWidget);
      expect(find.byType(ModulePlaceholderScreen), findsNothing);

      // Verify AccountScreen contents
      expect(find.text('Manager Ravi'), findsWidgets);
      expect(find.text('ravi@agriflow.com'), findsWidgets);
      expect(find.text('Change Password'), findsOneWidget);
      expect(find.text('ACTIVE'), findsOneWidget);

      // Test tapping back button returns to Dashboard
      final backButton = find.byIcon(Icons.arrow_back_rounded);
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton.first);
        await tester.pumpAndSettle();
        expect(find.byType(AccountScreen), findsNothing);
      }
    });

    testWidgets('AccountScreen logout button triggers logout callback', (tester) async {
      bool logoutCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: ManagerShell(
            session: testSession,
            onLogout: () {
              logoutCalled = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Account
      final accountTab = find.byIcon(Icons.person_outline_rounded);
      await tester.tap(accountTab);
      await tester.pumpAndSettle();

      expect(find.byType(AccountScreen), findsOneWidget);

      // Scroll down to find Log Out button
      final logoutBtn = find.text('Log Out of Account');
      expect(logoutBtn, findsOneWidget);
      await tester.ensureVisible(logoutBtn);
      await tester.tap(logoutBtn);
      await tester.pumpAndSettle();

      // Dialog confirmation
      final confirmLogoutBtn = find.widgetWithText(ElevatedButton, 'Log Out');
      expect(confirmLogoutBtn, findsOneWidget);
      await tester.tap(confirmLogoutBtn);
      await tester.pumpAndSettle();

      expect(logoutCalled, isTrue);
    });
  });
}
