import 'package:flutter/foundation.dart';
import 'package:agriflow_admin/features/auth/domain/entities/auth_exception.dart';
import 'package:agriflow_admin/features/dashboard/shared/presentation/dashboard_state.dart';
import 'package:agriflow_admin/features/admin/dashboard/domain/entities/admin_dashboard_data.dart';
import 'package:agriflow_admin/features/admin/dashboard/domain/repositories/admin_dashboard_repository.dart';
import 'package:agriflow_admin/core/network/error_sanitizer.dart';

class AdminDashboardController extends ChangeNotifier {
  final AdminDashboardRepository repository;
  final String accessToken;

  DashboardState<AdminDashboardData> _state = DashboardState.initial();
  DashboardState<AdminDashboardData> get state => _state;

  AdminDashboardController({
    required this.repository,
    required this.accessToken,
  });

  Future<void> loadDashboard() async {
    _state = DashboardState.loading();
    notifyListeners();

    try {
      final data = await repository.getAdminDashboard(accessToken: accessToken);
      _state = DashboardState.success(data);
    } on AuthException catch (e) {
      _state = DashboardState.error(
        e.message,
        isNetworkError: e.isNetworkError,
      );
    } catch (e) {
      _state = DashboardState.error(
        ErrorSanitizer.sanitize(e, defaultAction: 'Loading dashboard'),
      );
    }

    notifyListeners();
  }

  Future<void> refreshDashboard() async {
    if (_state.data != null) {
      _state = DashboardState.refreshing(_state.data!);
      notifyListeners();
    } else {
      _state = DashboardState.loading();
      notifyListeners();
    }

    try {
      final data = await repository.getAdminDashboard(accessToken: accessToken);
      _state = DashboardState.success(data);
    } on AuthException catch (e) {
      // Preserve current data on refresh error if available
      _state = DashboardState.error(
        e.message,
        isNetworkError: e.isNetworkError,
        previousData: _state.data,
      );
    } catch (e) {
      _state = DashboardState.error(
        ErrorSanitizer.sanitize(e, defaultAction: 'Refreshing dashboard'),
        previousData: _state.data,
      );
    }

    notifyListeners();
  }

  Future<void> retry() => loadDashboard();
}
