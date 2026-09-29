import 'package:flutter/material.dart';
import 'package:agriflow_admin/core/constants/app_colors.dart';
import 'package:agriflow_admin/core/constants/app_typography.dart';

class DateSelectorStrip extends StatelessWidget {
  final DateTime? selectedDate;
  final ValueChanged<DateTime?> onDateSelected;

  const DateSelectorStrip({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  static const List<String> _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final days = List.generate(7, (i) => today.add(Duration(days: i)));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // "All Dates" chip
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _buildChip(
              isSelected: selectedDate == null,
              onTap: () => onDateSelected(null),
              topLabel: 'Show',
              mainLabel: 'All',
            ),
          ),
          ...days.map((date) {
            final isToday = _isSameDay(date, today);
            final isSelected = selectedDate != null && _isSameDay(date, selectedDate!);
            final weekdayName = isToday ? 'Today' : _weekdays[date.weekday - 1];
            final dayNumber = date.day.toString();

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildChip(
                isSelected: isSelected,
                onTap: () => onDateSelected(isSelected ? null : date),
                topLabel: weekdayName,
                mainLabel: dayNumber,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildChip({
    required bool isSelected,
    required VoidCallback onTap,
    required String topLabel,
    required String mainLabel,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppColors.radiusMd),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.canopy : AppColors.surface,
              borderRadius: BorderRadius.circular(AppColors.radiusMd),
              border: Border.all(
                color: isSelected ? AppColors.canopy : AppColors.line,
              ),
              boxShadow: isSelected ? AppColors.shadowSm : null,
            ),
            // Guarantees a >=48dp tall touch target (48 = 32 content + 16
            // vertical padding) per ISSUE-P3-03 without changing the
            // horizontal footprint of the chip.
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    topLabel,
                    style: AppTypography.caption(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.85)
                          : AppColors.textMuted,
                    ).copyWith(fontSize: 10.5, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    mainLabel,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.text,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ),
    );
  }
}
