import '../entities/manager_item.dart';
import '../entities/manager_pagination.dart';

/// Abstract repository contract for Managers data access.
///
/// Verified FastAPI contract only (live OpenAPI, 2026-09-28):
/// - `GET    /api/v1/managers`                          (page, page_size, search, status, sort, order)
/// - `POST   /api/v1/managers`                          (ManagerCreate → 201)
/// - `PATCH  /api/v1/managers/{manager_id}/status`      (ManagerStatusUpdate)
/// - `POST   /api/v1/managers/{manager_id}/reset-password` (ResetPasswordRequest)
///
/// `PATCH /managers/{manager_id}` (ManagerUpdate) exists in the contract but
/// is intentionally not wrapped yet — M7 scope is list/create/status/reset.
abstract class ManagerRepository {
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
