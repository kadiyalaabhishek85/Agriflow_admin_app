import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/navigation/nav_destination.dart';
import '../../../../core/utils/app_dates.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/squircle_icon_button.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/entities/notification_item.dart';
import '../controllers/notification_controller.dart';
import '../services/system_notification_service.dart';
import '../../../../core/widgets/sheet_drag_handle.dart';

/// Full-screen notification center matching the web app's NotificationCenter
/// component with AgriFlow Admin/Manager theme applied.
class NotificationScreen extends StatelessWidget {
  final NotificationController controller;
  final VoidCallback? onBack;

  const NotificationScreen({
    super.key,
    required this.controller,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  if (onBack != null) ...[
                    SquircleIconButton.back(onTap: onBack),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notifications',
                          style: AppTypography.titleLarge(
                              color: AppColors.adminNavyDeep),
                        ),
                        Text(
                          controller.hasUnread
                              ? '${controller.unreadCount} unread'
                              : 'All caught up',
                          style: AppTypography.bodySmall(
                              color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  if (controller.hasUnread)
                    TextButton.icon(
                      onPressed: () => controller.markAllRead(),
                      icon: const Icon(Icons.done_all_rounded, size: 16),
                      label: Text(
                        'Mark all read',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.canopyDeep,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                      ),
                    ),
                ],
              ),
            ),

            const Divider(height: 1, color: AppColors.line),

            // Content
            Expanded(
              child: _buildContent(context),
            ),
          ],
        );
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    if (controller.isLoading && controller.notifications.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.adminNavy),
      );
    }

    if (controller.error != null && controller.notifications.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: AppErrorView(
          message: controller.error!,
          onRetry: () => controller.refresh(),
        ),
      );
    }

    if (controller.notifications.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: EmptyStateView(
          title: 'No notifications',
          description: 'You\'re all caught up! New notifications will appear here when business events occur.',
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.adminNavy,
      onRefresh: () => controller.refresh(),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: controller.notifications.length,
        separatorBuilder: (context, i) =>
            const Divider(height: 1, indent: 72, color: AppColors.line),
        itemBuilder: (context, index) {
          final item = controller.notifications[index];
          return _NotificationTile(
            item: item,
            onTap: () => _showDetail(context, item),
          );
        },
      ),
    );
  }

  void _showDetail(BuildContext context, NotificationItem item) {
    if (!item.isRead) {
      controller.markRead(item.id);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _NotificationDetailSheet(item: item),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationItem item;
  final VoidCallback onTap;

  const _NotificationTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: item.isRead ? Colors.transparent : AppColors.surfaceAlt,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(_icon, size: 20, color: _iconColor),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: AppTypography.titleSmall(
                        color: item.isRead
                            ? AppColors.textMuted
                            : AppColors.text,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.message,
                      style: AppTypography.bodySmall(
                          color: AppColors.textMuted),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.timeAgo,
                      style: GoogleFonts.manrope(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textFaint,
                      ),
                    ),
                  ],
                ),
              ),
              // Unread dot
              if (!item.isRead)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 6, left: 8),
                  decoration: const BoxDecoration(
                    color: AppColors.canopyDeep,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData get _icon {
    switch (item.type) {
      case NotificationType.success:
        return Icons.check_circle_rounded;
      case NotificationType.warning:
        return Icons.warning_amber_rounded;
      case NotificationType.error:
        return Icons.cancel_rounded;
      case NotificationType.info:
        return Icons.info_outline_rounded;
    }
  }

  Color get _iconColor {
    switch (item.type) {
      case NotificationType.success:
        return AppColors.canopyDeep;
      case NotificationType.warning:
        return AppColors.amber;
      case NotificationType.error:
        return AppColors.bad;
      case NotificationType.info:
        return AppColors.adminNavy;
    }
  }

  Color get _iconBgColor {
    switch (item.type) {
      case NotificationType.success:
        return AppColors.goodBg;
      case NotificationType.warning:
        return AppColors.warnBg;
      case NotificationType.error:
        return AppColors.badBg;
      case NotificationType.info:
        return const Color(0xFFECF1FA);
    }
  }
}

class _NotificationDetailSheet extends StatelessWidget {
  final NotificationItem item;

  const _NotificationDetailSheet({required this.item});

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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          SheetDragHandle(),
          const SizedBox(height: 16),
          // Title with icon
          Row(
            children: [
              Icon(
                _icon,
                color: _iconColor,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.title,
                  style: AppTypography.titleMedium(color: AppColors.text),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _formatDate(item.createdAt),
            style: AppTypography.bodySmall(color: AppColors.textFaint),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.line),
          const SizedBox(height: 16),
          // Message
          Text(
            item.message,
            style: AppTypography.bodyMedium(color: AppColors.text),
          ),
          if (item.referenceType != null) ...[
            const SizedBox(height: 12),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: AppColors.surfaceAlt,
              child: Row(
                children: [
                  const Icon(Icons.link_rounded,
                      size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${item.referenceType}${item.referenceId != null ? ' #${item.referenceId!.substring(0, 8)}' : ''}',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_openRouteId != null) ...[
            const SizedBox(height: 14),
            // Module-level deep-link: resolves through the same
            // role-validated path as a system-notification tap. The exact
            // record is not claimed to be opened (this app navigates at
            // route level; reference ids are shown above for identity).
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  NotificationTapBridge.pendingNotificationId.value =
                      item.id;
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.adminNavy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppColors.radiusMd),
                  ),
                ),
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: Text(
                  'Open ${NavDestination.fromId(_openRouteId!).title}',
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          // Close button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.adminNavy,
                side: const BorderSide(color: AppColors.line),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppColors.radiusMd),
                ),
              ),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }

  String? get _openRouteId =>
      NotificationDestinationResolver.routeFor(item.referenceType);

  IconData get _icon {
    switch (item.type) {
      case NotificationType.success:
        return Icons.check_circle_rounded;
      case NotificationType.warning:
        return Icons.warning_amber_rounded;
      case NotificationType.error:
        return Icons.cancel_rounded;
      case NotificationType.info:
        return Icons.info_outline_rounded;
    }
  }

  Color get _iconColor {
    switch (item.type) {
      case NotificationType.success:
        return AppColors.canopyDeep;
      case NotificationType.warning:
        return AppColors.amber;
      case NotificationType.error:
        return AppColors.bad;
      case NotificationType.info:
        return AppColors.adminNavy;
    }
  }

  String _formatDate(DateTime dt) {
    return AppDates.dateTimeLabel(dt);
  }
}
