import 'package:agriflow_admin/core/theme/app_theme.dart';
import 'package:agriflow_admin/core/widgets/app_date_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'showAppDatePicker stays compact portrait on wide landscape desktop viewport',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 720));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      DateTime? picked;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  picked = await showAppDatePicker(
                    context: context,
                    initialDate: DateTime(2026, 11, 28),
                    firstDate: DateTime(2026, 11, 1),
                    lastDate: DateTime(2027, 11, 1),
                    helpText: 'Select visit date',
                  );
                },
                child: const Text('Open Picker'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Picker'));
      await tester.pumpAndSettle();

      expect(find.text('Select visit date'), findsOneWidget);
      final dialogSize = tester.getSize(find.byType(DatePickerDialog));
      expect(dialogSize.width, lessThanOrEqualTo(360.0));
      expect(dialogSize.height, greaterThan(dialogSize.width));
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(picked, DateTime(2026, 11, 28));
    },
  );
}
