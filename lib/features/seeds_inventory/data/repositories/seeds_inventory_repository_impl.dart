import '../../domain/entities/seed_inventory_item.dart';
import '../../domain/entities/seed_warehouse_brief.dart';
import '../../domain/repositories/seeds_inventory_repository.dart';
import '../datasources/fast_api_seeds_inventory_remote_data_source.dart';

/// Implementation of SeedsInventoryRepository delegating to SeedsInventoryRemoteDataSource.
class SeedsInventoryRepositoryImpl implements SeedsInventoryRepository {
  final SeedsInventoryRemoteDataSource remoteDataSource;

  SeedsInventoryRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<List<SeedInventoryItem>> getSeeds({required String accessToken}) {
    return remoteDataSource.getSeeds(accessToken: accessToken);
  }

  @override
  Future<SeedInventoryItem> getSeed({
    required String accessToken,
    required String seedId,
  }) {
    return remoteDataSource.getSeed(
      accessToken: accessToken,
      seedId: seedId,
    );
  }

  @override
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
  }) {
    return remoteDataSource.createSeed(
      accessToken: accessToken,
      name: name,
      pricePerKg: pricePerKg,
      stockKg: stockKg,
      cropType: cropType,
      variety: variety,
      priceGradeA: priceGradeA,
      priceGradeB: priceGradeB,
      priceGradeC: priceGradeC,
      maxOrderQuantityKg: maxOrderQuantityKg,
      warehouseIds: warehouseIds,
      description: description,
      imageUrl: imageUrl,
    );
  }

  @override
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
  }) {
    return remoteDataSource.updateSeed(
      accessToken: accessToken,
      seedId: seedId,
      name: name,
      cropType: cropType,
      variety: variety,
      pricePerKg: pricePerKg,
      priceGradeA: priceGradeA,
      priceGradeB: priceGradeB,
      priceGradeC: priceGradeC,
      maxOrderQuantityKg: maxOrderQuantityKg,
      stockKg: stockKg,
      warehouseIds: warehouseIds,
      description: description,
      imageUrl: imageUrl,
      isActive: isActive,
    );
  }

  @override
  Future<void> deleteSeed({
    required String accessToken,
    required String seedId,
  }) {
    return remoteDataSource.deleteSeed(
      accessToken: accessToken,
      seedId: seedId,
    );
  }

  @override
  Future<List<SeedWarehouseBrief>> getWarehouses({required String accessToken}) {
    return remoteDataSource.getWarehouses(accessToken: accessToken);
  }

  @override
  Future<List<SeedWarehouseBrief>> getSeedWarehouses({
    required String accessToken,
    required String seedId,
  }) {
    return remoteDataSource.getSeedWarehouses(
      accessToken: accessToken,
      seedId: seedId,
    );
  }

  @override
  Future<List<SeedWarehouseBrief>> assignSeedWarehouses({
    required String accessToken,
    required String seedId,
    required List<String> warehouseIds,
  }) {
    return remoteDataSource.assignSeedWarehouses(
      accessToken: accessToken,
      seedId: seedId,
      warehouseIds: warehouseIds,
    );
  }

  @override
  Future<void> removeSeedWarehouse({
    required String accessToken,
    required String seedId,
    required String warehouseId,
  }) {
    return remoteDataSource.removeSeedWarehouse(
      accessToken: accessToken,
      seedId: seedId,
      warehouseId: warehouseId,
    );
  }

  @override
  Future<String> uploadSeedImage({
    required String accessToken,
    required List<int> fileBytes,
    required String fileName,
    String contentType = 'image/jpeg',
  }) {
    return remoteDataSource.uploadSeedImage(
      accessToken: accessToken,
      fileBytes: fileBytes,
      fileName: fileName,
      contentType: contentType,
    );
  }
}
