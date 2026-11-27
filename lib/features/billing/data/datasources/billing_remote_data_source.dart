import '../../domain/entities/billing_pagination.dart';
import '../../domain/entities/billing_transaction_item.dart';

/// Abstract remote data source contract for Billing & Invoices.
abstract class BillingRemoteDataSource {
  Future<({List<BillingTransactionItem> items, BillingPagination pagination})> getTransactions({
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

  Future<BillingTransactionItem> createTransaction({
    required String accessToken,
    required String farmerId,
    required double amount,
    required String direction,
    required String referenceType,
    String? description,
  });

  Future<BillingTransactionItem> payTransaction({
    required String accessToken,
    required String transactionId,
    String? description,
  });

  Future<Map<String, ({String name, String phone, String? village})>> getFarmers({
    required String accessToken,
  });
}
