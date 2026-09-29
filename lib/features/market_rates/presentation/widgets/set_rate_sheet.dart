import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../controllers/market_rates_controller.dart';
import '../../../../core/widgets/sheet_drag_handle.dart';

/// Modal bottom sheet for "Set New Rate" (bulk grade create).
///
/// Sends one `POST /api/v1/market-rates` per filled grade with
/// `effective_date = today`. Empty grades are never submitted, and there is
/// no bulk endpoint in the verified contract.
class SetRateSheet extends StatefulWidget {
  final MarketRatesController controller;

  const SetRateSheet({super.key, required this.controller});

  /// Crop options mirror the React reference `CROP_TYPES`.
  static const List<String> cropTypes = [
    'Rice',
    'Wheat',
    'Maize',
    'Cotton',
    'Groundnut',
    'Sugarcane',
  ];

  static Future<SetRatesResult?> show(
    BuildContext context, {
    required MarketRatesController controller,
  }) {
    return showModalBottomSheet<SetRatesResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SetRateSheet(controller: controller),
    );
  }

  @override
  State<SetRateSheet> createState() => _SetRateSheetState();
}

class _SetRateSheetState extends State<SetRateSheet> {
  String? _crop;
  final Map<String, TextEditingController> _priceControllers = {
    'A': TextEditingController(),
    'B': TextEditingController(),
    'C': TextEditingController(),
  };
  String? _validationError;
  bool _submitting = false;

  static const Map<String, Color> _gradeChipColors = {
    'A': AppColors.canopy,
    'B': AppColors.warn,
    'C': AppColors.textMuted,
  };

  @override
  void dispose() {
    for (final controller in _priceControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _validateAndSubmit() async {
    String? error;
    if (_crop == null || _crop!.trim().isEmpty) {
      error = 'Select a crop type.';
    }

    final prices = <String, double>{};
    if (error == null) {
      for (final grade in const ['A', 'B', 'C']) {
        final text = _priceControllers[grade]!.text.trim();
        if (text.isEmpty) continue;
        if (text.length > 10) {
          error = 'Price for Grade $grade is too long.';
          break;
        }
        final value = double.tryParse(text);
        if (value == null) {
          error = 'Enter a valid price for Grade $grade.';
          break;
        }
        if (value <= 0) {
          error = 'Price for Grade $grade must be greater than 0.';
          break;
        }
        prices[grade] = value;
      }
      if (error == null && prices.isEmpty) {
        error = 'Enter at least one grade price.';
      }
    }

    if (error != null) {
      setState(() => _validationError = error);
      return;
    }

    setState(() {
      _validationError = null;
      _submitting = true;
    });

    final result = await widget.controller.setRates(
      cropType: _crop!,
      prices: prices,
    );

    if (!mounted) return;
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetDragHandle(),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.canopyLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.trending_up_rounded,
                    color: AppColors.canopy,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Set New Rate',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                        ),
                      ),
                      Text(
                        'Set mandi price per crop and grade',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: AppColors.textMuted,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  splashRadius: 20,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Crop Type',
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.line),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  key: const ValueKey('set-rate-crop-dropdown'),
                  isExpanded: true,
                  value: _crop,
                  hint: Text(
                    'Select crop type...',
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      color: AppColors.textFaint,
                    ),
                  ),
                  items: SetRateSheet.cropTypes
                      .map(
                        (crop) => DropdownMenuItem(
                          value: crop,
                          child: Text(
                            crop,
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.text,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: _submitting
                      ? null
                      : (val) => setState(() => _crop = val),
                ),
              ),
            ),
            const SizedBox(height: 14),
            for (final grade in const ['A', 'B', 'C']) ...[
              _buildPriceField(grade),
              const SizedBox(height: 12),
            ],
            if (_validationError != null) ...[
              Container(
                key: const ValueKey('set-rate-validation'),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.badBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 16,
                      color: AppColors.bad,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _validationError!,
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.bad,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            Text(
              'Saved as price per kg (price_per_kg) with today\u2019s effective date. '
              'Only filled grades are submitted.',
              style: GoogleFonts.manrope(
                fontSize: 10.5,
                color: AppColors.textFaint,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              key: const ValueKey('set-rate-submit'),
              onPressed: _submitting ? null : _validateAndSubmit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: AppColors.canopy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Save Rates',
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceField(String grade) {
    final chipColor = _gradeChipColors[grade] ?? AppColors.textMuted;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 58,
              padding: const EdgeInsets.symmetric(vertical: 4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: chipColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Grade $grade',
                style: GoogleFonts.manrope(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: chipColor,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Price per kg (₹)',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          key: ValueKey('set-rate-price-$grade'),
          controller: _priceControllers[grade],
          enabled: !_submitting,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          maxLength: 10,
          decoration: InputDecoration(
            counterText: '',
            hintText: 'e.g. 22.50',
            prefixIcon: const Icon(
              Icons.currency_rupee_rounded,
              size: 18,
              color: AppColors.textMuted,
            ),
            filled: true,
            fillColor: AppColors.surfaceAlt,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.line),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}
