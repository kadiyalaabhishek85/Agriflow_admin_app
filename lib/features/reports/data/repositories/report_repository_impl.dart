import '../../domain/entities/monthly_report.dart';
import '../../domain/repositories/report_repository.dart';
import '../datasources/report_remote_data_source.dart';

/// Thin pass-through implementation of [ReportRepository].
class ReportRepositoryImpl implements ReportRepository {
  final ReportRemoteDataSource remoteDataSource;

  ReportRepositoryImpl({required this.remoteDataSource});

  @override
  Future<MonthlyReport> getMonthlyReport({
    required String accessToken,
    required String month,
  }) {
    return remoteDataSource.getMonthlyReport(
      accessToken: accessToken,
      month: month,
    );
  }
}
