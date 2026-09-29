import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agriflow_admin/core/widgets/squircle_icon_button.dart';
import 'package:agriflow_admin/features/help/presentation/screens/help_screen.dart';

void main() {
  group('M10 Help & Support screen (AdminMobile UIUX #screen-help)', () {
    testWidgets('Renders support card with helpline number', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HelpScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Help & Support'), findsOneWidget);
      expect(find.text('Contact Support'), findsOneWidget);
      expect(
        find.text('Call us at +91 9502662924 for any assistance.'),
        findsOneWidget,
      );
    });

    testWidgets('Renders all three FAQ questions', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HelpScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Frequently asked'), findsOneWidget);
      expect(find.textContaining('How do I approve a seed request?'), findsOneWidget);
      expect(find.textContaining('How do I create a new visit slot?'), findsOneWidget);
      expect(find.textContaining('How do I mark a grain sale as paid?'), findsOneWidget);
      expect(HelpScreen.faqQuestions, hasLength(3));
    });

    testWidgets('Back button pops a pushed help route', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(ctx).push(
                  MaterialPageRoute(builder: (_) => const HelpScreen()),
                ),
                child: const Text('open-help'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('open-help'));
      await tester.pumpAndSettle();
      expect(find.byType(HelpScreen), findsOneWidget);

      await tester.tap(find.byType(SquircleIconButton));
      await tester.pumpAndSettle();
      expect(find.byType(HelpScreen), findsNothing);
      expect(find.text('open-help'), findsOneWidget);
    });
  });
}
