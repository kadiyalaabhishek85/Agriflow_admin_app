import '../entities/monthly_report.dart';

/// Contract for reading admin monthly reports.
///
/// Backend API (verified against live OpenAPI):
/// - `GET /api/v1/admin/reports/monthly?month=YYYY-MM` → MonthlyReportResponse
abstract class ReportRepository {
  /// Loads one month of report totals. [month] must match `YYYY-MM`
  /// (OpenAPI pattern `^\d{4}-\d{2}$`).
  Future<MonthlyReport> getMonthlyReport({
    required String accessToken,
    required String month,
  });
}
