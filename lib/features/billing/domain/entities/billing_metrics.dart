import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'billing_transaction_item.dart';

/// Aggregated metrics for Billing & Invoices dashboard summary cards.
@immutable
class BillingMetrics {
  final int totalInvoices;
  final double totalCollected; // Total credits received
  final double totalPayouts; // Total debits disbursed
  final double pendingAmount;
  final int pendingCount;

  const BillingMetrics({
    this.totalInvoices = 0,
    this.totalCollected = 0.0,
    this.totalPayouts = 0.0,
    this.pendingAmount = 0.0,
    this.pendingCount = 0,
  });

  /// Computes metrics safely from a list of transactions.
  factory BillingMetrics.fromTransactions(List<BillingTransactionItem> items, {int? totalCount}) {
    double collected = 0.0;
    double payouts = 0.0;
    double pending = 0.0;
    int pendingNum = 0;

    for (final item in items) {
      if (item.isCredit) {
        collected += item.amount;
      } else if (item.isDebit) {
        payouts += item.amount;
      }

      if (item.isPending) {
        pending += item.amount;
        pendingNum++;
      }
    }

    return BillingMetrics(
      totalInvoices: totalCount ?? items.length,
      totalCollected: collected,
      totalPayouts: payouts,
      pendingAmount: pending,
      pendingCount: pendingNum,
    );
  }

  String get displayTotalInvoices => totalInvoices.toString();

  String get displayTotalCollected {
    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    return formatter.format(totalCollected);
  }

  String get displayTotalPayouts {
    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    return formatter.format(totalPayouts);
  }

  String get displayPendingAmount {
    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    return formatter.format(pendingAmount);
  }

  String get displayPendingCount => pendingCount.toString();
}
