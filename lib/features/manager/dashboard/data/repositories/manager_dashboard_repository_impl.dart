import '../../domain/entities/manager_dashboard_data.dart';
import '../../domain/repositories/manager_dashboard_repository.dart';
import '../datasources/manager_dashboard_remote_data_source.dart';

class ManagerDashboardRepositoryImpl implements ManagerDashboardRepository {
  final ManagerDashboardRemoteDataSource remoteDataSource;

  ManagerDashboardRepositoryImpl({required this.remoteDataSource});

  @override
  Future<ManagerDashboardData> getManagerDashboard({required String accessToken}) async {
    return await remoteDataSource.fetchDashboardData(accessToken: accessToken);
  }
}
