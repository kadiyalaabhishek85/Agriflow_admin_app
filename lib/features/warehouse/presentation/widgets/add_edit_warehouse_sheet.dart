import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/entities/warehouse_item.dart';
import '../../../../core/widgets/sheet_drag_handle.dart';

/// Modal bottom sheet for creating or updating a warehouse facility (Admin only).
class AddEditWarehouseSheet extends StatefulWidget {
  final WarehouseItem? warehouse;
  final String? Function()? errorMessage;
  final Future<bool> Function({
    required String name,
    required String address,
    required double totalCapacityKg,
    String? location,
    String? contactNumber,
    String? managerId,
    bool? isActive,
  }) onSave;

  const AddEditWarehouseSheet({
    super.key,
    this.warehouse,
    this.errorMessage,
    required this.onSave,
  });

  @override
  State<AddEditWarehouseSheet> createState() => _AddEditWarehouseSheetState();
}

class _AddEditWarehouseSheetState extends State<AddEditWarehouseSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _locationController;
  late final TextEditingController _addressController;
  late final TextEditingController _capacityQtlController;
  late final TextEditingController _contactController;
  late bool _isActive;
  bool _isSubmitting = false;

  String? _nameError;
  String? _addressError;
  String? _capacityError;
  String? _serverError;

  bool get isEditing => widget.warehouse != null;

  @override
  void initState() {
    super.initState();
    final w = widget.warehouse;
    _nameController = TextEditingController(text: w?.name ?? '');
    _locationController = TextEditingController(text: w?.location ?? '');
    _addressController = TextEditingController(text: w?.address ?? '');
    _capacityQtlController = TextEditingController(
      text: w != null ? w.totalCapacityQtl.toStringAsFixed(1) : '',
    );
    _contactController = TextEditingController(text: w?.contactNumber ?? '');
    _isActive = w?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _addressController.dispose();
    _capacityQtlController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  bool _validate() {
    bool valid = true;
    setState(() {
      _nameError = null;
      _addressError = null;
      _capacityError = null;
      _serverError = null;

      final name = _nameController.text.trim();
      if (name.length < 2) {
        _nameError = 'Warehouse name must be at least 2 characters.';
        valid = false;
      } else if (name.length > 160) {
        _nameError = 'Name cannot exceed 160 characters.';
        valid = false;
      }

      final address = _addressController.text.trim();
      if (address.length < 4) {
        _addressError = 'Address must be at least 4 characters.';
        valid = false;
      }

      final capText = _capacityQtlController.text.trim();
      final qtl = double.tryParse(capText);
      if (qtl == null || qtl <= 0) {
        _capacityError = 'Enter a valid positive capacity in Quintals.';
        valid = false;
      }
    });

    return valid;
  }

  Future<void> _handleSubmit() async {
    if (!_validate()) return;

    final qtl = double.parse(_capacityQtlController.text.trim());
    final totalCapacityKg = qtl * 100.0; // 1 Qtl = 100 Kg

    setState(() {
      _isSubmitting = true;
      _serverError = null;
    });

    final success = await widget.onSave(
      name: _nameController.text.trim(),
      address: _addressController.text.trim(),
      totalCapacityKg: totalCapacityKg,
      location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
      contactNumber: _contactController.text.trim().isEmpty ? null : _contactController.text.trim(),
      isActive: isEditing ? _isActive : null,
    );

    if (mounted) {
      setState(() {
        _isSubmitting = false;
        if (!success) {
          _serverError = widget.errorMessage?.call() ??
              'Failed to save warehouse details. Please try again.';
        }
      });
      if (success) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.9;
    return Material(
      color: AppColors.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(AppColors.radiusLg)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                SheetDragHandle(margin: const EdgeInsets.only(bottom: 16)),

                // Title and Subtitle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEditing ? 'Edit Warehouse' : 'Add Warehouse',
                            style: AppTypography.titleMedium(
                              color: AppColors.text,
                            ).copyWith(fontWeight: FontWeight.w800),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Enter warehouse facility details below',
                            style: AppTypography.caption(color: AppColors.textMuted),
                            maxLines: 2,
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

            // Warehouse Name
            AppTextField(
              label: 'Warehouse Name *',
              hint: 'e.g. Adoni Central Storage',
              controller: _nameController,
              errorText: _nameError,
              enabled: !_isSubmitting,
            ),
            const SizedBox(height: 14),

            // Location (City/Town/District)
            AppTextField(
              label: 'Location / District',
              hint: 'e.g. Adoni, Kurnool',
              controller: _locationController,
              enabled: !_isSubmitting,
            ),
            const SizedBox(height: 14),

            // Physical Address
            AppTextField(
              label: 'Address *',
              hint: 'e.g. Plot 12, Industrial Estate, Main Road',
              controller: _addressController,
              errorText: _addressError,
              enabled: !_isSubmitting,
            ),
            const SizedBox(height: 14),

            // Capacity in Quintals
            AppTextField(
              label: 'Total Capacity (Quintals) *',
              hint: 'e.g. 5000 (equivalent to 500,000 kg)',
              controller: _capacityQtlController,
              errorText: _capacityError,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              enabled: !_isSubmitting,
            ),
            const SizedBox(height: 14),

            // Contact Number
            AppTextField(
              label: 'Contact Number',
              hint: 'e.g. +91 98765 43210',
              controller: _contactController,
              keyboardType: TextInputType.phone,
              enabled: !_isSubmitting,
            ),

            if (isEditing) ...[
              const SizedBox(height: 14),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Active Facility',
                  style: AppTypography.bodySmall(color: AppColors.text).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Facility accepts incoming bookings and grain intake',
                  style: AppTypography.caption(color: AppColors.textMuted),
                ),
                value: _isActive,
                activeThumbColor: AppColors.canopy,
                onChanged: _isSubmitting ? null : (val) => setState(() => _isActive = val),
              ),
            ],

            if (_serverError != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.badBg,
                  borderRadius: BorderRadius.circular(AppColors.radiusSm),
                  border: Border.all(color: AppColors.bad.withValues(alpha: 0.35)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, size: 16, color: AppColors.bad),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _serverError!,
                        style: AppTypography.caption(color: AppColors.bad),
                      ),
                    ),
                  ],
                ),
              ),
            ],

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
                            isEditing ? 'Save Changes' : 'Create Warehouse',
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
    ),
    ),
    );
  }
}
