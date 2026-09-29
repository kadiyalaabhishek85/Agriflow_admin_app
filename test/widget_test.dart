import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agriflow_admin/app.dart';
import 'package:agriflow_admin/core/widgets/status_pill.dart';
import 'package:agriflow_admin/core/widgets/squircle_icon_button.dart';

void main() {
  testWidgets('AgriFlowApp foundation smoke test and role switching', (WidgetTester tester) async {
    // Set a phone-like viewport size for testing
    tester.view.physicalSize = const Size(412, 860);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const AgriFlowApp(showcaseMode: true));
    await tester.pump();


    // 1. Verify Manager initial state (Manager Console title, 5 bottom tabs)
    expect(find.text('MILESTONE 1 VERIFIED'), findsOneWidget);
    expect(find.text('MANAGER CONSOLE'), findsOneWidget);
    expect(find.text('Manager Role'), findsOneWidget);
    expect(find.text('Admin Role'), findsOneWidget);
    expect(find.text('Account'), findsOneWidget); // 5th tab only in Manager

    // 2. Switch to Admin Role
    await tester.tap(find.text('Admin Role'));
    await tester.pump();

    // 3. Verify Admin state (Admin Console title, 4 bottom tabs)
    expect(find.text('ADMIN CONSOLE'), findsOneWidget);
    expect(find.text('Seed Purchase'), findsWidgets);
    expect(find.text('Booking Slot'), findsWidgets);
    expect(find.text('Farm Visits'), findsWidgets);
    expect(find.text('Grain Sales'), findsWidgets);
    expect(find.text('Account'), findsNothing); // 5th tab removed in Admin

    // Advance time past the toast timer (repeating shimmer animation prevents pumpAndSettle)
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('StatusPill component resolves correct styles', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              StatusPill(label: 'Approved', type: PillType.good),
              StatusPill(label: 'Pending', type: PillType.warn),
              StatusPill(label: 'Rejected', type: PillType.bad),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Approved'), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Rejected'), findsOneWidget);
  });

  testWidgets('StatusPill maps VisitStatus pending_review and BookingStatus inspected (M11 rec 10)',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              StatusPill.fromStatus('pending_review'),
              StatusPill.fromStatus('inspected'),
            ],
          ),
        ),
      ),
    );

    final pendingReview = tester.widget<StatusPill>(find.byType(StatusPill).at(0));
    expect(pendingReview.label, 'Pending review');
    expect(pendingReview.type, PillType.warn);

    final inspected = tester.widget<StatusPill>(find.byType(StatusPill).at(1));
    expect(inspected.label, 'Inspected');
    expect(inspected.type, PillType.info);
  });

  testWidgets('SquircleIconButton triggers onTap callback', (WidgetTester tester) async {
    bool tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SquircleIconButton(
            icon: const Icon(Icons.search),
            onTap: () {
              tapped = true;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byType(SquircleIconButton));
    expect(tapped, isTrue);
  });
}
