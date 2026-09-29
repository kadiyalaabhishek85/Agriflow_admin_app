import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agriflow_admin/core/widgets/squircle_icon_button.dart';
import 'package:agriflow_admin/features/settings/data/notification_preferences.dart';
import 'package:agriflow_admin/features/settings/presentation/screens/settings_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpSettings(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
    await tester.pumpAndSettle();
  }

  group('M10 Settings screen (AdminMobile UIUX #screen-settings)', () {
    testWidgets('Renders header, three notification toggles and version footer', (tester) async {
      await pumpSettings(tester);

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Push notifications'), findsOneWidget);
      expect(find.text('Email alerts'), findsOneWidget);
      expect(find.text('SMS alerts for urgent items'), findsOneWidget);
      expect(
        find.text('Sri Siva Sai Seeds Admin Console v1.0.0'),
        findsOneWidget,
      );

      final switches = find.byType(Switch);
      expect(switches, findsNWidgets(3));
      // HTML defaults: push ON, email ON, SMS OFF.
      expect(tester.widget<Switch>(switches.at(0)).value, isTrue);
      expect(tester.widget<Switch>(switches.at(1)).value, isTrue);
      expect(tester.widget<Switch>(switches.at(2)).value, isFalse);
    });

    testWidgets('Toggling a switch persists to shared preferences', (tester) async {
      await pumpSettings(tester);

      final switches = find.byType(Switch);
      await tester.tap(switches.at(2)); // SMS: OFF -> ON
      await tester.pumpAndSettle();

      final loaded = await NotificationPreferences.load();
      expect(loaded[NotificationPreferences.smsKey], isTrue);
      expect(tester.widget<Switch>(switches.at(2)).value, isTrue);

      await tester.tap(switches.at(0)); // Push: ON -> OFF
      await tester.pumpAndSettle();
      final reloaded = await NotificationPreferences.load();
      expect(reloaded[NotificationPreferences.pushKey], isFalse);
    });

    testWidgets('Terms of service row opens the static legal document', (tester) async {
      await pumpSettings(tester);

      await tester.tap(find.text('Terms of service'));
      await tester.pumpAndSettle();

      expect(find.text('Terms of Service'), findsOneWidget);
      expect(
        find.textContaining('authorized personnel of Sri Siva Sai Seeds'),
        findsOneWidget,
      );
      expect(find.textContaining('logged and auditable'), findsOneWidget);
    });

    testWidgets('Privacy policy row opens the static legal document', (tester) async {
      await pumpSettings(tester);

      await tester.tap(find.text('Privacy policy'));
      await tester.pumpAndSettle();

      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(
        find.textContaining('confidential and must not be shared'),
        findsOneWidget,
      );
    });

    testWidgets('Back button pops the pushed settings route', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(ctx).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
                child: const Text('open-settings'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('open-settings'));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);

      await tester.tap(find.byType(SquircleIconButton));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsNothing);
      expect(find.text('open-settings'), findsOneWidget);
    });
  });
}
