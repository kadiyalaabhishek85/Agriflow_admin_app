import 'package:flutter/material.dart';
import 'package:agriflow_admin/core/constants/app_colors.dart';
import 'package:agriflow_admin/core/constants/app_typography.dart';

/// Summary strip matching approved HTML `#home-summary-strip`.
class DashboardSummaryStrip extends StatelessWidget {
  final String primaryAmount;
  final String primaryLabel;
  final String secondarySubtitle;
  final IconData leadingIcon;
  final VoidCallback? onTap;

  const DashboardSummaryStrip({
    super.key,
    required this.primaryAmount,
    required this.primaryLabel,
    required this.secondarySubtitle,
    this.leadingIcon = Icons.show_chart_rounded,
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF16293F),
                Color(0xFF1E3A5C),
              ],
            ),
            borderRadius: BorderRadius.circular(AppColors.radiusMd),
            boxShadow: AppColors.shadowSm,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Icon(
                    leadingIcon,
                    size: 24,
                    color: const Color(0xFFEEF3F9),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          primaryAmount,
                          style: AppTypography.titleLarge(
                            color: const Color(0xFFEEF3F9),
                          ).copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            primaryLabel,
                            style: AppTypography.caption(
                              color: const Color(0xFFEEF3F9).withValues(alpha: 0.85),
                            ).copyWith(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      secondarySubtitle,
                      style: AppTypography.caption(
                        color: const Color(0xFFEEF3F9).withValues(alpha: 0.82),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
