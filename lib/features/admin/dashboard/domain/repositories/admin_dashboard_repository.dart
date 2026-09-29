import '../entities/admin_dashboard_data.dart';

abstract class AdminDashboardRepository {
  Future<AdminDashboardData> getAdminDashboard({required String accessToken});
}
