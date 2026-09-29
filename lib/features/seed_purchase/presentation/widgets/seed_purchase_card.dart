import 'package:flutter/material.dart';
import 'package:agriflow_admin/core/constants/app_colors.dart';
import 'package:agriflow_admin/core/constants/app_typography.dart';
import 'package:agriflow_admin/core/utils/app_dates.dart';
import 'package:agriflow_admin/core/utils/app_initials.dart';
import 'package:agriflow_admin/core/widgets/status_pill.dart';
import 'package:agriflow_admin/features/seed_purchase/domain/entities/seed_purchase_item.dart';
import 'package:agriflow_admin/core/widgets/app_card.dart';

class SeedPurchaseCard extends StatelessWidget {
  final SeedPurchaseItem item;
  final bool isActionInFlight;
  final VoidCallback onTap;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const SeedPurchaseCard({
    super.key,
    required this.item,
    required this.isActionInFlight,
    required this.onTap,
    required this.onApprove,
    required this.onReject,
  });

  String _formatDate(DateTime? dt) {
    if (dt == null) return '-';
    return AppDates.numericDate(dt);
  }

  @override
  Widget build(BuildContext context) {
    final initials = AppInitials.of(item.displayName);
    final isPending = item.isPending;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      boxShadow: AppColors.shadowSm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Avatar + Details + StatusPill
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Farmer Initials Avatar matching HTML .req-avatar
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.canopy.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: AppTypography.titleSmall(color: AppColors.canopyDeep).copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Name and Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.displayName,
                      style: AppTypography.bodyMedium(color: AppColors.text).copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.displaySeed} · ${(item.quantityKg / 100).toStringAsFixed(2)} Qtl',
                      style: AppTypography.bodySmall(color: AppColors.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_formatDate(item.createdAt)} · ${item.invoiceNumber ?? (item.id.length > 8 ? item.id.substring(0, 8) : item.id)}',
                      style: AppTypography.caption(color: AppColors.textFaint),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Status Pill
              StatusPill.fromStatus(item.paymentStatus),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.line),
          const SizedBox(height: 10),

          // Bottom Row: Price and Actions
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 8,
            spacing: 8,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '₹${item.totalAmount.toStringAsFixed(2)}',
                    style: AppTypography.titleMedium(color: AppColors.text).copyWith(
                      fontWeight: FontWeight.w800,
                      fontFamily: 'RobotoMono',
                    ),
                  ),
                  Text(
                    '₹${item.pricePerKg.toStringAsFixed(1)}/kg',
                    style: AppTypography.caption(color: AppColors.textMuted),
                  ),
                ],
              ),
              if (isPending) ...[
                if (isActionInFlight)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.canopy),
                  )
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Reject Button
                      OutlinedButton(
                        onPressed: onReject,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.bad,
                          side: const BorderSide(color: Color(0xFFFCA5A5)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: const Size(60, 32),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Reject', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 8),
                      // Approve Button
                      ElevatedButton(
                        onPressed: onApprove,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.canopy,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          minimumSize: const Size(68, 32),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text('Approve', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
              ] else ...[
                Text(
                  item.isPaid ? 'Payment Confirmed' : 'Request Closed',
                  style: AppTypography.caption(
                    color: item.isPaid ? AppColors.canopyDeep : AppColors.textMuted,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
