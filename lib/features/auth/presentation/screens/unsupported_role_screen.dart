import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../controllers/auth_controller.dart';

/// Controlled access-denied screen for unsupported/unauthorized roles (e.g. farmers).
class UnsupportedRoleScreen extends StatelessWidget {
  final AuthController authController;
  final String roleName;

  const UnsupportedRoleScreen({
    super.key,
    required this.authController,
    required this.roleName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.badBg,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.bad.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.shield_outlined,
                        color: AppColors.bad,
                        size: 36,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  Text(
                    'Access Restricted',
                    style: AppTypography.titleLarge(
                      color: AppColors.adminNavyDeep,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Your account role ($roleName) is not authorized to access the Sri Siva Sai Seeds Admin & Manager console.\n\nPlease log in with an authorized Admin or Manager account.',
                    style: AppTypography.bodyMedium(
                      color: AppColors.textMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => authController.logout(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.adminNavy,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppColors.radiusMd),
                      ),
                    ),
                    child: const Text('Return to Login'),
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
