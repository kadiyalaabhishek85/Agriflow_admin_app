import '../../domain/entities/monthly_report.dart';

/// Remote source for admin monthly reports.
abstract class ReportRemoteDataSource {
  /// `GET /api/v1/admin/reports/monthly?month=YYYY-MM`
  Future<MonthlyReport> getMonthlyReport({
    required String accessToken,
    required String month,
  });
}
