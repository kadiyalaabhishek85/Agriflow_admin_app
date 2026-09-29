import 'package:agriflow_admin/features/dashboard/shared/presentation/widgets/dashboard_mandi_strip.dart';

class ManagerNotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime? createdAt;
  final bool isRead;

  const ManagerNotificationItem({
    required this.id,
    required this.title,
    required this.message,
    this.createdAt,
    this.isRead = false,
  });

  factory ManagerNotificationItem.fromJson(Map<String, dynamic> json) {
    DateTime? dt;
    if (json['created_at'] != null) {
      dt = DateTime.tryParse(json['created_at'].toString());
    }
    return ManagerNotificationItem(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? 'Notification').toString(),
      message: (json['message'] ?? json['body'] ?? '').toString(),
      createdAt: dt,
      isRead: json['is_read'] == true,
    );
  }

  String get timeAgo {
    if (createdAt == null) return '';
    final diff = DateTime.now().difference(createdAt!);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}

class ManagerDashboardData {
  final int pendingSeedOrders;
  final int todaySeedOrders;
  final int bookingsTotal;
  final int farmVisitsCount;
  final int farmVisitsScheduled;
  final int grainSalesTotal;
  final double revenueMtd;
  final List<MandiRateItem> mandiRates;
  final List<ManagerNotificationItem> recentNotifications;

  const ManagerDashboardData({
    required this.pendingSeedOrders,
    required this.todaySeedOrders,
    required this.bookingsTotal,
    required this.farmVisitsCount,
    required this.farmVisitsScheduled,
    required this.grainSalesTotal,
    required this.revenueMtd,
    this.mandiRates = const [],
    this.recentNotifications = const [],
  });

  factory ManagerDashboardData.empty() => const ManagerDashboardData(
        pendingSeedOrders: 0,
        todaySeedOrders: 0,
        bookingsTotal: 0,
        farmVisitsCount: 0,
        farmVisitsScheduled: 0,
        grainSalesTotal: 0,
        revenueMtd: 0.0,
      );
}
