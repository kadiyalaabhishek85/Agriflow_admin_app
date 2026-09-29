import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/app_dates.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../domain/entities/farm_visit_item.dart';

class FarmVisitCard extends StatelessWidget {
  final FarmVisitItem item;
  final bool isActionInFlight;
  final VoidCallback onTap;

  const FarmVisitCard({
    super.key,
    required this.item,
    required this.isActionInFlight,
    required this.onTap,
  });

  String _formatDate(String? dateStr) {
    return AppDates.dayMonthYear(dateStr, fallback: 'Date TBD');
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.line),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Avatar + Farmer Info + StatusPill
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar matching HTML .req-avatar
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.canopy.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      item.farmerInitials,
                      style: AppTypography.titleSmall(color: AppColors.canopyDeep).copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Farmer name & crop type
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.displayFarmerName,
                          style: AppTypography.titleMedium(color: AppColors.text).copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 4,
                          runSpacing: 2,
                          children: [
                            Text(
                              item.displayCropName,
                              style: AppTypography.bodySmall(color: AppColors.textMuted).copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (item.enrichedCropAcres != null && item.enrichedCropAcres!.isNotEmpty)
                              Text(
                                '· ${item.enrichedCropAcres} ac',
                                style: AppTypography.caption(color: AppColors.textFaint),
                              ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceAlt,
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                'M${item.visitMonth}',
                                style: AppTypography.caption(color: AppColors.textMuted).copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Status pill
                  StatusPill.fromStatus(item.status),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: AppColors.line),
              const SizedBox(height: 10),
              // Bottom Section: Officer / Village · Scheduled Date (using Wrap to prevent overflow on small screens)
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 6,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: AppColors.textFaint,
                      ),
                      const SizedBox(width: 4),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 160),
                        child: Text(
                          '${item.displayStaffName} · ${item.displayVillage}',
                          style: AppTypography.bodySmall(color: AppColors.textMuted).copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 13,
                        color: AppColors.canopy,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(item.scheduledDate),
                        style: AppTypography.bodySmall(color: AppColors.canopyDeep).copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
