import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/squircle_icon_button.dart';
import '../../domain/entities/monthly_report.dart';
import '../controllers/report_controller.dart';

/// Monthly Reports screen (M7-2): month navigator, four report stat cards,
/// and a disabled Export control (PDF/CSV export is backend-pending).
class ReportScreen extends StatefulWidget {
  final ReportController controller;
  final VoidCallback onBack;

  const ReportScreen({
    super.key,
    required this.controller,
    required this.onBack,
  });

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.controller.report == null &&
          widget.controller.errorMessage == null) {
        widget.controller.loadReport();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final ctrl = widget.controller;
        final report = ctrl.report;

        return Scaffold(
          key: const Key('report_screen'),
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),

                // Month navigator
                _buildMonthNavigator(ctrl),

                if (ctrl.errorMessage != null && report != null)
                  _buildErrorBanner(ctrl.errorMessage!),

                Expanded(
                  child: _buildBody(ctrl, report),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          SquircleIconButton.back(
            key: const Key('report_back_btn'),
            onTap: widget.onBack,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'MONTHLY REPORTS',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: AppColors.textFaint,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Reports',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
          ),

          // Export is backend-pending (PDF/CSV export API not available yet)
          const Tooltip(
            message:
                'PDF/CSV export: Backend API required — to be supplied by Syed.',
            child: SquircleIconButton(
              key: Key('report_export_btn'),
              icon: Icon(
                Icons.file_download_outlined,
                size: 18,
                color: AppColors.textFaint,
              ),
              size: 38,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthNavigator(ReportController ctrl) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            SquircleIconButton(
              key: const Key('report_prev_month_btn'),
              icon: const Icon(Icons.chevron_left_rounded,
                  size: 18, color: AppColors.textMuted),
              size: 32,
              onTap:
                  ctrl.isLoading ? null : () => ctrl.goToPreviousMonth(),
            ),
            Expanded(
              child: Text(
                ctrl.monthLabel,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
            ),
            SquircleIconButton(
              key: const Key('report_next_month_btn'),
              icon: const Icon(Icons.chevron_right_rounded,
                  size: 18, color: AppColors.textMuted),
              size: 32,
              onTap: ctrl.isLoading ? null : () => ctrl.goToNextMonth(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.badBg.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.badBg),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 16, color: AppColors.bad),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.bad,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ReportController ctrl, MonthlyReport? report) {
    if (ctrl.isLoading && report == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.canopy),
      );
    }

    if (ctrl.errorMessage != null && report == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded,
                  size: 48, color: AppColors.bad),
              const SizedBox(height: 12),
              Text(
                ctrl.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                key: const Key('report_retry_btn'),
                onPressed: () => ctrl.loadReport(refresh: true),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.canopy,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (report == null) {
      return const SizedBox.shrink();
    }

    return RefreshIndicator(
      onRefresh: () => ctrl.loadReport(refresh: true),
      color: AppColors.canopy,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
        children: [
          _buildStatCard(
            keyName: 'report_seed_purchases',
            label: 'SEED PURCHASES',
            value: MonthlyReport.formatAmount(report.totalSeedPurchasesAmount),
            color: AppColors.adminNavy,
            bgColor: const Color(0xFFEAF1FB),
            icon: Icons.agriculture_outlined,
          ),
          const SizedBox(height: 12),
          _buildStatCard(
            keyName: 'report_grain_sales',
            label: 'GRAIN SALES',
            value: MonthlyReport.formatAmount(report.totalGrainSalesAmount),
            color: AppColors.good,
            bgColor: const Color(0xFFE5F6EA),
            icon: Icons.stacked_bar_chart_rounded,
          ),
          const SizedBox(height: 12),
          _buildStatCard(
            keyName: 'report_bookings',
            label: 'BOOKINGS',
            value: '${report.totalBookings}',
            color: AppColors.warn,
            bgColor: AppColors.warnBg.withValues(alpha: 0.5),
            icon: Icons.calendar_month_outlined,
          ),
          const SizedBox(height: 12),
          _buildStatCard(
            keyName: 'report_new_farmers',
            label: 'NEW FARMERS',
            value: '${report.newFarmers}',
            color: AppColors.forest,
            bgColor: const Color(0xFFE5F6EA),
            icon: Icons.person_add_alt_1_outlined,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.line),
            ),
            child: const Text(
              'PDF/CSV report export: Backend API required — to be supplied by Syed.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String keyName,
    required String label,
    required String value,
    required Color color,
    required Color bgColor,
    required IconData icon,
  }) {
    return Container(
      key: Key(keyName),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
