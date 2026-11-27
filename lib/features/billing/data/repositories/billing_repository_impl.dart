import '../../domain/entities/billing_metrics.dart';
import '../../domain/entities/billing_pagination.dart';
import '../../domain/entities/billing_transaction_item.dart';
import '../../domain/repositories/billing_repository.dart';
import '../datasources/billing_remote_data_source.dart';

/// Implementation of BillingRepository communicating with BillingRemoteDataSource.
class BillingRepositoryImpl implements BillingRepository {
  final BillingRemoteDataSource remoteDataSource;

  BillingRepositoryImpl({required this.remoteDataSource});

  @override
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
  }) async {
    final result = await remoteDataSource.getTransactions(
      accessToken: accessToken,
      page: page,
      pageSize: pageSize,
      search: search,
      referenceType: referenceType,
      direction: direction,
      status: status,
      fromDate: fromDate,
      toDate: toDate,
      sort: sort,
      order: order,
    );

    final metrics = BillingMetrics.fromTransactions(
      result.items,
      totalCount: result.pagination.total,
    );

    return (
      items: result.items,
      pagination: result.pagination,
      metrics: metrics,
    );
  }

  @override
  Future<BillingTransactionItem> createTransaction({
    required String accessToken,
    required String farmerId,
    required double amount,
    required String direction,
    required String referenceType,
    String? description,
  }) async {
    return await remoteDataSource.createTransaction(
      accessToken: accessToken,
      farmerId: farmerId,
      amount: amount,
      direction: direction,
      referenceType: referenceType,
      description: description,
    );
  }

  @override
  Future<BillingTransactionItem> payTransaction({
    required String accessToken,
    required String transactionId,
    String? description,
  }) async {
    return await remoteDataSource.payTransaction(
      accessToken: accessToken,
      transactionId: transactionId,
      description: description,
    );
  }

  @override
  Future<Map<String, ({String name, String phone, String? village})>> getFarmerLookup({
    required String accessToken,
  }) async {
    return await remoteDataSource.getFarmers(accessToken: accessToken);
  }
}
