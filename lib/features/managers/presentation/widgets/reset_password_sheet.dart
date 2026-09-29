import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/squircle_icon_button.dart';
import '../../../../core/widgets/sheet_drag_handle.dart';

/// Bottom sheet for resetting a manager's password
/// (`POST /api/v1/managers/{id}/reset-password` — ResetPasswordRequest
/// { new_password }: 8-128 chars).
class ResetPasswordSheet extends StatefulWidget {
  final String managerName;
  final Future<String?> Function({required String newPassword}) onSubmit;
  final String? Function()? errorMessage;

  const ResetPasswordSheet({
    super.key,
    required this.managerName,
    required this.onSubmit,
    this.errorMessage,
  });

  static Future<String?> show({
    required BuildContext context,
    required String managerName,
    required Future<String?> Function({required String newPassword}) onSubmit,
    String? Function()? errorMessage,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ResetPasswordSheet(
        managerName: managerName,
        onSubmit: onSubmit,
        errorMessage: errorMessage,
      ),
    );
  }

  @override
  State<ResetPasswordSheet> createState() => _ResetPasswordSheetState();
}

class _ResetPasswordSheetState extends State<ResetPasswordSheet> {
  final _formKey = GlobalKey<FormState>();

  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  String? _passwordError;
  String? _confirmError;
  String? _submitError;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool _validate() {
    bool valid = true;
    setState(() {
      _passwordError = null;
      _confirmError = null;
      _submitError = null;

      if (_passwordController.text.length < 8) {
        _passwordError = 'Password must be at least 8 characters';
        valid = false;
      }
      if (_confirmController.text != _passwordController.text) {
        _confirmError = 'Passwords do not match';
        valid = false;
      }
    });

    return valid;
  }

  Future<void> _handleSave() async {
    if (!_validate()) return;

    setState(() => _isSubmitting = true);

    final message = await widget.onSubmit(
      newPassword: _passwordController.text,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (message != null) {
        Navigator.of(context).pop(message);
      } else {
        setState(() {
          _submitError = widget.errorMessage?.call() ??
              'Failed to reset password. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      key: const Key('reset_password_sheet'),
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
                        children: [
                          const Text(
                            'RESET PASSWORD',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: AppColors.textFaint,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.managerName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.text,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                      key: const Key('reset_password_error'),
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
                    key: const Key('reset_password_field'),
                    label: 'New Password (min. 8 chars) *',
                    hint: 'Min. 8 characters',
                    controller: _passwordController,
                    errorText: _passwordError,
                    isPassword: true,
                    prefixIcon: const Icon(Icons.lock_outline_rounded,
                        size: 18, color: AppColors.textFaint),
                  ),
                  const SizedBox(height: 12),

                  AppTextField(
                    key: const Key('reset_password_confirm_field'),
                    label: 'Confirm New Password *',
                    hint: 'Repeat the password',
                    controller: _confirmController,
                    errorText: _confirmError,
                    isPassword: true,
                    prefixIcon: const Icon(Icons.lock_reset_outlined,
                        size: 18, color: AppColors.textFaint),
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton.icon(
                    key: const Key('reset_password_submit_btn'),
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
                        : const Icon(Icons.key_outlined, size: 18),
                    label: Text(
                        _isSubmitting ? 'Resetting...' : 'Reset Password'),
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
