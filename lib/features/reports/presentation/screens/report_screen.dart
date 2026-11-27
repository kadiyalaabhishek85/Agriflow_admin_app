import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/sheet_drag_handle.dart';
import '../../../../core/widgets/squircle_icon_button.dart';
import '../../data/services/platform_report_exporter.dart';
import '../../domain/entities/monthly_report.dart';
import '../../domain/services/report_exporter.dart';
import '../controllers/report_controller.dart';

/// Monthly Reports screen (M7-2): live monthly metrics, month navigator,
/// real-time refresh, and working PDF/CSV export on Android & Web.
class ReportScreen extends StatefulWidget {
  final ReportController controller;
  final VoidCallback onBack;
  final ReportExporter? exporter;

  const ReportScreen({
    super.key,
    required this.controller,
    required this.onBack,
    this.exporter,
  });

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  bool _isExporting = false;
  String? _exportStatusMessage;
  String? _exportLocation;
  bool _exportIsError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!widget.controller.isLoading) {
        widget.controller.loadReport();
      }
    });
  }

  Future<void> _exportReport(
    ReportController ctrl,
    MonthlyReport report,
    ReportExportFormat format,
  ) async {
    if (_isExporting) return;
    setState(() {
      _isExporting = true;
      _exportStatusMessage = null;
      _exportLocation = null;
    });

    final exporter = widget.exporter ?? PlatformReportExporter();
    ReportExportResult result;
    try {
      result = await exporter.export(
        report: report,
        monthLabel: ctrl.monthLabel,
        format: format,
      );
    } catch (_) {
      result = const ReportExportResult(
        success: false,
        message: ReportMessages.saveFailure,
      );
    }

    if (!mounted) return;
    setState(() {
      _isExporting = false;
      _exportIsError = !result.success;
      _exportStatusMessage = result.message;
      _exportLocation = result.success ? result.location : null;
    });
  }

  void _showExportSheet(ReportController ctrl, MonthlyReport report) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SheetDragHandle(),
              const SizedBox(height: 14),
              Text(
                'Export ${ctrl.monthLabel} Report',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Choose a file format to download this month\'s live report.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                key: const Key('report_sheet_pdf_btn'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: AppColors.line),
                ),
                leading: const CircleAvatar(
                  backgroundColor: AppColors.surfaceAlt,
                  child: Icon(Icons.picture_as_pdf_rounded, color: AppColors.canopyDeep),
                ),
                title: const Text(
                  'Download PDF Report',
                  style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.text),
                ),
                subtitle: Text('AgriFlow_Report_${report.month}.pdf'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _exportReport(ctrl, report, ReportExportFormat.pdf);
                },
              ),
              const SizedBox(height: 10),
              ListTile(
                key: const Key('report_sheet_csv_btn'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: AppColors.line),
                ),
                leading: const CircleAvatar(
                  backgroundColor: AppColors.infoBg,
                  child: Icon(Icons.table_chart_outlined, color: AppColors.adminNavy),
                ),
                title: const Text(
                  'Download CSV Spreadsheet',
                  style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.text),
                ),
                subtitle: Text('AgriFlow_Report_${report.month}.csv'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _exportReport(ctrl, report, ReportExportFormat.csv);
                },
              ),
            ],
          ),
        ),
      ),
    );
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
                _buildHeader(ctrl, report),

                // Month navigator
                _buildMonthNavigator(ctrl),

                if (ctrl.isLoading && report != null)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: LinearProgressIndicator(
                      minHeight: 2.5,
                      color: AppColors.canopy,
                      backgroundColor: AppColors.surfaceAlt,
                    ),
                  ),

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

  Widget _buildHeader(ReportController ctrl, MonthlyReport? report) {
    final canExport = report != null && !_isExporting;
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
          SquircleIconButton(
            key: const Key('report_refresh_btn'),
            tooltip: 'Refresh live data',
            onTap: ctrl.isLoading
                ? null
                : () {
                    setState(() {
                      _exportStatusMessage = null;
                      _exportLocation = null;
                    });
                    ctrl.loadReport();
                  },
            icon: Icon(
              Icons.refresh_rounded,
              size: 18,
              color: ctrl.isLoading ? AppColors.textFaint : AppColors.forest,
            ),
            size: 38,
          ),
          const SizedBox(width: 8),
          SquircleIconButton(
            key: const Key('report_export_btn'),
            tooltip: 'Download report (PDF / CSV)',
            onTap: canExport ? () => _showExportSheet(ctrl, report) : null,
            backgroundColor: canExport ? AppColors.surfaceAlt : null,
            borderColor: canExport ? AppColors.canopy.withAlpha(90) : null,
            icon: _isExporting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.canopy,
                    ),
                  )
                : Icon(
                    Icons.file_download_outlined,
                    size: 18,
                    color: canExport ? AppColors.canopyDeep : AppColors.textFaint,
                  ),
            size: 38,
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
              onTap: ctrl.isLoading
                  ? null
                  : () {
                      setState(() {
                        _exportStatusMessage = null;
                        _exportLocation = null;
                      });
                      ctrl.goToPreviousMonth();
                    },
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
              onTap: ctrl.isLoading
                  ? null
                  : () {
                      setState(() {
                        _exportStatusMessage = null;
                        _exportLocation = null;
                      });
                      ctrl.goToNextMonth();
                    },
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
          if (_exportStatusMessage != null) ...[
            Container(
              key: const Key('report_export_status'),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: _exportIsError ? AppColors.badBg : AppColors.goodBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (_exportIsError ? AppColors.bad : AppColors.good)
                      .withAlpha(65),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _exportIsError
                        ? Icons.error_outline_rounded
                        : Icons.check_circle_outline_rounded,
                    size: 18,
                    color: _exportIsError ? AppColors.bad : AppColors.good,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _exportLocation != null
                          ? '$_exportStatusMessage ($_exportLocation)'
                          : _exportStatusMessage!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _exportIsError ? AppColors.bad : AppColors.good,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Download Monthly Report',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Export ${ctrl.monthLabel} summary metrics as PDF or CSV.',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const Key('report_export_csv_btn'),
                        onPressed: _isExporting
                            ? null
                            : () => _exportReport(
                                  ctrl,
                                  report,
                                  ReportExportFormat.csv,
                                ),
                        icon: const Icon(Icons.table_chart_outlined, size: 17),
                        label: const Text('Export CSV'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.forest,
                          side: const BorderSide(color: AppColors.line, width: 1.4),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        key: const Key('report_export_pdf_btn'),
                        onPressed: _isExporting
                            ? null
                            : () => _exportReport(
                                  ctrl,
                                  report,
                                  ReportExportFormat.pdf,
                                ),
                        icon: const Icon(Icons.picture_as_pdf_rounded, size: 17),
                        label: const Text('Export PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.canopy,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
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
