import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../controllers/auth_controller.dart';
import 'forgot_password_screen.dart';

/// Native Login Screen matching approved HTML #flow-login and FastAPI backend contract.
class LoginScreen extends StatefulWidget {
  final AuthController authController;

  const LoginScreen({
    super.key,
    required this.authController,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberMe = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Mobile number is required.';
    }
    final cleaned = value.trim().replaceAll(RegExp(r'[\s\-()]'), '');
    if (!RegExp(r'^\d{10}$').hasMatch(cleaned)) {
      return 'Enter a valid 10-digit mobile number.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required.';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters.';
    }
    return null;
  }

  Future<void> _handleLogin() async {
    widget.authController.clearError();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final phone = _phoneController.text.trim().replaceAll(RegExp(r'[\s\-()]'), '');
    final password = _passwordController.text;

    await widget.authController.login(
      phone: phone,
      password: password,
      rememberMe: _rememberMe,
    );
  }

  void _openForgotPassword() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ForgotPasswordScreen(
          authController: widget.authController,
          initialPhone: _phoneController.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.surface,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Form(
                  key: _formKey,
                  child: ListenableBuilder(
                    listenable: widget.authController,
                    builder: (context, _) {
                      final state = widget.authController.state;
                      final isLoading = state.isAuthenticating;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Brand Logo matching HTML #flow-login
                          Center(
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.adminNavyLight.withValues(alpha: 0.3),
                                  width: 2,
                                ),
                                boxShadow: AppColors.shadowSm,
                              ),
                              padding: const EdgeInsets.all(4),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.asset(
                                  'assets/images/sri_siva_sai_seeds_logo.png',
                                  fit: BoxFit.contain,
                                  filterQuality: FilterQuality.high,
                                  semanticLabel: 'Sri Siva Sai Seeds Logo',
                                ),
                              ),
                            ),
                          ),

                        const SizedBox(height: 16),

                        // Title matching HTML
                        Text(
                          'Sri Siva Sai Seeds Admin Console',
                          style: AppTypography.titleMedium(
                            color: AppColors.adminNavyDeep,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 6),

                        // Subtitle
                        Text(
                          'Sign in to manage operations for Sri Siva Sai Seeds',
                          style: AppTypography.bodySmall(
                            color: AppColors.textMuted,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 24),

                        // Error Banner (if authentication failed)
                        if (state.errorMessage != null && state.errorMessage!.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.badBg,
                              borderRadius: BorderRadius.circular(AppColors.radiusMd),
                              border: Border.all(
                                color: AppColors.bad.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  color: AppColors.bad,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    state.errorMessage!,
                                    style: AppTypography.bodySmall(
                                      color: AppColors.bad,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Phone Field
                        Text(
                          'Mobile number',
                          style: AppTypography.titleSmall(color: AppColors.text),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          enabled: !isLoading,
                          validator: _validatePhone,
                          style: AppTypography.bodyMedium(color: AppColors.text),
                          decoration: InputDecoration(
                            hintText: '10-digit mobile number',
                            hintStyle: AppTypography.bodyMedium(
                              color: AppColors.textFaint,
                            ),
                            prefixIcon: const Icon(
                              Icons.phone_outlined,
                              color: AppColors.textFaint,
                              size: 20,
                            ),
                            filled: true,
                            fillColor: AppColors.surfaceAlt,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppColors.radiusMd),
                              borderSide: const BorderSide(color: AppColors.line),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppColors.radiusMd),
                              borderSide: const BorderSide(color: AppColors.line),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppColors.radiusMd),
                              borderSide: const BorderSide(
                                color: AppColors.canopy,
                                width: 1.5,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppColors.radiusMd),
                              borderSide: const BorderSide(color: AppColors.alert),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Password Field
                        Text(
                          'Password',
                          style: AppTypography.titleSmall(color: AppColors.text),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          enabled: !isLoading,
                          validator: _validatePassword,
                          onFieldSubmitted: (_) => _handleLogin(),
                          style: AppTypography.bodyMedium(color: AppColors.text),
                          decoration: InputDecoration(
                            hintText: 'Enter your password',
                            hintStyle: AppTypography.bodyMedium(
                              color: AppColors.textFaint,
                            ),
                            prefixIcon: const Icon(
                              Icons.lock_outline_rounded,
                              color: AppColors.textFaint,
                              size: 20,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: AppColors.textFaint,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            filled: true,
                            fillColor: AppColors.surfaceAlt,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppColors.radiusMd),
                              borderSide: const BorderSide(color: AppColors.line),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppColors.radiusMd),
                              borderSide: const BorderSide(color: AppColors.line),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppColors.radiusMd),
                              borderSide: const BorderSide(
                                color: AppColors.canopy,
                                width: 1.5,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppColors.radiusMd),
                              borderSide: const BorderSide(color: AppColors.alert),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Remember Me Checkbox matching HTML
                        Row(
                          children: [
                            SizedBox(
                              height: 24,
                              width: 24,
                              child: Checkbox(
                                value: _rememberMe,
                                activeColor: AppColors.adminNavy,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                onChanged: isLoading
                                    ? null
                                    : (val) {
                                        setState(() {
                                          _rememberMe = val ?? true;
                                        });
                                      },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: GestureDetector(
                                onTap: isLoading
                                    ? null
                                    : () {
                                        setState(() {
                                          _rememberMe = !_rememberMe;
                                        });
                                      },
                                child: Text(
                                  'Remember me on this device',
                                  style: AppTypography.bodySmall(
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Login Button
                        ElevatedButton(
                          onPressed: isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.adminNavy,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: AppColors.adminNavy.withValues(alpha: 0.6),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppColors.radiusMd),
                            ),
                            elevation: 0,
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Log in',
                                  style: AppTypography.titleSmall(color: Colors.white),
                                ),
                        ),

                        const SizedBox(height: 20),

                        // Access Info Card matching HTML #flow-login
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceAlt,
                            borderRadius: BorderRadius.circular(AppColors.radiusMd),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.help_outline_rounded,
                                color: AppColors.adminNavyDeep,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Sign in with your registered 10-digit mobile number and password assigned by Sri Siva Sai Seeds administration.',
                                  style: AppTypography.bodySmall(
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Forgot Password Link matching HTML
                        Center(
                          child: TextButton(
                            onPressed: isLoading ? null : _openForgotPassword,
                            child: Text(
                              'Forgot password? Call us for help',
                              style: AppTypography.titleSmall(
                                color: AppColors.adminNavy,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          ),
        ),
      ),
    );
  }
}
