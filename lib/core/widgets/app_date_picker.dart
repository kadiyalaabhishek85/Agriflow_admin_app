import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';

/// Shared agri-green calendar theme applied globally in [AppTheme] and
/// locally in [showAppDatePicker] / [showAppDateRangePicker].
DatePickerThemeData buildAppDatePickerTheme() {
  return DatePickerThemeData(
    backgroundColor: AppColors.surface,
    surfaceTintColor: Colors.transparent,
    elevation: 6,
    shadowColor: const Color.fromRGBO(21, 48, 42, 0.16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
      side: const BorderSide(color: AppColors.line, width: 1),
    ),
    headerBackgroundColor: AppColors.canopy,
    headerForegroundColor: Colors.white,
    headerHelpStyle: AppTypography.bodySmall(
      color: const Color(0xE0FFFFFF),
      fontWeight: FontWeight.w700,
    ),
    headerHeadlineStyle: AppTypography.titleLarge(color: Colors.white).copyWith(fontSize: 26),
    weekdayStyle: AppTypography.bodySmall(
      color: AppColors.textMuted,
      fontWeight: FontWeight.w700,
    ),
    dayStyle: AppTypography.bodySmall(color: AppColors.text),
    yearStyle: AppTypography.bodyMedium(color: AppColors.text),
    todayBorder: const BorderSide(color: AppColors.canopy, width: 1.5),
    todayForegroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return Colors.white;
      return AppColors.canopyDeep;
    }),
    todayBackgroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return AppColors.canopy;
      return AppColors.surfaceAlt;
    }),
    dayForegroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return Colors.white;
      if (states.contains(WidgetState.disabled)) {
        return AppColors.textFaint.withAlpha(115);
      }
      return AppColors.text;
    }),
    dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return AppColors.canopy;
      return Colors.transparent;
    }),
    rangePickerBackgroundColor: AppColors.surface,
    rangePickerSurfaceTintColor: Colors.transparent,
    rangePickerHeaderBackgroundColor: AppColors.canopy,
    rangePickerHeaderForegroundColor: Colors.white,
    rangeSelectionBackgroundColor: AppColors.surfaceAlt,
    rangeSelectionOverlayColor: WidgetStatePropertyAll(
      AppColors.canopy.withAlpha(30),
    ),
    dividerColor: AppColors.line,
    cancelButtonStyle: TextButton.styleFrom(
      foregroundColor: AppColors.textMuted,
      textStyle: AppTypography.button(color: AppColors.textMuted),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    confirmButtonStyle: TextButton.styleFrom(
      foregroundColor: AppColors.canopyDeep,
      textStyle: AppTypography.button(color: AppColors.canopyDeep),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

Widget _buildCompactCalendarDialog(BuildContext context, Widget child) {
  final mq = MediaQuery.of(context);
  final compactWidth = math.min(mq.size.width, 360.0);
  // Desktop/web windows have width > height, which flips Material's
  // DatePickerDialog into a wide side-by-side landscape layout. Forcing a
  // portrait aspect inside the builder keeps the calendar card vertical,
  // centered, and compact without overflowing shorter mobile viewports.
  final adjustedMq = mq.size.width >= mq.size.height && mq.size.height > compactWidth
      ? mq.copyWith(size: Size(compactWidth, mq.size.height))
      : mq;

  final baseTheme = Theme.of(context);
  final themed = baseTheme.copyWith(
    colorScheme: baseTheme.colorScheme.copyWith(
      primary: AppColors.canopy,
      onPrimary: Colors.white,
      surface: AppColors.surface,
      onSurface: AppColors.text,
      secondary: AppColors.canopyDeep,
      surfaceContainerHigh: AppColors.surface,
    ),
    datePickerTheme: buildAppDatePickerTheme(),
  );

  return MediaQuery(
    data: adjustedMq,
    child: Theme(
      data: themed,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: child,
        ),
      ),
    ),
  );
}

/// Shows a neat, compact, AgriFlow-themed portrait calendar date picker.
Future<DateTime?> showAppDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  DatePickerEntryMode initialEntryMode = DatePickerEntryMode.calendarOnly,
  String? helpText,
}) {
  return showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
    initialEntryMode: initialEntryMode,
    helpText: helpText,
    builder: (ctx, child) => _buildCompactCalendarDialog(ctx, child!),
  );
}

/// Shows a neat, AgriFlow-themed date range picker.
Future<DateTimeRange?> showAppDateRangePicker({
  required BuildContext context,
  required DateTime firstDate,
  required DateTime lastDate,
  DateTimeRange? initialDateRange,
  DatePickerEntryMode initialEntryMode = DatePickerEntryMode.calendarOnly,
  String? helpText,
}) {
  return showDateRangePicker(
    context: context,
    firstDate: firstDate,
    lastDate: lastDate,
    initialDateRange: initialDateRange,
    initialEntryMode: initialEntryMode,
    helpText: helpText,
    builder: (ctx, child) => _buildCompactCalendarDialog(ctx, child!),
  );
}
