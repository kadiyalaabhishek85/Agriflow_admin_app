import 'package:agriflow_admin/features/dashboard/shared/presentation/widgets/dashboard_chart_card.dart';
import 'package:agriflow_admin/features/dashboard/shared/presentation/widgets/dashboard_mandi_strip.dart';

class AdminAuditItem {
  final String id;
  final String action;
  final String? entityType;
  final String? details;
  final DateTime? createdAt;
  final String? userName;

  const AdminAuditItem({
    required this.id,
    required this.action,
    this.entityType,
    this.details,
    this.createdAt,
    this.userName,
  });

  factory AdminAuditItem.fromJson(Map<String, dynamic> json) {
    DateTime? dt;
    if (json['created_at'] != null) {
      dt = DateTime.tryParse(json['created_at'].toString());
    }
    return AdminAuditItem(
      id: (json['id'] ?? '').toString(),
      action: (json['action'] ?? json['event'] ?? 'Activity').toString(),
      entityType: json['entity_type']?.toString(),
      details: json['details']?.toString(),
      createdAt: dt,
      userName: json['user_name'] ?? json['user']?['name'],
    );
  }
}

class AdminDashboardData {
  final int totalFarmers;
  final int activeFarmers;
  final int pendingFarmerApprovals;
  final int totalManagers;
  final int activeBookings;
  final int pendingGrainSales;
  final double totalSeedStockKg;
  final double warehouseInventoryKg;
  final double procurementMtdKg;
  final double revenueMtd;
  final double procurementCostMtd;
  final double profitMtd;
  final int pendingPayments;
  final int activeCrops;
  final int visitsToday;
  final int totalVisits;
  final int activeWarehouses;
  final List<MonthlyChartPoint> monthlyPoints;
  final List<MandiRateItem> mandiRates;
  final List<AdminAuditItem> recentAuditLogs;

  const AdminDashboardData({
    required this.totalFarmers,
    required this.activeFarmers,
    required this.pendingFarmerApprovals,
    required this.totalManagers,
    required this.activeBookings,
    required this.pendingGrainSales,
    required this.totalSeedStockKg,
    required this.warehouseInventoryKg,
    required this.procurementMtdKg,
    required this.revenueMtd,
    required this.procurementCostMtd,
    required this.profitMtd,
    required this.pendingPayments,
    required this.activeCrops,
    required this.visitsToday,
    this.totalVisits = 0,
    this.activeWarehouses = 0,
    this.monthlyPoints = const [],
    this.mandiRates = const [],
    this.recentAuditLogs = const [],
  });

  factory AdminDashboardData.fromJson({
    required Map<String, dynamic> summaryJson,
    List<MonthlyChartPoint> monthlyPoints = const [],
    List<MandiRateItem> mandiRates = const [],
    List<AdminAuditItem> recentAuditLogs = const [],
    int totalVisits = 0,
    int activeWarehouses = 0,
  }) {
    double parseD(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    int parseI(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    return AdminDashboardData(
      totalFarmers: parseI(summaryJson['total_farmers'] ?? summaryJson['totalFarmers']),
      activeFarmers: parseI(summaryJson['active_farmers'] ?? summaryJson['activeFarmers']),
      pendingFarmerApprovals: parseI(summaryJson['pending_farmer_approvals'] ?? summaryJson['pendingApprovals']),
      totalManagers: parseI(summaryJson['total_managers'] ?? summaryJson['totalManagers']),
      activeBookings: parseI(summaryJson['active_bookings'] ?? summaryJson['activeBookings']),
      pendingGrainSales: parseI(summaryJson['pending_grain_sales'] ?? summaryJson['pendingGrainSales']),
      totalSeedStockKg: parseD(summaryJson['total_seed_stock_kg'] ?? summaryJson['totalSeedStockKg']),
      warehouseInventoryKg: parseD(summaryJson['warehouse_inventory_kg'] ?? summaryJson['warehouseInv']),
      procurementMtdKg: parseD(summaryJson['procurement_mtd_kg'] ?? summaryJson['procurementMTD']),
      revenueMtd: parseD(summaryJson['revenue_mtd'] ?? summaryJson['revenueMTD']),
      procurementCostMtd: parseD(summaryJson['procurement_cost_mtd'] ?? summaryJson['procurementCost']),
      profitMtd: parseD(summaryJson['profit_mtd'] ?? summaryJson['profitMTD']),
      pendingPayments: parseI(summaryJson['pending_payments'] ?? summaryJson['pendingPayments']),
      activeCrops: parseI(summaryJson['active_crops'] ?? summaryJson['activeCrops']),
      visitsToday: parseI(summaryJson['visits_today'] ?? summaryJson['visitsToday'] ?? summaryJson['visitorToday']),
      totalVisits: totalVisits,
      activeWarehouses: activeWarehouses,
      monthlyPoints: monthlyPoints,
      mandiRates: mandiRates,
      recentAuditLogs: recentAuditLogs,
    );
  }
}
