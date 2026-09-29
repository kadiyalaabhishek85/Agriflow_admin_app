import '../../domain/entities/audit_log_item.dart';
import '../../domain/entities/audit_log_pagination.dart';
import '../../domain/repositories/event_log_repository.dart';
import '../datasources/event_log_remote_data_source.dart';

/// Thin pass-through implementation of [EventLogRepository].
class EventLogRepositoryImpl implements EventLogRepository {
  final EventLogRemoteDataSource remoteDataSource;

  EventLogRepositoryImpl({required this.remoteDataSource});

  @override
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
  }) {
    return remoteDataSource.getAuditLogs(
      accessToken: accessToken,
      page: page,
      pageSize: pageSize,
      search: search,
      sort: sort,
      order: order,
    );
  }
}
