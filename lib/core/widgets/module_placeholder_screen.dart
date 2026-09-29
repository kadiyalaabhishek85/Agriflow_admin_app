import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import '../models/user_role.dart';
import 'status_pill.dart';

/// Clean placeholder screen for future business modules.
/// Strictly displays navigation status without mock business data.
class ModulePlaceholderScreen extends StatelessWidget {
  final String title;
  final String destinationId;
  final IconData icon;
  final UserRole role;
  final VoidCallback? onBackToDashboard;

  const ModulePlaceholderScreen({
    super.key,
    required this.title,
    required this.destinationId,
    required this.icon,
    required this.role,
    this.onBackToDashboard,
  });

  @override
  Widget build(BuildContext context) {
    // Credits ledger and Cache management have no live contract at all —
    // honest BLOCKED copy instead of a misleading "coming later" promise.
    final bool backendBlocked = destinationId == 'credits' ||
        destinationId == 'cache-management';
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppColors.radiusMd),
              border: Border.all(color: AppColors.line),
              boxShadow: AppColors.shadowSm,
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      size: 26,
                      color: role.isAdmin ? AppColors.adminNavy : AppColors.canopy,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: AppTypography.titleMedium(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          StatusPill(
                            label: role.displayLabel,
                            type: role.isAdmin ? PillType.info : PillType.good,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Route: $destinationId',
                        style: AppTypography.bodySmall(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Milestone Status Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppColors.radiusMd),
              border: Border.all(color: AppColors.line),
              boxShadow: AppColors.shadowSm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.line),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.hourglass_empty_rounded,
                      size: 32,
                      color: AppColors.adminNavyLight,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: AppTypography.displaySmall(),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    backendBlocked ? 'Blocked (backend)' : 'Coming in a later milestone',
                    style: AppTypography.titleSmall(
                      color: role.isAdmin ? AppColors.adminNavy : AppColors.canopy,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  backendBlocked
                      ? 'Backend API required — to be supplied by Syed. This module has no '
                          'contract in the live OpenAPI, so no data or actions are shown here.'
                      : 'This business module is part of future milestone implementation. The navigation shell, drawer access, and role routing for this destination are verified.',
                  style: AppTypography.bodyMedium(color: AppColors.textMuted),
                  textAlign: TextAlign.center,
                ),
                if (onBackToDashboard != null) ...[
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: onBackToDashboard,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.text,
                      side: const BorderSide(color: AppColors.line),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppColors.radiusSm),
                      ),
                    ),
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: Text(
                      'Back to Dashboard',
                      style: AppTypography.titleSmall(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
