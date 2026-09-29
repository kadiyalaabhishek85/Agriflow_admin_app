import '../entities/billing_metrics.dart';
import '../entities/billing_pagination.dart';
import '../entities/billing_transaction_item.dart';

/// Abstract repository contract for Billing & Invoices data access.
abstract class BillingRepository {
  /// Fetches paginated list of transactions with server-side filters.
  Future<({List<BillingTransactionItem> items, BillingPagination pagination, BillingMetrics metrics})>
      getTransactions({
    required String accessToken,
    int page = 1,
    int pageSize = 20,
    String? search,
    String? referenceType,
    String? direction,
    String? status,
    String? fromDate,
    String? toDate,
    String? sort,
    String? order,
  });

  /// Settles payment for a pending transaction via PATCH /api/v1/transactions/{id}/pay.
  Future<BillingTransactionItem> payTransaction({
    required String accessToken,
    required String transactionId,
    String? description,
  });

  /// Fetches farmer catalog for name/phone enrichment.
  Future<Map<String, ({String name, String phone, String? village})>> getFarmerLookup({
    required String accessToken,
  });
}
