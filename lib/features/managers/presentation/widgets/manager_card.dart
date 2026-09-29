import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/squircle_icon_button.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../domain/entities/manager_item.dart';
import '../../../../core/widgets/app_card.dart';

/// Card for one manager account: avatar, identity, role/region line,
/// status pill, and admin actions (status toggle + password reset).
class ManagerCard extends StatelessWidget {
  final ManagerItem manager;
  final VoidCallback onToggleStatus;
  final VoidCallback onResetPassword;

  const ManagerCard({
    super.key,
    required this.manager,
    required this.onToggleStatus,
    required this.onResetPassword,
  });

  @override
  Widget build(BuildContext context) {
    final subtitleParts = <String>[
      manager.phone,
      if (manager.role == 'super_admin') 'Super Admin',
      if (manager.assignedRegion != null &&
          manager.assignedRegion!.isNotEmpty)
        manager.assignedRegion!,
      if (manager.department != null && manager.department!.isNotEmpty)
        manager.department!,
    ];

    return AppCard(
      key: Key('manager_card_${manager.id}'),
      margin: const EdgeInsets.only(bottom: 10),
      borderRadius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          // Avatar with initials
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFE5F6EA),
              borderRadius: BorderRadius.circular(21),
              border: Border.all(
                color: AppColors.canopyLight.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              manager.initials,
              style: const TextStyle(
                color: AppColors.canopyDeep,
                fontWeight: FontWeight.w800,
                fontSize: 14.5,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Name & meta
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  manager.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitleParts.join(' · '),
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          StatusPill.fromStatus(manager.status),
          const SizedBox(width: 6),

          // Activate / suspend toggle
          SquircleIconButton(
            key: Key('manager_status_btn_${manager.id}'),
            icon: Icon(
              manager.isSuspended
                  ? Icons.play_circle_outline_rounded
                  : Icons.pause_circle_outline_rounded,
              size: 16,
              color: manager.isSuspended ? AppColors.good : AppColors.warn,
            ),
            size: 32,
            tooltip: manager.isSuspended ? 'Activate' : 'Suspend',
            onTap: onToggleStatus,
          ),
          const SizedBox(width: 6),

          // Reset password
          SquircleIconButton(
            key: Key('manager_reset_pwd_btn_${manager.id}'),
            icon: const Icon(
              Icons.key_outlined,
              size: 16,
              color: AppColors.adminNavy,
            ),
            size: 32,
            tooltip: 'Reset password',
            onTap: onResetPassword,
          ),
        ],
      ),
    );
  }
}
