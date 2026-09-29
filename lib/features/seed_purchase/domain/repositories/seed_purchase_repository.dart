import 'package:agriflow_admin/features/seed_purchase/domain/entities/seed_catalog_item.dart';
import 'package:agriflow_admin/features/seed_purchase/domain/entities/seed_purchase_item.dart';
import 'package:agriflow_admin/features/seed_purchase/domain/entities/seed_purchase_pagination.dart';

abstract class SeedPurchaseRepository {
  /// Fetches paginated seed purchases directly from FastAPI
  Future<({List<SeedPurchaseItem> items, SeedPurchasePagination pagination})> getPurchases({
    required String accessToken,
    int page = 1,
    int pageSize = 20,
    String? search,
    String? status,
  });

  /// Authoritatively updates seed purchase payment status on backend
  Future<SeedPurchaseItem> updatePurchaseStatus({
    required String accessToken,
    required String purchaseId,
    required String newStatus,
  });

  /// Fetches seed catalog for relationship enrichment
  Future<List<SeedCatalogItem>> getSeeds({
    required String accessToken,
  });

  /// Fetches farmers map for relationship enrichment
  Future<Map<String, ({String name, String phone})>> getFarmerLookup({
    required String accessToken,
  });
}
