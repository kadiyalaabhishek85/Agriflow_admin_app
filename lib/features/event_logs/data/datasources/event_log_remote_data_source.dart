import '../../domain/entities/audit_log_item.dart';
import '../../domain/entities/audit_log_pagination.dart';

/// Remote source for admin audit logs.
abstract class EventLogRemoteDataSource {
  /// `GET /api/v1/admin/audit-logs`
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
