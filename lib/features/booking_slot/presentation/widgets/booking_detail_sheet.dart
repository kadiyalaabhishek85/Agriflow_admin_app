import 'package:flutter/material.dart';
import 'package:agriflow_admin/core/constants/app_colors.dart';
import 'package:agriflow_admin/core/constants/app_typography.dart';
import 'package:agriflow_admin/core/utils/app_dates.dart';
import 'package:agriflow_admin/core/widgets/detail_row.dart';
import 'package:agriflow_admin/core/widgets/status_pill.dart';
import 'package:agriflow_admin/features/booking_slot/domain/entities/booking_item.dart';

class BookingDetailSheet extends StatelessWidget {
  final BookingItem item;
  final bool isActionInFlight;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback? onInspect;

  const BookingDetailSheet({
    super.key,
    required this.item,
    required this.isActionInFlight,
    required this.onApprove,
    required this.onReject,
    this.onInspect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BOOKING DETAILS',
                    style: AppTypography.eyebrow(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.id.length > 8 ? item.id.substring(0, 8) : item.id,
                    style: AppTypography.titleMedium(color: AppColors.text).copyWith(
                      fontWeight: FontWeight.w800,
                      fontFamily: 'RobotoMono',
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.line),
          const SizedBox(height: 16),

          // Farmer Info Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.line),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.canopy.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      item.displayName.isNotEmpty ? item.displayName[0].toUpperCase() : 'F',
                      style: AppTypography.titleMedium(color: AppColors.canopyDeep).copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.displayName,
                        style: AppTypography.bodyMedium(color: AppColors.text).copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (item.displayPhone.isNotEmpty)
                        Text(
                          item.displayPhone,
                          style: AppTypography.caption(color: AppColors.textMuted),
                        ),
                      Text(
                        'ID: ${item.farmerId.length > 8 ? item.farmerId.substring(0, 8) : item.farmerId}',
                        style: AppTypography.caption(color: AppColors.textFaint),
                      ),
                    ],
                  ),
                ),
                StatusPill.fromStatus(item.status),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Breakdown Details
          DetailRow('Grain Type', item.grainType),
          DetailRow(
            'Quantity',
            '${item.quantityQtl.toStringAsFixed(2)} Qtl (${item.quantityKg.toStringAsFixed(1)} kg)',
            emphasis: true,
          ),
          DetailRow(
            'Booking Date',
            AppDates.dayMonthYear(item.bookingDate, fallback: 'Date TBD'),
          ),
          DetailRow('Warehouse Hub', item.displayWarehouse),
          if (item.displayAddress.isNotEmpty)
            DetailRow('Location', item.displayAddress),
          if (item.notes != null && item.notes!.isNotEmpty)
            DetailRow('Notes', item.notes!),

          const SizedBox(height: 24),

          // Actions
          if (item.isPending) ...[
            if (isActionInFlight)
              const Center(
                child: CircularProgressIndicator(color: AppColors.canopy),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onReject,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.bad,
                        side: const BorderSide(color: Color(0xFFFCA5A5)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Reject Request', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onApprove,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.canopy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: const Text('Approve & Confirm', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
          ] else if (item.isDelivered && onInspect != null) ...[
            if (isActionInFlight)
              const Center(
                child: CircularProgressIndicator(color: AppColors.canopy),
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  key: const Key('booking_inspect_btn'),
                  onPressed: onInspect,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.canopy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: const Text('Record Inspection', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
