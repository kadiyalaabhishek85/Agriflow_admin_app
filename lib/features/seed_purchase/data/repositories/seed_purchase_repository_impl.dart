import 'package:agriflow_admin/features/seed_purchase/data/datasources/seed_purchase_remote_data_source.dart';
import 'package:agriflow_admin/features/seed_purchase/domain/entities/seed_catalog_item.dart';
import 'package:agriflow_admin/features/seed_purchase/domain/entities/seed_purchase_item.dart';
import 'package:agriflow_admin/features/seed_purchase/domain/entities/seed_purchase_pagination.dart';
import 'package:agriflow_admin/features/seed_purchase/domain/repositories/seed_purchase_repository.dart';

class SeedPurchaseRepositoryImpl implements SeedPurchaseRepository {
  final SeedPurchaseRemoteDataSource remoteDataSource;

  // In-memory cache for relationship enrichment
  final Map<String, SeedCatalogItem> _seedsCache = {};
  final Map<String, ({String name, String phone})> _farmersCache = {};
  bool _catalogsLoaded = false;

  SeedPurchaseRepositoryImpl({required this.remoteDataSource});

  Future<void> _ensureCatalogsLoaded(String accessToken) async {
    if (_catalogsLoaded) return;
    try {
      final seedsFuture = remoteDataSource.getSeeds(accessToken: accessToken);
      final farmersFuture = remoteDataSource.getFarmerLookup(accessToken: accessToken);

      final results = await Future.wait([seedsFuture, farmersFuture]);
      final seedsList = results[0] as List<SeedCatalogItem>;
      final farmersMap = results[1] as Map<String, ({String name, String phone})>;

      for (final seed in seedsList) {
        _seedsCache[seed.id] = seed;
      }
      _farmersCache.addAll(farmersMap);
      _catalogsLoaded = true;
    } catch (_) {
      // Enrichment failure should not block purchase display
    }
  }

  SeedPurchaseItem _enrichItem(SeedPurchaseItem item) {
    final seed = _seedsCache[item.seedId];
    final farmer = _farmersCache[item.farmerId];

    return item.copyWithEnrichment(
      farmerName: farmer?.name,
      farmerPhone: farmer?.phone,
      seedName: seed?.name,
      seedVariety: seed?.variety,
    );
  }

  @override
  Future<({List<SeedPurchaseItem> items, SeedPurchasePagination pagination})> getPurchases({
    required String accessToken,
    int page = 1,
    int pageSize = 20,
    String? search,
    String? status,
  }) async {
    // 1. Fetch raw purchases from backend
    final result = await remoteDataSource.getPurchases(
      accessToken: accessToken,
      page: page,
      pageSize: pageSize,
      search: search,
      status: status,
    );

    // 2. Ensure relationship lookup catalogs are warm
    await _ensureCatalogsLoaded(accessToken);

    // 3. Enrich items with farmer & seed metadata (while keeping backend fields distinct)
    final enrichedItems = result.items.map(_enrichItem).toList();

    return (items: enrichedItems, pagination: result.pagination);
  }

  @override
  Future<SeedPurchaseItem> updatePurchaseStatus({
    required String accessToken,
    required String purchaseId,
    required String newStatus,
  }) async {
    final updated = await remoteDataSource.updatePurchaseStatus(
      accessToken: accessToken,
      purchaseId: purchaseId,
      newStatus: newStatus,
    );
    return _enrichItem(updated);
  }

  @override
  Future<List<SeedCatalogItem>> getSeeds({required String accessToken}) async {
    await _ensureCatalogsLoaded(accessToken);
    return _seedsCache.values.toList();
  }

  @override
  Future<Map<String, ({String name, String phone})>> getFarmerLookup({
    required String accessToken,
  }) async {
    await _ensureCatalogsLoaded(accessToken);
    return _farmersCache;
  }
}
