import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/squircle_icon_button.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../domain/entities/farmer_item.dart';
import '../../../../core/widgets/app_card.dart';

/// Card widget matching the approved HTML All Farmers layout.
/// Displays avatar with initials, farmer name, phone number, land size,
/// status pill, and detail view action button.
class FarmerCard extends StatelessWidget {
  final FarmerItem farmer;
  final VoidCallback onTap;

  const FarmerCard({
    super.key,
    required this.farmer,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      borderRadius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: onTap,
      child: Row(
        children: [
          // Avatar with initials
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFE5F6EA),
              borderRadius: BorderRadius.circular(21),
              border: Border.all(
                color: AppColors.canopyLight.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              farmer.initials,
              style: const TextStyle(
                color: AppColors.canopyDeep,
                fontWeight: FontWeight.w800,
                fontSize: 14.5,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Name & phone · land
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  farmer.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${farmer.phone} · ${farmer.landAcresDisplay}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Status pill
          StatusPill.fromStatus(farmer.status),
          const SizedBox(width: 8),

          // View action button
          SquircleIconButton(
            icon: const Icon(
              Icons.remove_red_eye_outlined,
              size: 16,
              color: AppColors.adminNavy,
            ),
            size: 32,
            onTap: onTap,
          ),
        ],
      ),
    );
  }
}
