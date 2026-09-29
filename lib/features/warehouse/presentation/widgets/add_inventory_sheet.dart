import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/sheet_drag_handle.dart';

/// Modal bottom sheet for logging incoming grain inventory stock intake.
class AddInventorySheet extends StatefulWidget {
  final String warehouseId;
  final String warehouseName;
  final Future<bool> Function({
    required String warehouseId,
    required String grainType,
    required double quantityKg,
  }) onAdd;

  const AddInventorySheet({
    super.key,
    required this.warehouseId,
    required this.warehouseName,
    required this.onAdd,
  });

  @override
  State<AddInventorySheet> createState() => _AddInventorySheetState();
}

class _AddInventorySheetState extends State<AddInventorySheet> {
  String _selectedGrainType = 'Rice';
  final _customTypeController = TextEditingController();
  final _quantityQtlController = TextEditingController();
  bool _isSubmitting = false;

  String? _customTypeError;
  String? _quantityError;

  final List<String> _commonGrainTypes = const [
    'Rice',
    'Wheat',
    'Maize',
    'Cotton',
    'Groundnut',
    'Sugarcane',
    'Other Seeds',
  ];

  @override
  void dispose() {
    _customTypeController.dispose();
    _quantityQtlController.dispose();
    super.dispose();
  }

  bool _validate() {
    bool valid = true;
    setState(() {
      _customTypeError = null;
      _quantityError = null;

      if (_selectedGrainType == 'Other Seeds') {
        final custom = _customTypeController.text.trim();
        if (custom.isEmpty) {
          _customTypeError = 'Please specify the crop type.';
          valid = false;
        }
      }

      final qtlText = _quantityQtlController.text.trim();
      final qtl = double.tryParse(qtlText);
      if (qtl == null || qtl <= 0) {
        _quantityError = 'Enter a valid positive quantity in Quintals.';
        valid = false;
      }
    });

    return valid;
  }

  Future<void> _handleSubmit() async {
    if (!_validate()) return;

    final qtl = double.parse(_quantityQtlController.text.trim());
    final finalGrainType = _selectedGrainType == 'Other Seeds'
        ? _customTypeController.text.trim()
        : _selectedGrainType;

    final quantityKg = qtl * 100.0; // 1 Qtl = 100 Kg

    setState(() => _isSubmitting = true);

    final success = await widget.onAdd(
      warehouseId: widget.warehouseId,
      grainType: finalGrainType,
      quantityKg: quantityKg,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppColors.radiusLg)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            SheetDragHandle(margin: const EdgeInsets.only(bottom: 16)),

            // Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Log Incoming Grain Stock',
                        style: AppTypography.titleMedium(
                          color: AppColors.text,
                        ).copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Destination: ${widget.warehouseName}',
                        style: AppTypography.caption(color: AppColors.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textMuted),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Grain Type Dropdown
            Text(
              'Grain / Seed Crop Type *',
              style: AppTypography.caption(color: AppColors.text).copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(AppColors.radiusSm),
                border: Border.all(color: AppColors.line),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedGrainType,
                  icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textMuted),
                  items: _commonGrainTypes.map((type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(
                        type,
                        style: AppTypography.bodySmall(color: AppColors.text),
                      ),
                    );
                  }).toList(),
                  onChanged: _isSubmitting
                      ? null
                      : (val) {
                          if (val != null) {
                            setState(() => _selectedGrainType = val);
                          }
                        },
                ),
              ),
            ),

            if (_selectedGrainType == 'Other Seeds') ...[
              const SizedBox(height: 14),
              AppTextField(
                label: 'Custom Seed / Crop Type *',
                hint: 'e.g. Sunflower, Mustard, Barley',
                controller: _customTypeController,
                errorText: _customTypeError,
                enabled: !_isSubmitting,
              ),
            ],

            const SizedBox(height: 14),

            // Quantity in Quintals
            AppTextField(
              label: 'Quantity (Quintals) *',
              hint: 'e.g. 50 (equivalent to 5,000 kg)',
              controller: _quantityQtlController,
              errorText: _quantityError,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              enabled: !_isSubmitting,
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppColors.radiusSm),
                      ),
                      side: const BorderSide(color: AppColors.line),
                    ),
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                    child: Text(
                      'Cancel',
                      style: AppTypography.bodySmall(color: AppColors.text),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.canopy,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppColors.radiusSm),
                      ),
                    ),
                    onPressed: _isSubmitting ? null : _handleSubmit,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Add Inventory',
                            style: AppTypography.bodySmall(color: Colors.white).copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
