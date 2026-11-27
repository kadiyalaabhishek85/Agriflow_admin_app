import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/error_sanitizer.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/squircle_icon_button.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../help/presentation/screens/help_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../../core/widgets/sheet_drag_handle.dart';

/// Production-ready Account and Profile Management Screen.
/// Provides:
/// - User profile display (Name, Phone, Role, Account Status)
/// - Profile self-edit via PATCH /api/v1/users/me (name + email)
/// - Settings & Help navigation (M10)
/// - Security & Password change flow via POST /api/v1/auth/change-password
/// - Session details and logout trigger
class AccountScreen extends StatefulWidget {
  final AuthSession session;
  final VoidCallback onLogout;
  final VoidCallback? onBack;
  final http.Client? httpClient;

  /// When provided, a successful profile edit is applied to the active
  /// session so shells/drawer headers rebuild with the updated name/email.
  final AuthController? authController;

  const AccountScreen({
    super.key,
    required this.session,
    required this.onLogout,
    this.onBack,
    this.httpClient,
    this.authController,
  });

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  /// Latest profile after a successful edit; falls back to [AuthSession.user]
  /// (which AuthController.applyUser also refreshes when a controller exists).
  AuthUser? _localUser;

  void _showEditProfileSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EditProfileSheet(
        user: _localUser ?? widget.session.user,
        accessToken: widget.session.accessToken,
        httpClient: widget.httpClient,
        onSaved: (updated) {
          widget.authController?.applyUser(updated);
          if (mounted) {
            setState(() => _localUser = updated);
          }
          AppToast.show(context, 'Profile updated successfully');
        },
      ),
    );
  }

  void _showChangePasswordDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ChangePasswordSheet(
        accessToken: widget.session.accessToken,
        httpClient: widget.httpClient,
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusMd),
        ),
        title: Text(
          'Log Out',
          style: AppTypography.titleMedium(color: AppColors.text),
        ),
        content: Text(
          'Are you sure you want to log out of your session on this device?',
          style: AppTypography.bodySmall(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: AppTypography.titleSmall(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              widget.onLogout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.bad,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppColors.radiusSm),
              ),
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _localUser ?? widget.session.user;
    final role = widget.session.role;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with back button if available
          Row(
            children: [
              if (widget.onBack != null) ...[
                SquircleIconButton.back(onTap: widget.onBack),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account & Security',
                      style: AppTypography.titleLarge(color: AppColors.adminNavyDeep),
                    ),
                    Text(
                      'Manage your credentials and session settings',
                      style: AppTypography.bodySmall(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Profile Summary Card matching AgriFlow theme
          AppCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.adminNavyDeep, AppColors.adminNavy],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.adminNavyLight.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                        style: GoogleFonts.manrope(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name.isNotEmpty ? user.name : 'Authorized User',
                            style: AppTypography.titleMedium(color: AppColors.text),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user.phone.isNotEmpty ? user.phone : 'No phone linked',
                            style: AppTypography.bodySmall(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    StatusPill.fromStatus(user.status.isNotEmpty ? user.status : 'active'),
                  ],
                ),
                const SizedBox(height: 18),
                const Divider(height: 1, color: AppColors.line),
                const SizedBox(height: 14),

                // Details grid
                _buildInfoRow(
                  icon: Icons.badge_outlined,
                  label: 'System Role',
                  value: role.displayLabel,
                ),
                const SizedBox(height: 10),
                _buildInfoRow(
                  icon: Icons.email_outlined,
                  label: 'Email Address',
                  value: user.email?.isNotEmpty == true ? user.email! : 'Not configured',
                ),
                const SizedBox(height: 10),
                _buildInfoRow(
                  icon: Icons.verified_user_outlined,
                  label: 'Account Status',
                  value: user.status.toUpperCase(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Account menu rows (HTML #screen-account menu: edit profile,
          // settings, help)
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                _buildMenuRow(
                  icon: Icons.person_outline_rounded,
                  title: 'Edit profile details',
                  onTap: _showEditProfileSheet,
                ),
                const Divider(height: 1, color: AppColors.line),
                _buildMenuRow(
                  icon: Icons.settings_outlined,
                  title: 'Settings & preferences',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                ),
                const Divider(height: 1, color: AppColors.line),
                _buildMenuRow(
                  icon: Icons.help_outline_rounded,
                  title: 'Help & support',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const HelpScreen()),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Security Settings
          Text('SECURITY & AUTHENTICATION', style: AppTypography.eyebrow()),
          const SizedBox(height: 10),

          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                Material(
                  color: Colors.transparent,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.lock_reset_rounded,
                        color: AppColors.adminNavy,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      'Change Password',
                      style: AppTypography.titleSmall(),
                    ),
                    subtitle: Text(
                      'Update your account access password',
                      style: AppTypography.bodySmall(color: AppColors.textMuted),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textFaint,
                    ),
                    onTap: _showChangePasswordDialog,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Helpline & Support Card
          AppCard(
            padding: const EdgeInsets.all(16),
            color: AppColors.surfaceAlt,
            child: Row(
              children: [
                const Icon(
                  Icons.support_agent_rounded,
                  color: AppColors.adminNavy,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Administrative Support Helpline',
                        style: AppTypography.titleSmall(),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '+91 95026 62924',
                        style: AppTypography.bodyMedium(
                          color: AppColors.canopyDeep,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Logout Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _confirmLogout,
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Log Out of Account'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.badBg,
                foregroundColor: AppColors.bad,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppColors.radiusMd),
                  side: BorderSide(color: AppColors.bad.withValues(alpha: 0.3)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textFaint),
        const SizedBox(width: 10),
        Text(
          label,
          style: AppTypography.bodySmall(color: AppColors.textMuted),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.titleSmall(color: AppColors.text),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuRow({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: AppColors.adminNavy, size: 20),
        ),
        title: Text(title, style: AppTypography.titleSmall()),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: AppColors.textFaint,
        ),
        onTap: onTap,
      ),
    );
  }
}

class _ChangePasswordSheet extends StatefulWidget {
  final String accessToken;
  final http.Client? httpClient;

  const _ChangePasswordSheet({
    required this.accessToken,
    this.httpClient,
  });

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitChangePassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'New passwords do not match.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final client = widget.httpClient ?? http.Client();
    final uri = Uri.parse('${ApiClient.defaultBaseUrl}/api/v1/auth/change-password');

    try {
      final response = await client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer ${widget.accessToken}',
            },
            body: jsonEncode({
              'current_password': _currentPasswordController.text,
              'new_password': _newPasswordController.text,
            }),
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (!mounted) return;
        Navigator.of(context).pop();
        AppToast.show(context, 'Password changed successfully!');
      } else {
        String msg = ErrorSanitizer.sanitize('HTTP ${response.statusCode}');
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map && decoded['detail'] != null) {
            msg = decoded['detail'].toString();
          } else if (decoded is Map && decoded['error'] is Map) {
            msg = (decoded['error'] as Map)['message']?.toString() ?? msg;
          }
        } catch (_) {}

        setState(() {
          _errorMessage = msg;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = ErrorSanitizer.sanitize(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppColors.radiusLg)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              SheetDragHandle(),
              const SizedBox(height: 16),
              Text(
                'Change Password',
                style: AppTypography.titleLarge(color: AppColors.adminNavyDeep),
              ),
              const SizedBox(height: 4),
              Text(
                'Enter your current password and a new secure password (minimum 8 characters).',
                style: AppTypography.bodySmall(color: AppColors.textMuted),
              ),
              const SizedBox(height: 20),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.badBg,
                    borderRadius: BorderRadius.circular(AppColors.radiusMd),
                    border: Border.all(color: AppColors.bad.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: AppTypography.bodySmall(color: AppColors.bad),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Current Password
              TextFormField(
                controller: _currentPasswordController,
                obscureText: _obscureCurrent,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  hintText: 'Enter current password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppColors.radiusMd),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureCurrent ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Current password is required.';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // New Password
              TextFormField(
                controller: _newPasswordController,
                obscureText: _obscureNew,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  hintText: 'At least 8 characters',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppColors.radiusMd),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNew ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscureNew = !_obscureNew),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'New password is required.';
                  if (val.length < 8) return 'Password must be at least 8 characters.';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Confirm New Password
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  hintText: 'Re-enter new password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppColors.radiusMd),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Please confirm your new password.';
                  return null;
                },
              ),
              const SizedBox(height: 22),

              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitChangePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.adminNavy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppColors.radiusMd),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Update Password'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Profile self-edit sheet backed by PATCH /api/v1/users/me
/// (`UpdateProfileRequest` = name + email only; phone is read-only and
/// zone/branch does not exist in the contract — never invented).
class _EditProfileSheet extends StatefulWidget {
  final AuthUser user;
  final String accessToken;
  final http.Client? httpClient;
  final void Function(AuthUser updated) onSaved;

  const _EditProfileSheet({
    required this.user,
    required this.accessToken,
    required this.onSaved,
    this.httpClient,
  });

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _emailController = TextEditingController(text: widget.user.email ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final client = widget.httpClient ?? http.Client();
    final uri = Uri.parse(
      '${ApiClient.defaultBaseUrl}/api/v1/users/me',
    );
    final email = _emailController.text.trim();

    try {
      final response = await client
          .patch(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer ${widget.accessToken}',
            },
            body: jsonEncode({
              'name': _nameController.text.trim(),
              'email': email.isEmpty ? null : email,
            }),
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        Map<String, dynamic> decoded = const {};
        try {
          final body = jsonDecode(response.body);
          if (body is Map<String, dynamic>) {
            final data = body['data'];
            decoded =
                data is Map<String, dynamic> ? data : body;
          }
        } catch (_) {}

        final updated = AuthUser.fromJson({
          ...widget.user.toJson(),
          ...decoded,
        });
        if (!mounted) return;
        widget.onSaved(updated);
        Navigator.of(context).pop();
      } else {
        String msg = ErrorSanitizer.sanitize('HTTP ${response.statusCode}');
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map && decoded['detail'] != null) {
            final detail = decoded['detail'];
            if (detail is List && detail.isNotEmpty) {
              final first = detail.first;
              msg = first is Map && first['msg'] != null
                  ? first['msg'].toString().replaceFirst('Value error, ', '')
                  : detail.first.toString();
            } else {
              msg = detail.toString();
            }
          } else if (decoded is Map && decoded['error'] is Map) {
            msg = (decoded['error'] as Map)['message']?.toString() ?? msg;
          }
        } catch (_) {}

        if (mounted) {
          setState(() => _errorMessage = msg);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = ErrorSanitizer.sanitize(e));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppColors.radiusLg)),
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
              Text(
                'Edit Profile',
                style: AppTypography.titleLarge(color: AppColors.adminNavyDeep),
              ),
              const SizedBox(height: 4),
              Text(
                'Update your name and email address (minimum 2 characters).',
                style: AppTypography.bodySmall(color: AppColors.textMuted),
              ),
              const SizedBox(height: 20),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.badBg,
                    borderRadius: BorderRadius.circular(AppColors.radiusMd),
                    border: Border.all(
                      color: AppColors.bad.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: AppTypography.bodySmall(color: AppColors.bad),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full name',
                  hintText: 'Enter your full name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppColors.radiusMd),
                  ),
                ),
                validator: (val) {
                  final v = val?.trim() ?? '';
                  if (v.isEmpty) return 'Name is required.';
                  if (v.length < 2) return 'Name must be at least 2 characters.';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'name@example.com (optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppColors.radiusMd),
                  ),
                ),
                validator: (val) {
                  final v = val?.trim() ?? '';
                  if (v.isEmpty) return null;
                  final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v);
                  if (!ok) return 'Enter a valid email address.';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Phone is read-only: UpdateProfileRequest (contract) only
              // accepts name + email.
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Phone',
                  style: AppTypography.bodySmall(color: AppColors.textMuted),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(AppColors.radiusMd),
                  border: Border.all(color: AppColors.line),
                ),
                child: Text(
                  widget.user.phone.isNotEmpty
                      ? widget.user.phone
                      : 'No phone linked',
                  style: AppTypography.titleSmall(color: AppColors.textFaint),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Phone changes: Backend API required — to be supplied by Syed.',
                style: AppTypography.caption(color: AppColors.textFaint),
              ),
              const SizedBox(height: 22),

              ElevatedButton(
                onPressed: _isSubmitting ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.adminNavy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppColors.radiusMd),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
