import '../../domain/entities/manager_item.dart';
import '../../domain/entities/manager_pagination.dart';

/// Abstract remote data source contract for Managers.
///
/// Mirrors the verified FastAPI routes (live OpenAPI, 2026-09-28).
abstract class ManagerRemoteDataSource {
  Future<({List<ManagerItem> items, ManagerPagination pagination})>
      getManagers({
    required String accessToken,
    int page = 1,
    int pageSize = 20,
    String? search,
    String? status,
    String? sort,
    String? order,
  });

  Future<ManagerItem> createManager({
    required String accessToken,
    required String name,
    required String phone,
    required String password,
    String? email,
    String? assignedRegion,
    String? department,
  });

  Future<ManagerItem> updateManagerStatus({
    required String accessToken,
    required String managerId,
    required String status,
  });

  Future<String> resetManagerPassword({
    required String accessToken,
    required String managerId,
    required String newPassword,
  });
}
