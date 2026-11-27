import 'package:flutter/material.dart';
import 'package:agriflow_admin/core/constants/app_colors.dart';
import 'package:agriflow_admin/core/constants/app_typography.dart';
import 'package:agriflow_admin/core/navigation/nav_destination.dart';
import 'package:agriflow_admin/core/widgets/status_pill.dart';
import 'package:agriflow_admin/features/auth/domain/entities/auth_session.dart';
import 'package:agriflow_admin/features/dashboard/shared/presentation/widgets/dashboard_chart_card.dart';
import 'package:agriflow_admin/features/dashboard/shared/presentation/widgets/dashboard_mandi_strip.dart';
import 'package:agriflow_admin/features/dashboard/shared/presentation/widgets/dashboard_metric_card.dart';
import 'package:agriflow_admin/features/dashboard/shared/presentation/widgets/dashboard_state_views.dart';
import 'package:agriflow_admin/features/dashboard/shared/presentation/widgets/dashboard_summary_strip.dart';
import 'package:agriflow_admin/features/admin/dashboard/domain/entities/admin_dashboard_data.dart';
import 'package:agriflow_admin/features/admin/dashboard/presentation/controllers/admin_dashboard_controller.dart';

class AdminDashboardView extends StatelessWidget {
  final AuthSession session;
  final AdminDashboardController controller;
  final void Function(int tabIndex) onTabSelected;
  final void Function(String routeId) onNavigate;

  const AdminDashboardView({
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

        final data = state.data ??
            const AdminDashboardData(
              totalFarmers: 0,
              activeFarmers: 0,
              pendingFarmerApprovals: 0,
              totalManagers: 0,
              activeBookings: 0,
              pendingGrainSales: 0,
              totalSeedStockKg: 0,
              warehouseInventoryKg: 0,
              procurementMtdKg: 0,
              revenueMtd: 0,
              procurementCostMtd: 0,
              profitMtd: 0,
              pendingPayments: 0,
              activeCrops: 0,
              visitsToday: 0,
            );

        return RefreshIndicator(
          onRefresh: controller.refreshDashboard,
          color: AppColors.adminNavy,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Greeting Header matching HTML
                _buildHeader(),
                const SizedBox(height: 18),

                if (data.sectionWarnings.isNotEmpty) ...[
                  _buildPartialWarningBanner(data.sectionWarnings),
                  const SizedBox(height: 14),
                ],

                // Summary Strip matching HTML
                DashboardSummaryStrip(
                  primaryAmount: '₹${data.revenueMtd.toStringAsFixed(0)}',
                  primaryLabel: "MTD Seed Revenue",
                  secondarySubtitle:
                      '${data.procurementMtdKg.toStringAsFixed(0)} kg procured · ${data.activeBookings} active bookings · ${data.pendingGrainSales} pending sales',
                  onTap: () => onTabSelected(1),
                ),
                const SizedBox(height: 20),

                // Primary Operational KPI Cards (2x2 Grid)
                _buildOperationalGrid(data),
                const SizedBox(height: 24),

                // System Overview (Super Admin Oversight)
                _buildSystemOverview(data),
                const SizedBox(height: 24),

                // Monthly Financial Trend Chart
                DashboardChartCard(
                  title: 'Monthly Revenue Trend',
                  subtitle: '6-Month Trend',
                  points: data.monthlyPoints,
                ),
                const SizedBox(height: 24),

                // Quick Actions
                _buildQuickActions(),
                const SizedBox(height: 24),

                // More Tools (Operational & Admin Portal)
                _buildMoreTools(),
                const SizedBox(height: 24),

                // Today's Mandi Prices
                DashboardMandiStrip(
                  rates: data.mandiRates,
                  updatedAt: 'Live',
                  onViewAll: () => onNavigate(NavDestination.marketRates.id),
                ),
                const SizedBox(height: 24),

                // Recent Audit Activity
                _buildRecentActivity(data.recentAuditLogs),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    final name = session.user.name.isNotEmpty ? session.user.name : 'Super Admin';
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                'Sri Siva Sai Seeds · Administration',
                style: AppTypography.eyebrow(color: AppColors.textMuted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.adminNavy.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'SUPER ADMIN',
                style: AppTypography.caption(color: AppColors.adminNavy).copyWith(
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
          '$greeting, $name 👋',
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

  Widget _buildOperationalGrid(AdminDashboardData data) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 0.96,
      children: [
        DashboardMetricCard(
          label: 'Total Seed Stock',
          value: '${(data.totalSeedStockKg / 100).toStringAsFixed(1)} Qtl',
          icon: Icons.shopping_cart_outlined,
          iconColor: const Color(0xFF0369A1),
          iconBgColor: const Color(0xFFECF5FD),
          deltaText: '▲ ${(data.totalSeedStockKg / 1000).toStringAsFixed(1)} T total',
          deltaColor: AppColors.canopyDeep,
          onTap: () => onTabSelected(0),
        ),
        DashboardMetricCard(
          label: 'Active Bookings',
          value: '${data.activeBookings}',
          icon: Icons.calendar_today_outlined,
          iconColor: AppColors.canopy,
          iconBgColor: const Color(0xFFF0F8EC),
          deltaText: 'Inv: ${(data.warehouseInventoryKg / 100).toStringAsFixed(0)} Qtl',
          deltaColor: AppColors.textMuted,
          onTap: () => onTabSelected(1),
        ),
        DashboardMetricCard(
          label: 'Warehouse Stock',
          value: '${(data.warehouseInventoryKg / 100).toStringAsFixed(0)} Qtl',
          icon: Icons.warehouse_outlined,
          iconColor: const Color(0xFF6B4C9A),
          iconBgColor: const Color(0xFFF4F2F7),
          deltaText: data.warehousesFetchFailed
              ? 'Hub count unavailable'
              : '${data.activeWarehouses} warehouses',
          deltaColor: data.warehousesFetchFailed ? AppColors.bad : AppColors.textMuted,
          onTap: () => onNavigate(NavDestination.warehouse.id),
        ),
        DashboardMetricCard(
          label: 'Pending Sales',
          value: '${data.pendingGrainSales}',
          icon: Icons.storefront_outlined,
          iconColor: const Color(0xFF6B4C9A),
          iconBgColor: const Color(0xFFF4F2F7),
          deltaText: 'Procured: ${(data.procurementMtdKg / 100).toStringAsFixed(0)} Qtl',
          deltaColor: AppColors.canopyDeep,
          onTap: () => onTabSelected(3),
        ),
      ],
    );
  }

  Widget _buildSystemOverview(AdminDashboardData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            Text(
              'System Overview',
              style: AppTypography.titleSmall().copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const StatusPill(
              label: '● All Systems Operational',
              type: PillType.good,
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.02,
          children: [
            DashboardMetricCard(
              label: 'Total Farmers',
              value: '${data.totalFarmers}',
              icon: Icons.people_outline_rounded,
              iconColor: const Color(0xFF0369A1),
              iconBgColor: const Color(0xFFECF5FD),
              onTap: () => onNavigate(NavDestination.allFarmers.id),
            ),
            DashboardMetricCard(
              label: 'Pending Payments',
              value: '${data.pendingPayments}',
              icon: Icons.payment_outlined,
              iconColor: AppColors.bad,
              iconBgColor: const Color(0xFFFDF2F2),
              onTap: () => onNavigate(NavDestination.billing.id),
            ),
            DashboardMetricCard(
              label: 'System Managers',
              value: '${data.totalManagers}',
              icon: Icons.shield_outlined,
              iconColor: AppColors.amber,
              iconBgColor: const Color(0xFFFDF3E5),
              onTap: () => onNavigate(NavDestination.managers.id),
            ),
            DashboardMetricCard(
              label: 'Farm Visits Recorded',
              value: data.visitsFetchFailed ? '—' : '${data.totalVisits}',
              icon: Icons.pin_drop_outlined,
              iconColor: AppColors.canopy,
              iconBgColor: const Color(0xFFF0F8EC),
              onTap: () => onTabSelected(2),
            ),
          ],
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
                title: 'Seed Purchase',
                icon: Icons.shopping_cart_outlined,
                iconColor: const Color(0xFF0369A1),
                bgColor: const Color(0xFFECF5FD),
                onTap: () => onTabSelected(0),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildActionTile(
                title: 'Booking Slot',
                icon: Icons.calendar_today_outlined,
                iconColor: AppColors.canopy,
                bgColor: const Color(0xFFF0F8EC),
                onTap: () => onTabSelected(1),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildActionTile(
                title: 'Farm Visit',
                icon: Icons.location_on_outlined,
                iconColor: AppColors.amber,
                bgColor: const Color(0xFFFDF5EC),
                onTap: () => onTabSelected(2),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildActionTile(
                title: 'Grain Sale',
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

  Widget _buildActionTile({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppColors.shadowSm,
            ),
            child: Icon(icon, size: 22, color: iconColor),
          ),
          const SizedBox(height: 7),
          Text(
            title,
            style: AppTypography.caption(color: AppColors.textMuted).copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 10,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMoreTools() {
    final tools = [
      ('Inventory', Icons.inventory_2_outlined, const Color(0xFF0369A1), const Color(0xFFECF5FD), NavDestination.seedsInventory.id),
      ('Warehouse', Icons.warehouse_outlined, const Color(0xFF6B4C9A), const Color(0xFFF4F2F7), NavDestination.warehouse.id),
      ('Billing', Icons.receipt_long_outlined, AppColors.canopyDeep, const Color(0xFFF0F8EC), NavDestination.billing.id),
      ('Market Rates', Icons.trending_up_rounded, AppColors.amber, const Color(0xFFFDF5EC), NavDestination.marketRates.id),
      ('Reports', Icons.bar_chart_rounded, const Color(0xFF0369A1), const Color(0xFFECF5FD), NavDestination.reports.id),
      ('Event Logs', Icons.fact_check_outlined, const Color(0xFF6B4C9A), const Color(0xFFF4F2F7), NavDestination.eventLogs.id),
      ('Managers', Icons.badge_outlined, AppColors.amber, const Color(0xFFFDF3E5), NavDestination.managers.id),
      ('All Farmers', Icons.people_outline_rounded, AppColors.canopyDeep, const Color(0xFFF0F8EC), NavDestination.allFarmers.id),
      ('Credits', Icons.credit_card_outlined, const Color(0xFF0369A1), const Color(0xFFECF5FD), NavDestination.credits.id),
      ('Cache', Icons.storage_rounded, const Color(0xFF6B4C9A), const Color(0xFFF4F2F7), NavDestination.cacheManagement.id),
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
            mainAxisSpacing: 14,
            childAspectRatio: 0.72,
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

  Widget _buildRecentActivity(List<AdminAuditItem> auditLogs) {
    if (auditLogs.isEmpty) {
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
                'Recent Activity',
                style: AppTypography.titleSmall().copyWith(
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            InkWell(
              onTap: () => onNavigate(NavDestination.eventLogs.id),
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
          itemCount: auditLogs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final log = auditLogs[index];
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
                      color: const Color(0xFFF4F2F7),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.history_rounded,
                      size: 16,
                      color: Color(0xFF6B4C9A),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          log.action,
                          style: AppTypography.bodySmall().copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (log.details != null && log.details!.isNotEmpty)
                          Text(
                            log.details!,
                            style: AppTypography.caption(color: AppColors.textMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  if (log.createdAt != null)
                    Text(
                      '${log.createdAt!.hour.toString().padLeft(2, '0')}:${log.createdAt!.minute.toString().padLeft(2, '0')}',
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

  Widget _buildPartialWarningBanner(List<String> warnings) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8EC),
        borderRadius: BorderRadius.circular(AppColors.radiusMd),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.amber),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Some dashboard sections failed to load: ${warnings.join(' · ')}',
              style: AppTypography.caption(color: AppColors.text),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: controller.retry,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Retry',
              style: AppTypography.caption(color: AppColors.adminNavy).copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
