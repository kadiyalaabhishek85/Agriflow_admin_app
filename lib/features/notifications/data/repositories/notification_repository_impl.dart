import '../../domain/entities/notification_item.dart';
import '../datasources/notification_remote_data_source.dart';

/// Repository for notification operations.
/// Thin wrapper around the data source for testability.
class NotificationRepository {
  final NotificationRemoteDataSource remoteDataSource;

  NotificationRepository({required this.remoteDataSource});

  Future<List<NotificationItem>> fetchNotifications({
    required String accessToken,
    int page = 1,
    int pageSize = 50,
  }) {
    return remoteDataSource.fetchNotifications(
      accessToken: accessToken,
      page: page,
      pageSize: pageSize,
    );
  }

  Future<void> markRead({
    required String accessToken,
    required String notificationId,
  }) {
    return remoteDataSource.markRead(
      accessToken: accessToken,
      notificationId: notificationId,
    );
  }

  Future<void> markAllRead({required String accessToken}) {
    return remoteDataSource.markAllRead(accessToken: accessToken);
  }

  Future<String> getStreamTicket({required String accessToken}) {
    return remoteDataSource.getStreamTicket(accessToken: accessToken);
  }
}
