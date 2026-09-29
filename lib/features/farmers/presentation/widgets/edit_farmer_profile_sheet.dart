import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../domain/entities/farmer_item.dart';
import '../../../../core/widgets/sheet_drag_handle.dart';

/// Modal bottom sheet for editing a farmer profile (FEAT-04)
/// via PATCH /api/v1/farmers/{farmer_id}. All request fields are optional;
/// only non-empty values are sent.
class EditFarmerProfileSheet extends StatefulWidget {
  final FarmerItem farmer;
  final bool isSubmitting;
  final Future<bool> Function({
    required String name,
    required String phone,
    String? email,
    String? address,
    double? acresOfLand,
    String? soilType,
    String? irrigationType,
    String? primaryCrop,
    String? secondaryCrop,
  }) onSubmit;
  final String? Function()? errorMessage;

  const EditFarmerProfileSheet({
    super.key,
    required this.farmer,
    required this.isSubmitting,
    required this.onSubmit,
    this.errorMessage,
  });

  static Future<bool?> show({
    required BuildContext context,
    required FarmerItem farmer,
    required bool isSubmitting,
    required Future<bool> Function({
      required String name,
      required String phone,
      String? email,
      String? address,
      double? acresOfLand,
      String? soilType,
      String? irrigationType,
      String? primaryCrop,
      String? secondaryCrop,
    }) onSubmit,
    String? Function()? errorMessage,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => EditFarmerProfileSheet(
        farmer: farmer,
        isSubmitting: isSubmitting,
        onSubmit: onSubmit,
        errorMessage: errorMessage,
      ),
    );
  }

  @override
  State<EditFarmerProfileSheet> createState() => _EditFarmerProfileSheetState();
}

class _EditFarmerProfileSheetState extends State<EditFarmerProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;
  late final TextEditingController _acresController;
  late final TextEditingController _soilController;
  late final TextEditingController _irrigationController;
  late final TextEditingController _primaryCropController;
  late final TextEditingController _secondaryCropController;

  bool _submitting = false;
  String? _localError;

  @override
  void initState() {
    super.initState();
    final farmer = widget.farmer;
    final profile = farmer.profile;
    _nameController = TextEditingController(text: farmer.name);
    _phoneController = TextEditingController(text: farmer.phone);
    _emailController = TextEditingController(text: farmer.email ?? '');
    _addressController = TextEditingController(text: profile?.address ?? '');
    _acresController = TextEditingController(
      text: (profile?.acresOfLand.isNotEmpty ?? false) ? profile!.acresOfLand : '',
    );
    _soilController = TextEditingController(text: profile?.soilType ?? '');
    _irrigationController = TextEditingController(text: profile?.irrigationType ?? '');
    _primaryCropController = TextEditingController(text: profile?.primaryCrop ?? '');
    _secondaryCropController = TextEditingController(text: profile?.secondaryCrop ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _acresController.dispose();
    _soilController.dispose();
    _irrigationController.dispose();
    _primaryCropController.dispose();
    _secondaryCropController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
      _localError = null;
    });

    final acresText = _acresController.text.trim();
    final success = await widget.onSubmit(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim().replaceAll(RegExp(r'\D'), ''),
      email: _emailController.text.trim(),
      address: _addressController.text.trim(),
      acresOfLand: acresText.isNotEmpty ? double.tryParse(acresText) : null,
      soilType: _soilController.text.trim(),
      irrigationType: _irrigationController.text.trim(),
      primaryCrop: _primaryCropController.text.trim(),
      secondaryCrop: _secondaryCropController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (success) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _localError =
          widget.errorMessage?.call() ?? 'Could not update farmer profile. Please try again.';
    });
  }

  InputDecoration _decoration(String hint) {
    return InputDecoration(
      hintText: hint,
      fillColor: AppColors.surfaceAlt,
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.line),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: AppTypography.bodySmall(color: AppColors.text)
            .copyWith(fontWeight: FontWeight.w700),
      );

  Widget _field({
    required Key key,
    required TextEditingController controller,
    required String hint,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(hint),
        const SizedBox(height: 6),
        TextFormField(
          key: key,
          controller: controller,
          keyboardType: keyboardType,
          decoration: _decoration(hint),
          validator: validator,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final busy = _submitting || widget.isSubmitting;

    return Container(
      key: const Key('edit_farmer_sheet'),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SheetDragHandle(),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FARMER PROFILE',
                        style: AppTypography.eyebrow(color: AppColors.canopyDeep),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Edit ${widget.farmer.name}',
                        style: AppTypography.titleLarge(color: AppColors.text),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: busy ? null : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _field(
                key: const Key('edit_farmer_name_field'),
                controller: _nameController,
                hint: 'Full Name *',
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Name is required';
                  if (v.trim().length < 2) return 'Name must be at least 2 characters';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              _field(
                key: const Key('edit_farmer_phone_field'),
                controller: _phoneController,
                hint: 'Phone *',
                keyboardType: TextInputType.phone,
                validator: (v) {
                  final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
                  if (digits.length < 8 || digits.length > 20) {
                    return 'Enter a valid phone (8-20 digits)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              _field(
                key: const Key('edit_farmer_email_field'),
                controller: _emailController,
                hint: 'Email (optional)',
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  final email = (v ?? '').trim();
                  if (email.isEmpty) return null;
                  final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
                  return valid ? null : 'Enter a valid email';
                },
              ),
              const SizedBox(height: 14),
              _field(
                key: const Key('edit_farmer_address_field'),
                controller: _addressController,
                hint: 'Address / Village (optional)',
              ),
              const SizedBox(height: 14),
              _field(
                key: const Key('edit_farmer_acres_field'),
                controller: _acresController,
                hint: 'Acres of Land (optional)',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  final text = (v ?? '').trim();
                  if (text.isEmpty) return null;
                  final n = double.tryParse(text);
                  if (n == null || n < 0) return 'Enter a valid acreage (≥ 0)';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              _field(
                key: const Key('edit_farmer_soil_field'),
                controller: _soilController,
                hint: 'Soil Type (optional)',
              ),
              const SizedBox(height: 14),
              _field(
                key: const Key('edit_farmer_irrigation_field'),
                controller: _irrigationController,
                hint: 'Irrigation Type (optional)',
              ),
              const SizedBox(height: 14),
              _field(
                key: const Key('edit_farmer_primary_crop_field'),
                controller: _primaryCropController,
                hint: 'Primary Crop (optional)',
              ),
              const SizedBox(height: 14),
              _field(
                key: const Key('edit_farmer_secondary_crop_field'),
                controller: _secondaryCropController,
                hint: 'Secondary Crop (optional)',
              ),
              if (_localError != null) ...[
                const SizedBox(height: 12),
                Container(
                  key: const Key('edit_farmer_error'),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.alert.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.alert.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    _localError!,
                    style: AppTypography.bodySmall(color: AppColors.alert),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                key: const Key('edit_farmer_submit_btn'),
                onPressed: busy ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.canopyDeep,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.canopyDeep.withValues(alpha: 0.6),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: busy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.save_outlined, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Save Changes',
                            style: AppTypography.titleSmall(color: Colors.white),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
