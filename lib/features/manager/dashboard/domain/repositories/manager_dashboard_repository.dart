import '../entities/manager_dashboard_data.dart';

abstract class ManagerDashboardRepository {
  Future<ManagerDashboardData> getManagerDashboard({required String accessToken});
}
