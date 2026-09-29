import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../domain/entities/seed_inventory_item.dart';

/// Card component presenting a seed catalog product with multi-warehouse availability,
/// grade pricing, global stock levels, and role-gated actions.
class SeedInventoryCard extends StatelessWidget {
  final SeedInventoryItem seed;
  final bool isAdmin;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const SeedInventoryCard({
    super.key,
    required this.seed,
    this.isAdmin = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Image/Icon, Name, Variety, and Status Pill
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 48,
                  height: 48,
                  color: AppColors.surfaceAlt,
                  child: (seed.imageUrl != null && seed.imageUrl!.trim().isNotEmpty)
                      ? Image.network(
                          seed.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _buildFallbackThumbnail(),
                        )
                      : _buildFallbackThumbnail(),
                ),
              ),
              const SizedBox(width: 12),

              // Title and Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      seed.name,
                      style: AppTypography.titleSmall(
                        color: AppColors.text,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _buildSubtitle(),
                      style: AppTypography.bodySmall(
                        color: AppColors.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusPill(
                label: seed.isActive ? 'Active' : 'Inactive',
                type: seed.isActive ? PillType.good : PillType.neutral,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Pricing & Stock Row
          Wrap(
            spacing: 12,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Base Price / kg
              Text(
                '₹${seed.displayPrice}/kg',
                style: AppTypography.titleSmall(
                  color: AppColors.canopyDeep,
                  fontWeight: FontWeight.w800,
                ),
              ),

              // Global Stock in Qtl and Kg
              Text(
                '${seed.displayStockQtl} Qtl (${seed.displayStockKg} kg)',
                style: AppTypography.bodySmall(
                  color: seed.isLowStock ? AppColors.bad : AppColors.textMuted,
                  fontWeight: seed.isLowStock ? FontWeight.w800 : FontWeight.w600,
                ),
              ),

              // Low-stock alert badge (< 5 Qtl / < 500 Kg)
              if (seed.isLowStock)
                const StatusPill(
                  label: 'LOW STOCK',
                  type: PillType.bad,
                ),

              // Max Order Quantity badge
              if (seed.maxOrderQuantityKg != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.infoBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.adminNavyLight.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    'Max: ${seed.displayMaxOrderQuantity} kg',
                    style: AppTypography.caption(
                      color: AppColors.adminNavyLight,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),

          // Grade Pricing Breakdown if configured
          if (seed.priceGradeA != null || seed.priceGradeB != null || seed.priceGradeC != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.line),
              ),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Grade Prices: ',
                    style: AppTypography.caption(
                      color: AppColors.textFaint,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (seed.priceGradeA != null)
                    Text(
                      'A: ₹${seed.displayPriceGradeA}',
                      style: AppTypography.caption(
                        color: AppColors.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  if (seed.priceGradeB != null)
                    Text(
                      'B: ₹${seed.displayPriceGradeB}',
                      style: AppTypography.caption(
                        color: AppColors.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  if (seed.priceGradeC != null)
                    Text(
                      'C: ₹${seed.displayPriceGradeC}',
                      style: AppTypography.caption(
                        color: AppColors.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ),
          ],

          // Fulfillment Warehouses Row
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2, right: 6),
                child: Icon(Icons.warehouse_outlined, size: 14, color: AppColors.textFaint),
              ),
              Expanded(
                child: seed.warehouses.isNotEmpty
                    ? Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: seed.warehouses.map((w) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.infoBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              w.name,
                              style: AppTypography.caption(
                                color: AppColors.adminNavyDeep,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                      )
                    : Text(
                        'Unassigned to any warehouse',
                        style: AppTypography.caption(color: AppColors.textFaint)
                            .copyWith(fontStyle: FontStyle.italic),
                      ),
              ),
            ],
          ),

          // Description snippet if available
          if (seed.description != null && seed.description!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              seed.description!,
              style: AppTypography.caption(
                color: AppColors.textFaint,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          // Admin Action Row: Edit & Delete Buttons (Hidden for Manager)
          if (isAdmin) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                // Edit button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Edit'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.text,
                      side: const BorderSide(color: AppColors.line),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      textStyle: AppTypography.bodySmall(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                if (seed.isActive) ...[
                  const SizedBox(width: 10),
                  // Delete button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: const Text('Delete'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.bad,
                        side: const BorderSide(color: AppColors.bad),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        textStyle: AppTypography.bodySmall(
                          fontWeight: FontWeight.w700,
                          color: AppColors.bad,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFallbackThumbnail() {
    return const Center(
      child: Icon(
        Icons.grass,
        color: AppColors.canopy,
        size: 24,
      ),
    );
  }

  String _buildSubtitle() {
    final parts = <String>[];
    if (seed.cropType != null && seed.cropType!.trim().isNotEmpty) {
      parts.add(seed.cropType!.trim());
    }
    if (seed.variety != null && seed.variety!.trim().isNotEmpty) {
      parts.add(seed.variety!.trim());
    }
    return parts.isNotEmpty ? parts.join(' • ') : '—';
  }
}
