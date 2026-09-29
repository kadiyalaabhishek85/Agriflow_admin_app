import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/network/error_sanitizer.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/entities/auth_exception.dart';
import '../controllers/auth_controller.dart';

/// Password reset screen integrated with FastAPI OTP reset endpoints and HTML helpline assistance.
class ForgotPasswordScreen extends StatefulWidget {
  static const String otpTimestampKey = 'agriflow_forgot_password_otp_timestamp';
  static const String otpPhoneKey = 'agriflow_forgot_password_otp_phone';

  final AuthController authController;
  final String? initialPhone;
  final SharedPreferences? prefs;

  const ForgotPasswordScreen({
    super.key,
    required this.authController,
    this.initialPhone,
    this.prefs,
  });

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();

  bool _codeSent = false;
  bool _isLoading = false;
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;
  String? _statusMessage;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialPhone != null) {
      _phoneController.text = widget.initialPhone!;
    }
    _initCooldown();
  }

  Future<void> _initCooldown() async {
    try {
      final prefs = widget.prefs ?? await SharedPreferences.getInstance();
      final savedTs = prefs.getInt(ForgotPasswordScreen.otpTimestampKey);
      if (savedTs != null) {
        final now = DateTime.now().millisecondsSinceEpoch;
        final elapsed = (now - savedTs) ~/ 1000;
        final remaining = 60 - elapsed;
        if (remaining > 0 && remaining <= 60) {
          final savedPhone = prefs.getString(ForgotPasswordScreen.otpPhoneKey);
          if (mounted) {
            setState(() {
              _cooldownSeconds = remaining;
              if (savedPhone != null && savedPhone.isNotEmpty && _phoneController.text.isEmpty) {
                _phoneController.text = savedPhone;
              }
              _codeSent = true;
            });
            _startCooldownTimer();
          }
          return;
        } else {
          // Expired or out-of-range timestamp
          await prefs.remove(ForgotPasswordScreen.otpTimestampKey);
        }
      }
    } catch (_) {
      // Corrupted timestamp - safely remove
      try {
        final prefs = widget.prefs ?? await SharedPreferences.getInstance();
        await prefs.remove(ForgotPasswordScreen.otpTimestampKey);
      } catch (_) {}
    }
  }

  void _startCooldownTimer() {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_cooldownSeconds <= 1) {
        timer.cancel();
        setState(() {
          _cooldownSeconds = 0;
        });
      } else {
        setState(() {
          _cooldownSeconds--;
        });
      }
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _phoneController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSendOtp() async {
    if (_cooldownSeconds > 0) return;

    final phone = _phoneController.text.trim().replaceAll(RegExp(r'[\s\-()]'), '');
    if (!RegExp(r'^\d{10}$').hasMatch(phone)) {
      setState(() {
        _errorMessage = 'Please enter a valid 10-digit mobile number.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _statusMessage = null;
    });

    try {
      await widget.authController.requestPasswordResetOtp(phone: phone);
      final prefs = widget.prefs ?? await SharedPreferences.getInstance();
      await prefs.setInt(ForgotPasswordScreen.otpTimestampKey, DateTime.now().millisecondsSinceEpoch);
      await prefs.setString(ForgotPasswordScreen.otpPhoneKey, phone);

      if (!mounted) return;
      setState(() {
        _codeSent = true;
        _cooldownSeconds = 60;
        _statusMessage = 'OTP code sent to $phone. Please enter it below.';
      });
      _startCooldownTimer();
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = ErrorSanitizer.sanitize(e);
      });
    } catch (e) {
      setState(() {
        _errorMessage = ErrorSanitizer.sanitize(e, defaultAction: 'Sending OTP code');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleResetPassword() async {
    final phone = _phoneController.text.trim().replaceAll(RegExp(r'[\s\-()]'), '');
    final code = _codeController.text.trim();
    final newPassword = _newPasswordController.text;

    if (code.isEmpty) {
      setState(() => _errorMessage = 'Please enter the verification code.');
      return;
    }
    if (newPassword.length < 8) {
      setState(() => _errorMessage = 'New password must be at least 8 characters.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.authController.resetPasswordWithOtp(
        phone: phone,
        code: code,
        newPassword: newPassword,
      );

      final prefs = widget.prefs ?? await SharedPreferences.getInstance();
      await prefs.remove(ForgotPasswordScreen.otpTimestampKey);
      await prefs.remove(ForgotPasswordScreen.otpPhoneKey);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset successfully! Please sign in with your new password.'),
          backgroundColor: AppColors.canopy,
        ),
      );
      Navigator.of(context).pop();
    } on AuthException catch (e) {
      setState(() => _errorMessage = ErrorSanitizer.sanitize(e));
    } catch (e) {
      setState(() => _errorMessage = ErrorSanitizer.sanitize(e, defaultAction: 'Resetting password'));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          'Reset Password',
          style: AppTypography.titleMedium(color: AppColors.text),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.text),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Recover Account Access',
                  style: AppTypography.titleLarge(color: AppColors.adminNavyDeep),
                ),
                const SizedBox(height: 6),
                Text(
                  'Reset your password via verified mobile OTP or reach out directly to the administration support line.',
                  style: AppTypography.bodySmall(color: AppColors.textMuted),
                ),
                const SizedBox(height: 20),

                // Helpline Card from approved HTML
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
                              'Sri Siva Sai Seeds Support Helpline',
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

                const SizedBox(height: 24),

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
                      style: AppTypography.bodySmall(
                        color: AppColors.bad,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                if (_statusMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.goodBg,
                      borderRadius: BorderRadius.circular(AppColors.radiusMd),
                      border: Border.all(color: AppColors.good.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      _statusMessage!,
                      style: AppTypography.bodySmall(
                        color: AppColors.good,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Step 1: Mobile Number
                Text(
                  'Registered Mobile Number',
                  style: AppTypography.titleSmall(color: AppColors.text),
                ),

                const SizedBox(height: 6),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  enabled: !_isLoading && !_codeSent,
                  decoration: InputDecoration(
                    hintText: '10-digit mobile number',
                    prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppColors.radiusMd),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                if (!_codeSent) ...[
                  ElevatedButton(
                    onPressed: (_isLoading || _cooldownSeconds > 0) ? null : _handleSendOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.canopy,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppColors.radiusMd),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(_cooldownSeconds > 0
                            ? 'Resend OTP in ${_cooldownSeconds}s'
                            : 'Send Reset OTP Code'),
                  ),
                ] else ...[
                  // Step 2: Verification Code
                  Text('Verification Code', style: AppTypography.titleSmall(color: AppColors.text)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      hintText: 'Enter code received',
                      prefixIcon: const Icon(Icons.key_rounded, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppColors.radiusMd),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _cooldownSeconds > 0
                            ? 'Resend OTP in ${_cooldownSeconds}s'
                            : "Didn't receive code?",
                        style: AppTypography.bodySmall(color: AppColors.textMuted),
                      ),
                      if (_cooldownSeconds <= 0)
                        TextButton(
                          onPressed: _isLoading ? null : _handleSendOtp,
                          child: const Text('Resend OTP'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // New Password
                  Text('New Password (min 8 chars)', style: AppTypography.titleSmall(color: AppColors.text)),

                  const SizedBox(height: 6),
                  TextField(
                    controller: _newPasswordController,
                    obscureText: true,
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      hintText: 'Enter new password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppColors.radiusMd),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleResetPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.adminNavy,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppColors.radiusMd),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Reset Password & Sign In'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
