import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';

/// Shared label/value row for detail bottom sheets.
///
/// flutter-03 rec 11: replaces the three private `_buildDetailRow` builders
/// that were duplicated in the booking, seed-purchase and grain-sale detail
/// sheets. Default typography matches the booking/seed sheets (12px w600);
/// [emphasis] reproduces their bold rows and [mono] the grain sheet's
/// money rows.
class DetailRow extends StatelessWidget {
  const DetailRow(
    this.label,
    this.value, {
    super.key,
    this.emphasis = false,
    this.mono = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool emphasis;
  final bool mono;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final TextStyle valueStyle;
    if (mono) {
      valueStyle = AppTypography.monoMedium(
        color: valueColor ?? AppColors.text,
        fontWeight: FontWeight.w700,
      );
    } else if (emphasis) {
      valueStyle = AppTypography.titleSmall(
        color: valueColor ?? AppColors.text,
      ).copyWith(fontWeight: FontWeight.w800);
    } else {
      valueStyle = AppTypography.bodySmall(
        color: valueColor ?? AppColors.text,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall(color: AppColors.textMuted),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: valueStyle,
            ),
          ),
        ],
      ),
    );
  }
}
