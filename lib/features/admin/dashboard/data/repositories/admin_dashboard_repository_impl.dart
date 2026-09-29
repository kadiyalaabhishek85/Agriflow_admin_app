import '../../domain/entities/admin_dashboard_data.dart';
import '../../domain/repositories/admin_dashboard_repository.dart';
import '../datasources/admin_dashboard_remote_data_source.dart';

class AdminDashboardRepositoryImpl implements AdminDashboardRepository {
  final AdminDashboardRemoteDataSource remoteDataSource;

  AdminDashboardRepositoryImpl({required this.remoteDataSource});

  @override
  Future<AdminDashboardData> getAdminDashboard({required String accessToken}) async {
    return await remoteDataSource.fetchDashboardData(accessToken: accessToken);
  }
}
