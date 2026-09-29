import '../entities/seed_inventory_item.dart';
import '../entities/seed_warehouse_brief.dart';

/// Abstract repository interface for Seeds Inventory module.
/// Strictly maps to FastAPI live contracts including multi-warehouse assignments and grade pricing.
abstract class SeedsInventoryRepository {
  /// Fetch all seeds in the master catalog.
  Future<List<SeedInventoryItem>> getSeeds({required String accessToken});

  /// Fetch a single seed by ID.
  Future<SeedInventoryItem> getSeed({
    required String accessToken,
    required String seedId,
  });

  /// Create a new seed product (Admin only).
  Future<SeedInventoryItem> createSeed({
    required String accessToken,
    required String name,
    required double pricePerKg,
    required double stockKg,
    String? cropType,
    String? variety,
    double? priceGradeA,
    double? priceGradeB,
    double? priceGradeC,
    double? maxOrderQuantityKg,
    List<String>? warehouseIds,
    String? description,
    String? imageUrl,
  });

  /// Update existing seed product (Admin only).
  Future<SeedInventoryItem> updateSeed({
    required String accessToken,
    required String seedId,
    String? name,
    String? cropType,
    String? variety,
    double? pricePerKg,
    double? priceGradeA,
    double? priceGradeB,
    double? priceGradeC,
    double? maxOrderQuantityKg,
    double? stockKg,
    List<String>? warehouseIds,
    String? description,
    String? imageUrl,
    bool? isActive,
  });

  /// Delete a seed product from the catalog (Admin only).
  Future<void> deleteSeed({
    required String accessToken,
    required String seedId,
  });

  /// Fetch available warehouses from `/api/v1/warehouses`.
  Future<List<SeedWarehouseBrief>> getWarehouses({required String accessToken});

  /// Fetch warehouses assigned to a specific seed from `/api/v1/seeds/{id}/warehouses`.
  Future<List<SeedWarehouseBrief>> getSeedWarehouses({
    required String accessToken,
    required String seedId,
  });

  /// Assign warehouses to a seed from `/api/v1/seeds/{id}/warehouses`.
  Future<List<SeedWarehouseBrief>> assignSeedWarehouses({
    required String accessToken,
    required String seedId,
    required List<String> warehouseIds,
  });

  /// Remove a warehouse assignment from `/api/v1/seeds/{id}/warehouses/{warehouse_id}`.
  Future<void> removeSeedWarehouse({
    required String accessToken,
    required String seedId,
    required String warehouseId,
  });

  /// Upload seed image via `/api/v1/uploads` with bucket="seeds".
  Future<String> uploadSeedImage({
    required String accessToken,
    required List<int> fileBytes,
    required String fileName,
    String contentType = 'image/jpeg',
  });
}
