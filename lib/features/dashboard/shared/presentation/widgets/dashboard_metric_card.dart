import 'package:flutter/material.dart';
import 'package:agriflow_admin/core/constants/app_colors.dart';
import 'package:agriflow_admin/core/constants/app_typography.dart';

/// Reusable metric card matching the approved HTML `.stat-card.card` design.
class DashboardMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String? deltaText;
  final Color? deltaColor;
  final VoidCallback? onTap;

  const DashboardMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    this.deltaText,
    this.deltaColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppColors.radiusMd),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppColors.radiusMd),
            border: Border.all(color: AppColors.line),
            boxShadow: AppColors.shadowSm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon Container
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: 18,
                    color: iconColor,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              // Value
              Text(
                value,
                style: AppTypography.titleLarge(
                  color: AppColors.text,
                ).copyWith(fontWeight: FontWeight.w800),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              // Label
              Text(
                label,
                style: AppTypography.bodySmall(
                  color: AppColors.textMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (deltaText != null && deltaText!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  deltaText!,
                  style: AppTypography.caption(
                    color: deltaColor ?? AppColors.canopyDeep,
                  ).copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
