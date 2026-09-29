import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/squircle_icon_button.dart';
import '../../../../core/widgets/sheet_drag_handle.dart';

/// Bottom sheet for adding / registering a new farmer.
/// Matches `#flow-add-farmer` in Manager Dashboard and React Admin registration.
class AddFarmerSheet extends StatefulWidget {
  final Future<bool> Function({
    required String name,
    required String phone,
    required String password,
    String? email,
    String? address,
    double? acresOfLand,
    String? cropAddress,
  }) onSubmit;
  final String? Function()? errorMessage;

  const AddFarmerSheet({
    super.key,
    required this.onSubmit,
    this.errorMessage,
  });

  @override
  State<AddFarmerSheet> createState() => _AddFarmerSheetState();
}

class _AddFarmerSheetState extends State<AddFarmerSheet> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController(text: 'AgriFlow@123');
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _acresController = TextEditingController();
  final _cropAddressController = TextEditingController();

  String? _nameError;
  String? _phoneError;
  String? _passwordError;
  String? _acresError;
  String? _submitError;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _acresController.dispose();
    _cropAddressController.dispose();
    super.dispose();
  }

  bool _validate() {
    bool valid = true;
    setState(() {
      _nameError = null;
      _phoneError = null;
      _passwordError = null;
      _acresError = null;
      _submitError = null;

      final name = _nameController.text.trim();
      if (name.isEmpty) {
        _nameError = 'Please enter farmer full name';
        valid = false;
      } else if (name.length < 2) {
        _nameError = 'Name must be at least 2 characters';
        valid = false;
      }

      final phone = _phoneController.text.trim().replaceAll(RegExp(r'\D'), '');
      if (phone.isEmpty) {
        _phoneError = 'Please enter mobile number';
        valid = false;
      } else if (phone.length < 10) {
        _phoneError = 'Phone number must be at least 10 digits';
        valid = false;
      }

      final password = _passwordController.text;
      if (password.length < 8) {
        _passwordError = 'Password must be at least 8 characters';
        valid = false;
      }

      final acresText = _acresController.text.trim();
      if (acresText.isNotEmpty) {
        final acres = double.tryParse(acresText);
        if (acres == null || acres < 0) {
          _acresError = 'Please enter valid acres (number >= 0)';
          valid = false;
        }
      }
    });

    return valid;
  }

  Future<void> _handleSave() async {
    if (!_validate()) return;

    setState(() => _isSubmitting = true);

    final cleanPhone = _phoneController.text.trim().replaceAll(RegExp(r'\D'), '');
    final acresText = _acresController.text.trim();
    final acres = acresText.isNotEmpty ? double.tryParse(acresText) : null;

    final success = await widget.onSubmit(
      name: _nameController.text.trim(),
      phone: cleanPhone,
      password: _passwordController.text,
      email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
      address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
      acresOfLand: acres,
      cropAddress: _cropAddressController.text.trim().isNotEmpty ? _cropAddressController.text.trim() : null,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _submitError = widget.errorMessage?.call() ??
              'Failed to register farmer. Please check details and try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Drag handle
                  SheetDragHandle(margin: const EdgeInsets.only(bottom: 12)),

                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'REGISTER NEW FARMER',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: AppColors.textFaint,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Add to Directory',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.text,
                            ),
                          ),
                        ],
                      ),
                      SquircleIconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: AppColors.textMuted,
                        ),
                        size: 32,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (_submitError != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.badBg.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.badBg),
                      ),
                      child: Text(
                        _submitError!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.bad,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],

                  // Full name
                  AppTextField(
                    label: 'Full Name *',
                    hint: 'e.g. Ramulu Naik',
                    controller: _nameController,
                    errorText: _nameError,
                    prefixIcon: const Icon(Icons.person_outline_rounded, size: 18, color: AppColors.textFaint),
                  ),
                  const SizedBox(height: 12),

                  // Phone
                  AppTextField(
                    label: 'Phone (10 digits) *',
                    hint: '9876543210',
                    controller: _phoneController,
                    errorText: _phoneError,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    prefixIcon: const Icon(Icons.phone_outlined, size: 18, color: AppColors.textFaint),
                  ),
                  const SizedBox(height: 12),

                  // Password
                  AppTextField(
                    label: 'Password (min. 8 chars) *',
                    hint: 'Min. 8 characters',
                    controller: _passwordController,
                    errorText: _passwordError,
                    isPassword: true,
                    prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.textFaint),
                  ),
                  const SizedBox(height: 12),

                  // Email
                  AppTextField(
                    label: 'Email (Optional)',
                    hint: 'farmer@example.com',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: const Icon(Icons.email_outlined, size: 18, color: AppColors.textFaint),
                  ),
                  const SizedBox(height: 12),

                  // Address
                  AppTextField(
                    label: 'Village / Address (Optional)',
                    hint: 'Village or Town name',
                    controller: _addressController,
                    prefixIcon: const Icon(Icons.location_on_outlined, size: 18, color: AppColors.textFaint),
                  ),
                  const SizedBox(height: 12),

                  // Land size & Crop address
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: 'Land Size (Acres)',
                          hint: 'e.g. 5.5',
                          controller: _acresController,
                          errorText: _acresError,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          prefixIcon: const Icon(Icons.landscape_outlined, size: 18, color: AppColors.textFaint),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AppTextField(
                          label: 'Farm Location',
                          hint: 'Plot / Sector',
                          controller: _cropAddressController,
                          prefixIcon: const Icon(Icons.pin_drop_outlined, size: 18, color: AppColors.textFaint),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Submit button
                  ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _handleSave,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.person_add_alt_1_rounded, size: 18),
                    label: Text(_isSubmitting ? 'Registering...' : 'Register Farmer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.canopy,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
