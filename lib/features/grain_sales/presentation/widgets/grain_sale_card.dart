import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../domain/entities/grain_sale_item.dart';
import '../../../../core/widgets/app_card.dart';

/// Card component representing a Grain Sale transaction matching approved HTML UX.
class GrainSaleCard extends StatelessWidget {
  final GrainSaleItem item;
  final VoidCallback onTap;

  const GrainSaleCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  String _formatRelativeTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    }
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      boxShadow: AppColors.shadowSm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Avatar, Farmer Info, Status Pill
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Farmer Initials Avatar
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.canopyLight,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.canopy.withValues(alpha: 0.3)),
                ),
                alignment: Alignment.center,
                child: Text(
                  item.farmerInitials,
                  style: AppTypography.titleSmall(color: AppColors.canopyDeep),
                ),
              ),
              const SizedBox(width: 12),
              // Farmer Name & Crop details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.displayFarmerName,
                      style: AppTypography.titleSmall(color: AppColors.text),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.grainType} (Grade ${item.grade}) · ${item.goodMaterialQuintals} qtl',
                      style: AppTypography.bodySmall(color: AppColors.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusPill.fromStatus(item.status),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.line, height: 1),
          const SizedBox(height: 10),
          // Bottom Section: Total Payout and Timestamp (using Wrap to prevent overflow on small screens)
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 4,
                runSpacing: 2,
                children: [
                  Text(
                    'Total Payout: ',
                    style: AppTypography.bodySmall(color: AppColors.textMuted),
                  ),
                  Text(
                    item.displayTotalPayout,
                    style: AppTypography.monoMedium(
                      color: AppColors.text,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              Text(
                _formatRelativeTime(item.createdAt),
                style: AppTypography.caption(color: AppColors.textFaint),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
