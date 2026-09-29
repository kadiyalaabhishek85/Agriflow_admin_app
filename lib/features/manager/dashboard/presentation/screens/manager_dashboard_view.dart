import 'package:flutter/material.dart';
import 'package:agriflow_admin/core/constants/app_colors.dart';
import 'package:agriflow_admin/core/constants/app_typography.dart';
import 'package:agriflow_admin/core/navigation/nav_destination.dart';
import 'package:agriflow_admin/features/auth/domain/entities/auth_session.dart';
import 'package:agriflow_admin/features/dashboard/shared/presentation/widgets/dashboard_mandi_strip.dart';
import 'package:agriflow_admin/features/dashboard/shared/presentation/widgets/dashboard_metric_card.dart';
import 'package:agriflow_admin/features/dashboard/shared/presentation/widgets/dashboard_state_views.dart';
import 'package:agriflow_admin/features/dashboard/shared/presentation/widgets/dashboard_summary_strip.dart';
import 'package:agriflow_admin/features/manager/dashboard/domain/entities/manager_dashboard_data.dart';
import 'package:agriflow_admin/features/manager/dashboard/presentation/controllers/manager_dashboard_controller.dart';

class ManagerDashboardView extends StatelessWidget {
  final AuthSession session;
  final ManagerDashboardController controller;
  final void Function(int tabIndex) onTabSelected;
  final void Function(String routeId) onNavigate;

  const ManagerDashboardView({
    super.key,
    required this.session,
    required this.controller,
    required this.onTabSelected,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final state = controller.state;

        if (state.isLoading || state.isInitial) {
          return const DashboardLoadingView();
        }

        if (state.isError && state.data == null) {
          return DashboardErrorView(
            message: state.errorMessage ?? 'Unable to connect to the AgriFlow server.',
            isNetworkError: state.isNetworkError,
            onRetry: controller.retry,
          );
        }

        final data = state.data ?? ManagerDashboardData.empty();

        return RefreshIndicator(
          onRefresh: controller.refreshDashboard,
          color: AppColors.canopy,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Greeting Header matching HTML
                _buildHeader(),
                const SizedBox(height: 18),

                // Summary Strip matching HTML
                DashboardSummaryStrip(
                  primaryAmount: '₹${data.revenueMtd.toStringAsFixed(0)}',
                  primaryLabel: 'Revenue (month-to-date)',
                  secondarySubtitle:
                      '${data.todaySeedOrders} seed orders · ${data.bookingsTotal} bookings · ${data.farmVisitsCount} visits',
                  onTap: () => onTabSelected(1),
                ),
                const SizedBox(height: 20),

                // Primary Operational KPI Cards (2x2 Grid)
                _buildOperationalGrid(data),
                const SizedBox(height: 24),

                // Quick Actions
                _buildQuickActions(),
                const SizedBox(height: 24),

                // More Tools (Operational portal for Manager - Strictly no admin tools)
                _buildOperationalTools(),
                const SizedBox(height: 24),

                // Today's Mandi Prices
                DashboardMandiStrip(
                  rates: data.mandiRates,
                  updatedAt: 'Live',
                  onViewAll: () => onNavigate(NavDestination.marketRates.id),
                ),
                const SizedBox(height: 24),

                // Recent Notifications / Alerts
                _buildRecentNotifications(data.recentNotifications),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    final name = session.user.name.isNotEmpty ? session.user.name : 'Manager';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                'Sri Siva Sai Seeds · Kurnool Zone',
                style: AppTypography.eyebrow(color: AppColors.textMuted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.canopy.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'FIELD MANAGER',
                style: AppTypography.caption(color: AppColors.canopy).copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Good Morning, $name 👋',
          style: AppTypography.displayMedium(color: AppColors.text).copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Here's what's happening across your operations today.",
          style: AppTypography.bodySmall(color: AppColors.textMuted),
        ),
      ],
    );
  }

  Widget _buildOperationalGrid(ManagerDashboardData data) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.05,
      children: [
        DashboardMetricCard(
          label: 'Pending seed orders',
          value: '${data.pendingSeedOrders}',
          icon: Icons.shopping_cart_outlined,
          iconColor: const Color(0xFF0369A1),
          iconBgColor: const Color(0xFFECF5FD),
          onTap: () => onTabSelected(0),
        ),
        DashboardMetricCard(
          label: 'Bookings',
          value: '${data.bookingsTotal}',
          icon: Icons.calendar_today_outlined,
          iconColor: AppColors.canopy,
          iconBgColor: const Color(0xFFF0F8EC),
          onTap: () => onTabSelected(1),
        ),
        DashboardMetricCard(
          label: 'Farm visits',
          value: '${data.farmVisitsCount}',
          icon: Icons.location_on_outlined,
          iconColor: AppColors.amber,
          iconBgColor: const Color(0xFFFDF5EC),
          deltaText: '${data.farmVisitsScheduled} scheduled',
          deltaColor: AppColors.textMuted,
          onTap: () => onTabSelected(2),
        ),
        DashboardMetricCard(
          label: 'Grain sales',
          value: '${data.grainSalesTotal}',
          icon: Icons.storefront_outlined,
          iconColor: const Color(0xFF6B4C9A),
          iconBgColor: const Color(0xFFF4F2F7),
          onTap: () => onTabSelected(3),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: AppTypography.titleSmall().copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildActionTile(
                title: 'Seed Requests',
                icon: Icons.shopping_cart_outlined,
                iconColor: const Color(0xFF0369A1),
                bgColor: const Color(0xFFECF5FD),
                onTap: () => onTabSelected(0),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildActionTile(
                title: 'Farm Visits',
                icon: Icons.location_on_outlined,
                iconColor: AppColors.amber,
                bgColor: const Color(0xFFFDF5EC),
                onTap: () => onTabSelected(2),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildActionTile(
                title: 'Grain Sales',
                icon: Icons.storefront_outlined,
                iconColor: const Color(0xFF6B4C9A),
                bgColor: const Color(0xFFF4F2F7),
                onTap: () => onTabSelected(3),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOperationalTools() {
    // Only operational tools allowed for Manager
    final tools = [
      ('Inventory', Icons.inventory_2_outlined, const Color(0xFF0369A1), const Color(0xFFECF5FD), NavDestination.seedsInventory.id),
      ('Warehouse', Icons.warehouse_outlined, const Color(0xFF6B4C9A), const Color(0xFFF4F2F7), NavDestination.warehouse.id),
      ('Billing', Icons.receipt_long_outlined, AppColors.canopy, const Color(0xFFF0F8EC), NavDestination.billing.id),
      ('Market Rates', Icons.trending_up_rounded, AppColors.amber, const Color(0xFFFDF5EC), NavDestination.marketRates.id),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'More Tools',
          style: AppTypography.titleSmall().copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: tools.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.85,
          ),
          itemBuilder: (context, index) {
            final tool = tools[index];
            return _buildActionTile(
              title: tool.$1,
              icon: tool.$2,
              iconColor: tool.$3,
              bgColor: tool.$4,
              onTap: () => onNavigate(tool.$5),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppColors.radiusMd),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppColors.radiusMd),
            border: Border.all(color: AppColors.line),
            boxShadow: AppColors.shadowSm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 17, color: iconColor),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: AppTypography.caption(color: AppColors.text).copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentNotifications(List<ManagerNotificationItem> notifications) {
    if (notifications.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Recent Notifications',
                style: AppTypography.titleSmall().copyWith(
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            InkWell(
              onTap: () => onNavigate(NavDestination.notifications.id),
              child: Row(
                children: [
                  Text(
                    'View all',
                    style: AppTypography.caption(color: AppColors.adminNavy).copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.chevron_right_rounded, size: 14, color: AppColors.adminNavy),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: notifications.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final notif = notifications[index];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppColors.radiusMd),
                border: Border.all(color: AppColors.line),
                boxShadow: AppColors.shadowSm,
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F8EC),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.notifications_active_outlined,
                      size: 18,
                      color: AppColors.canopy,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notif.title,
                          style: AppTypography.bodySmall().copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (notif.message.isNotEmpty)
                          Text(
                            notif.message,
                            style: AppTypography.caption(color: AppColors.textMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  if (notif.createdAt != null)
                    Text(
                      '${notif.createdAt!.hour.toString().padLeft(2, '0')}:${notif.createdAt!.minute.toString().padLeft(2, '0')}',
                      style: AppTypography.caption(color: AppColors.textMuted),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
