import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agriflow_admin/core/widgets/detail_row.dart';
import 'package:agriflow_admin/core/widgets/sheet_drag_handle.dart';
import 'package:agriflow_admin/core/widgets/squircle_icon_button.dart';
import 'package:agriflow_admin/features/booking_slot/presentation/widgets/date_selector_strip.dart';

void main() {
  group('DetailRow (flutter-03 rec 11)', () {
    testWidgets('Renders label and value text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: DetailRow('Grain Type', 'Rice - Sona')),
        ),
      );
      expect(find.text('Grain Type'), findsOneWidget);
      expect(find.text('Rice - Sona'), findsOneWidget);
    });

    testWidgets('Default value style is bodySmall w600', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: DetailRow('Label', 'Value')),
        ),
      );
      final value = tester.widget<Text>(find.text('Value'));
      expect(value.style?.fontWeight, FontWeight.w600);
    });

    testWidgets('Emphasis value style is titleSmall w800', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DetailRow('Total', '\$1,250', emphasis: true),
          ),
        ),
      );
      final value = tester.widget<Text>(find.text('\$1,250'));
      expect(value.style?.fontWeight, FontWeight.w800);
    });

    testWidgets('valueColor overrides the value text color', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DetailRow(
              'Status',
              'Paid',
              valueColor: Color(0xFF0B7A4B),
            ),
          ),
        ),
      );
      final value = tester.widget<Text>(find.text('Paid'));
      expect(value.style?.color, const Color(0xFF0B7A4B));
    });
  });

  group('SheetDragHandle (flutter-03 rec 11)', () {
    testWidgets('Renders a 40x4 drag handle', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SheetDragHandle())),
      );
      final handle = find.descendant(
        of: find.byType(SheetDragHandle),
        matching: find.byType(Container),
      );
      expect(handle, findsOneWidget);
      expect(tester.getSize(handle), const Size(40, 4));
    });

    testWidgets('Preserves caller margin without changing handle width', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SheetDragHandle(margin: EdgeInsets.only(bottom: 16)),
          ),
        ),
      );
      final handle = find.descendant(
        of: find.byType(SheetDragHandle),
        matching: find.byType(Container),
      );
      expect(tester.getSize(handle).width, 40);
      expect(tester.getSize(handle).height, greaterThanOrEqualTo(4));
    });
  });

  group('SquircleIconButton touch target (ISSUE-P3-03)', () {
    testWidgets('Hit box is at least 48x48 even when visual is smaller', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SquircleIconButton(
                size: 32,
                icon: const Icon(Icons.settings, size: 16),
                onTap: () {},
              ),
            ),
          ),
        ),
      );
      final box = tester.getSize(find.byType(SquircleIconButton));
      expect(box.width, greaterThanOrEqualTo(kMinTouchTargetSize));
      expect(box.height, greaterThanOrEqualTo(kMinTouchTargetSize));
      expect(kMinTouchTargetSize, 48.0);
    });

    testWidgets('Visual button keeps its requested size', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SquircleIconButton(
                size: 32,
                icon: const Icon(Icons.settings, size: 16),
                onTap: () {},
              ),
            ),
          ),
        ),
      );
      final visual = find
          .descendant(
            of: find.byType(SquircleIconButton),
            matching: find.byType(Container),
          )
          .first;
      expect(tester.getSize(visual), const Size(32, 32));
    });

    testWidgets('Tap outside the 32dp visual but inside the 48dp box fires onTap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SquircleIconButton(
                size: 32,
                icon: const Icon(Icons.settings, size: 16),
                onTap: () => taps++,
              ),
            ),
          ),
        ),
      );
      final center = tester.getCenter(find.byType(SquircleIconButton));
      await tester.tapAt(center + const Offset(22, 22));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('Center tap still fires onTap (default 38dp variant)', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(child: SquircleIconButton.back(onTap: () => taps++)),
          ),
        ),
      );
      expect(
        tester.getSize(find.byType(SquircleIconButton)).height,
        greaterThanOrEqualTo(kMinTouchTargetSize),
      );
      await tester.tap(find.byType(SquircleIconButton));
      await tester.pump();
      expect(taps, 1);
    });
  });

  group('DateSelectorStrip touch target (ISSUE-P3-03)', () {
    testWidgets('Every date chip is at least 48dp tall', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DateSelectorStrip(
              selectedDate: null,
              onDateSelected: (_) {},
            ),
          ),
        ),
      );
      final chips = find.descendant(
        of: find.byType(DateSelectorStrip),
        matching: find.byType(InkWell),
      );
      expect(chips, findsWidgets);
      for (final chip in chips.evaluate()) {
        expect(
          tester.getSize(find.byWidget(chip.widget)).height,
          greaterThanOrEqualTo(kMinTouchTargetSize),
          reason: 'date chip must meet the 48dp minimum touch target',
        );
      }
    });

    testWidgets('Tapping a chip calls onDateSelected', (tester) async {
      DateTime? picked;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DateSelectorStrip(
              selectedDate: null,
              onDateSelected: (d) => picked = d,
            ),
          ),
        ),
      );
      final chips = find.descendant(
        of: find.byType(DateSelectorStrip),
        matching: find.byType(InkWell),
      );
      await tester.tap(chips.at(2));
      await tester.pump();
      expect(picked, isNotNull);
    });
  });
}
