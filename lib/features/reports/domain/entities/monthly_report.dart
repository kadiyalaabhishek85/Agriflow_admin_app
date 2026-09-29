import 'package:flutter/foundation.dart';

/// Monthly report entity (`MonthlyReportResponse` from
/// `GET /api/v1/admin/reports/monthly?month=YYYY-MM`).
///
/// Amount fields are strings in the contract; parsed for display only.
@immutable
class MonthlyReport {
  final String month;
  final String totalSeedPurchasesAmount;
  final String totalGrainSalesAmount;
  final int totalBookings;
  final int newFarmers;

  const MonthlyReport({
    required this.month,
    required this.totalSeedPurchasesAmount,
    required this.totalGrainSalesAmount,
    required this.totalBookings,
    required this.newFarmers,
  });

  factory MonthlyReport.fromJson(Map<String, dynamic> json) {
    return MonthlyReport(
      month: (json['month'] as String?) ?? '',
      totalSeedPurchasesAmount:
          (json['total_seed_purchases_amount'] as String?) ?? '0',
      totalGrainSalesAmount:
          (json['total_grain_sales_amount'] as String?) ?? '0',
      totalBookings: (json['total_bookings'] as num?)?.toInt() ?? 0,
      newFarmers: (json['new_farmers'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'month': month,
        'total_seed_purchases_amount': totalSeedPurchasesAmount,
        'total_grain_sales_amount': totalGrainSalesAmount,
        'total_bookings': totalBookings,
        'new_farmers': newFarmers,
      };

  double get seedPurchasesValue =>
      double.tryParse(totalSeedPurchasesAmount) ?? 0;
  double get grainSalesValue =>
      double.tryParse(totalGrainSalesAmount) ?? 0;

  /// Formats a numeric amount for display: `125000` → `₹1,25,000`
  /// (Indian grouping) or the raw string when unparseable.
  static String formatAmount(String raw) {
    final value = double.tryParse(raw);
    if (value == null) return raw;

    final negative = value < 0;
    final abs = value.abs();
    final intPart = abs.truncate();
    final isWhole = abs == intPart;

    var digits = intPart.toString();
    String grouped;
    if (digits.length > 3) {
      final chunks = <String>[digits.substring(digits.length - 3)];
      var rest = digits.substring(0, digits.length - 3);
      while (rest.length > 2) {
        chunks.insert(0, rest.substring(rest.length - 2));
        rest = rest.substring(0, rest.length - 2);
      }
      chunks.insert(0, rest);
      grouped = chunks.join(',');
    } else {
      grouped = digits;
    }

    final sign = negative ? '-' : '';
    final suffix = isWhole ? '' : '.${abs.toStringAsFixed(2).split('.').last}';
    return '₹$sign$grouped$suffix';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MonthlyReport &&
          other.month == month &&
          other.totalSeedPurchasesAmount == totalSeedPurchasesAmount &&
          other.totalGrainSalesAmount == totalGrainSalesAmount &&
          other.totalBookings == totalBookings &&
          other.newFarmers == newFarmers);

  @override
  int get hashCode => Object.hash(
        month,
        totalSeedPurchasesAmount,
        totalGrainSalesAmount,
        totalBookings,
        newFarmers,
      );
}
