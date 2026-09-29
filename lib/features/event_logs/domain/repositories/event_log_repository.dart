import '../entities/audit_log_item.dart';
import '../entities/audit_log_pagination.dart';

/// Contract for reading the admin audit log.
///
/// Backend API (verified against live OpenAPI):
/// - `GET /api/v1/admin/audit-logs` → PaginatedResponse[AuditLogPublic]
abstract class EventLogRepository {
  Future<({
    List<AuditLogItem> items,
    AuditLogPagination pagination,
  })> getAuditLogs({
    required String accessToken,
    int page = 1,
    int pageSize = 20,
    String? search,
    String? sort,
    String? order,
  });
}
