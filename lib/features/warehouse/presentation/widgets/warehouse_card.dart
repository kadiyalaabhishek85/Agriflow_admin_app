import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../domain/entities/warehouse_item.dart';

/// Card component presenting a warehouse location, its capacity utilization meter,
/// and role-gated admin actions.
class WarehouseCard extends StatelessWidget {
  final WarehouseItem warehouse;
  final bool isAdmin;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const WarehouseCard({
    super.key,
    required this.warehouse,
    this.isAdmin = false,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  Color _getBarColor() {
    if (warehouse.isOverCapacity) {
      return AppColors.bad;
    }
    if (warehouse.isNearCapacity) {
      return AppColors.alert;
    }
    if (warehouse.isModerateOccupancy) {
      return AppColors.amber;
    }
    return AppColors.canopy;
  }

  @override
  Widget build(BuildContext context) {
    final barColor = _getBarColor();
    final fillFraction = (warehouse.occupancyPercent / 100.0).clamp(0.0, 1.0);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppColors.radiusMd),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Warehouse Icon, Name & Location, Pill, and Edit Action
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Purple Squircle Warehouse Icon
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F2F7),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.warehouse_outlined,
                      size: 20,
                      color: Color(0xFF6B4C9A),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Name, Location & Address
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        warehouse.name,
                        style: AppTypography.titleSmall(
                          color: AppColors.text,
                        ).copyWith(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        warehouse.location?.isNotEmpty == true
                            ? '${warehouse.location} • ${warehouse.address}'
                            : warehouse.address,
                        style: AppTypography.caption(
                          color: AppColors.textMuted,
                        ).copyWith(fontSize: 11.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Active / Inactive Pill
                StatusPill.fromStatus(warehouse.isActive ? 'active' : 'inactive'),

                // Role-Gated Admin Edit Action
                if (isAdmin) ...[
                  const SizedBox(width: 4),
                  PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_vert,
                      size: 18,
                      color: AppColors.textFaint,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                    onSelected: (val) {
                      if (val == 'edit') {
                        onEdit?.call();
                      } else if (val == 'delete') {
                        onDelete?.call();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 16, color: AppColors.text),
                            SizedBox(width: 8),
                            Text('Edit Warehouse'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 16, color: AppColors.alert),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: AppColors.alert)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),

            const SizedBox(height: 12),

            // Capacity Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Container(
                height: 7,
                width: double.infinity,
                color: AppColors.line,
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: fillFraction,
                  child: Container(
                    decoration: BoxDecoration(
                      color: barColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Metric Text Row: Used/Total Capacity & Occupancy %
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${warehouse.currentLoadQtl.toStringAsFixed(1)} / ${warehouse.totalCapacityQtl.toStringAsFixed(1)} qtl capacity used',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption(
                      color: AppColors.textFaint,
                    ).copyWith(fontSize: 11),
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  children: [
                    if (warehouse.isOverCapacity) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: AppColors.badBg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'OVERFILL',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: AppColors.bad,
                          ),
                        ),
                      ),
                    ],
                    Text(
                      '${warehouse.occupancyPercent.toStringAsFixed(1)}%',
                      style: AppTypography.caption(
                        color: warehouse.isOverCapacity ? AppColors.bad : AppColors.text,
                      ).copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
