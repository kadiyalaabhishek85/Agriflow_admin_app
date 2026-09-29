import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/squircle_icon_button.dart';
import '../../../../core/widgets/sheet_drag_handle.dart';

/// Bottom sheet for creating a manager account
/// (`POST /api/v1/managers` — ManagerCreate: name, phone, password required;
/// email / assigned_region / department optional; role is fixed to `manager`).
class CreateManagerSheet extends StatefulWidget {
  final Future<bool> Function({
    required String name,
    required String phone,
    required String password,
    String? email,
    String? assignedRegion,
    String? department,
  }) onSubmit;
  final String? Function()? errorMessage;

  const CreateManagerSheet({
    super.key,
    required this.onSubmit,
    this.errorMessage,
  });

  static Future<bool?> show({
    required BuildContext context,
    required Future<bool> Function({
      required String name,
      required String phone,
      required String password,
      String? email,
      String? assignedRegion,
      String? department,
    }) onSubmit,
    String? Function()? errorMessage,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateManagerSheet(
        onSubmit: onSubmit,
        errorMessage: errorMessage,
      ),
    );
  }

  @override
  State<CreateManagerSheet> createState() => _CreateManagerSheetState();
}

class _CreateManagerSheetState extends State<CreateManagerSheet> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();
  final _regionController = TextEditingController();
  final _departmentController = TextEditingController();

  String? _nameError;
  String? _phoneError;
  String? _passwordError;
  String? _submitError;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    _regionController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  bool _validate() {
    bool valid = true;
    setState(() {
      _nameError = null;
      _phoneError = null;
      _passwordError = null;
      _submitError = null;

      final name = _nameController.text.trim();
      if (name.isEmpty) {
        _nameError = 'Please enter manager full name';
        valid = false;
      } else if (name.length < 2) {
        _nameError = 'Name must be at least 2 characters';
        valid = false;
      }

      final phone =
          _phoneController.text.trim().replaceAll(RegExp(r'\D'), '');
      if (phone.isEmpty) {
        _phoneError = 'Please enter mobile number';
        valid = false;
      } else if (phone.length < 8 || phone.length > 20) {
        _phoneError = 'Enter a valid phone (8-20 digits)';
        valid = false;
      }

      if (_passwordController.text.length < 8) {
        _passwordError = 'Password must be at least 8 characters';
        valid = false;
      }
    });

    return valid;
  }

  Future<void> _handleSave() async {
    if (!_validate()) return;

    setState(() => _isSubmitting = true);

    final success = await widget.onSubmit(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim().replaceAll(RegExp(r'\D'), ''),
      password: _passwordController.text,
      email: _emailController.text.trim().isNotEmpty
          ? _emailController.text.trim()
          : null,
      assignedRegion: _regionController.text.trim().isNotEmpty
          ? _regionController.text.trim()
          : null,
      department: _departmentController.text.trim().isNotEmpty
          ? _departmentController.text.trim()
          : null,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _submitError = widget.errorMessage?.call() ??
              'Failed to create manager. Please check details and try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      key: const Key('create_manager_sheet'),
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
                            'MANAGERS ADMIN',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: AppColors.textFaint,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Add a Manager',
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
                      key: const Key('create_manager_error'),
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

                  AppTextField(
                    key: const Key('create_manager_name_field'),
                    label: 'Full Name *',
                    hint: 'e.g. Anil Kumar',
                    controller: _nameController,
                    errorText: _nameError,
                    prefixIcon: const Icon(Icons.person_outline_rounded,
                        size: 18, color: AppColors.textFaint),
                  ),
                  const SizedBox(height: 12),

                  AppTextField(
                    key: const Key('create_manager_phone_field'),
                    label: 'Phone (8-20 digits) *',
                    hint: '9876543210',
                    controller: _phoneController,
                    errorText: _phoneError,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(20),
                    ],
                    prefixIcon: const Icon(Icons.phone_outlined,
                        size: 18, color: AppColors.textFaint),
                  ),
                  const SizedBox(height: 12),

                  AppTextField(
                    key: const Key('create_manager_password_field'),
                    label: 'Password (min. 8 chars) *',
                    hint: 'Min. 8 characters',
                    controller: _passwordController,
                    errorText: _passwordError,
                    isPassword: true,
                    prefixIcon: const Icon(Icons.lock_outline_rounded,
                        size: 18, color: AppColors.textFaint),
                  ),
                  const SizedBox(height: 12),

                  AppTextField(
                    key: const Key('create_manager_email_field'),
                    label: 'Email (Optional)',
                    hint: 'manager@example.com',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: const Icon(Icons.email_outlined,
                        size: 18, color: AppColors.textFaint),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          key: const Key('create_manager_region_field'),
                          label: 'Assigned Region (Optional)',
                          hint: 'e.g. Kurnool',
                          controller: _regionController,
                          prefixIcon: const Icon(Icons.public_outlined,
                              size: 18, color: AppColors.textFaint),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AppTextField(
                          key: const Key('create_manager_department_field'),
                          label: 'Department (Optional)',
                          hint: 'e.g. Procurement',
                          controller: _departmentController,
                          prefixIcon: const Icon(Icons.business_outlined,
                              size: 18, color: AppColors.textFaint),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton.icon(
                    key: const Key('create_manager_submit_btn'),
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
                        : const Icon(Icons.person_add_alt_1_rounded,
                            size: 18),
                    label:
                        Text(_isSubmitting ? 'Creating...' : 'Create Manager'),
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
