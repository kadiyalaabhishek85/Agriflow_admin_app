import 'package:flutter/material.dart';
import 'package:agriflow_admin/core/constants/app_colors.dart';
import 'package:agriflow_admin/core/constants/app_typography.dart';

class MandiRateItem {
  final String cropType;
  final String grade;
  final double pricePerKg;
  final String? effectiveDate;

  const MandiRateItem({
    required this.cropType,
    required this.grade,
    required this.pricePerKg,
    this.effectiveDate,
  });

  factory MandiRateItem.fromJson(Map<String, dynamic> json) {
    return MandiRateItem(
      cropType: (json['crop_type'] ?? json['crop'] ?? 'Crop').toString(),
      grade: (json['grade'] ?? 'Standard').toString(),
      pricePerKg: double.tryParse((json['price_per_kg'] ?? '0').toString()) ?? 0.0,
      effectiveDate: json['effective_date']?.toString(),
    );
  }
}

/// Horizontal scroll of live crop mandi prices matching HTML `#home-mandi-strip`.
class DashboardMandiStrip extends StatelessWidget {
  final List<MandiRateItem> rates;
  final String title;
  final String? updatedAt;
  final VoidCallback? onViewAll;

  const DashboardMandiStrip({
    super.key,
    required this.rates,
    this.title = 'Live Mandi Rates',
    this.updatedAt,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    if (rates.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: AppTypography.titleSmall().copyWith(
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (updatedAt != null && updatedAt!.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                'Updated $updatedAt',
                style: AppTypography.caption(
                  color: AppColors.textMuted,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: rates.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final rate = rates[index];
              return Container(
                width: 140,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppColors.radiusMd),
                  border: Border.all(color: AppColors.line),
                  boxShadow: AppColors.shadowSm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            rate.cropType,
                            style: AppTypography.bodySmall().copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.text,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            rate.grade,
                            style: AppTypography.caption(
                              color: AppColors.canopyDeep,
                            ).copyWith(fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${(rate.pricePerKg * 100).toStringAsFixed(0)} / Qtl',
                      style: AppTypography.titleSmall(
                        color: AppColors.canopyDeep,
                      ).copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      '₹${rate.pricePerKg.toStringAsFixed(1)} / kg',
                      style: AppTypography.caption(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
