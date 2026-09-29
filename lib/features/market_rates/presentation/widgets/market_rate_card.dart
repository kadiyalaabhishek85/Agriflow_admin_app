import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/market_rate_group.dart';
import '../../domain/entities/market_rate_item.dart';
import 'edit_rate_disabled_action.dart';

/// Per-crop rate card matching the approved HTML `#market-rates-list` cards:
/// crop header with (disabled) edit affordance, a 3-column grade grid with
/// ₹/quintal prices, and the "Rates per quintal" footer.
class MarketRateCard extends StatelessWidget {
  final MarketRateGroup group;

  const MarketRateCard({
    super.key,
    required this.group,
  });

  static const Map<String, Color> _gradeBackgrounds = {
    'A': AppColors.canopyLight,
    'B': AppColors.surfaceAlt,
    'C': AppColors.amberSoft,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('market-rate-card-${group.cropType}'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.canopyLight,
                  borderRadius: BorderRadius.circular(11),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.agriculture_rounded,
                  size: 19,
                  color: AppColors.canopy,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  group.cropType,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              EditRateDisabledAction(cropName: group.cropType),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 0; i < group.rates.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(child: _GradeCell(rate: group.rates[i])),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Rates per quintal',
            style: GoogleFonts.manrope(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textFaint,
            ),
          ),
        ],
      ),
    );
  }
}

class _GradeCell extends StatelessWidget {
  final MarketRateItem rate;

  const _GradeCell({required this.rate});

  @override
  Widget build(BuildContext context) {
    final background =
        MarketRateCard._gradeBackgrounds[rate.grade] ?? AppColors.surfaceAlt;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'GRADE ${rate.grade}',
            style: GoogleFonts.manrope(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textMuted,
              letterSpacing: 0.4,
            ),
            maxLines: 1,
          ),
          const SizedBox(height: 3),
          Text(
            rate.displayPricePerQtlLabel,
            style: GoogleFonts.manrope(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
