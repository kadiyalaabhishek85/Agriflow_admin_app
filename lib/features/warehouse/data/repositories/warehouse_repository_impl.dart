import '../../domain/entities/warehouse_inventory_item.dart';
import '../../domain/entities/warehouse_item.dart';
import '../../domain/entities/warehouse_slot_item.dart';
import '../../domain/repositories/warehouse_repository.dart';
import '../datasources/fast_api_warehouse_remote_data_source.dart';

/// Production implementation of [WarehouseRepository].
class WarehouseRepositoryImpl implements WarehouseRepository {
  final WarehouseRemoteDataSource remoteDataSource;

  WarehouseRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<List<WarehouseItem>> getWarehouses({
    required String accessToken,
  }) {
    return remoteDataSource.getWarehouses(accessToken: accessToken);
  }

  @override
  Future<WarehouseItem> getWarehouse({
    required String accessToken,
    required String warehouseId,
  }) {
    return remoteDataSource.getWarehouse(
      accessToken: accessToken,
      warehouseId: warehouseId,
    );
  }

  @override
  Future<WarehouseItem> createWarehouse({
    required String accessToken,
    required String name,
    required String address,
    required double totalCapacityKg,
    String? location,
    String? contactNumber,
    String? managerId,
  }) {
    return remoteDataSource.createWarehouse(
      accessToken: accessToken,
      name: name,
      address: address,
      totalCapacityKg: totalCapacityKg,
      location: location,
      contactNumber: contactNumber,
      managerId: managerId,
    );
  }

  @override
  Future<WarehouseItem> updateWarehouse({
    required String accessToken,
    required String warehouseId,
    String? name,
    String? address,
    double? totalCapacityKg,
    String? location,
    String? contactNumber,
    String? managerId,
    bool? isActive,
  }) {
    return remoteDataSource.updateWarehouse(
      accessToken: accessToken,
      warehouseId: warehouseId,
      name: name,
      address: address,
      totalCapacityKg: totalCapacityKg,
      location: location,
      contactNumber: contactNumber,
      managerId: managerId,
      isActive: isActive,
    );
  }

  @override
  Future<void> deleteWarehouse({
    required String accessToken,
    required String warehouseId,
  }) {
    return remoteDataSource.deleteWarehouse(
      accessToken: accessToken,
      warehouseId: warehouseId,
    );
  }

  @override
  Future<List<WarehouseInventoryItem>> getWarehouseInventory({
    required String accessToken,
    required String warehouseId,
  }) {
    return remoteDataSource.getWarehouseInventory(
      accessToken: accessToken,
      warehouseId: warehouseId,
    );
  }

  @override
  Future<WarehouseInventoryItem> addWarehouseInventory({
    required String accessToken,
    required String warehouseId,
    required String grainType,
    required double quantityKg,
  }) {
    return remoteDataSource.addWarehouseInventory(
      accessToken: accessToken,
      warehouseId: warehouseId,
      grainType: grainType,
      quantityKg: quantityKg,
    );
  }

  @override
  Future<List<WarehouseSlotItem>> getWarehouseSlots({
    required String accessToken,
    required String warehouseId,
  }) {
    return remoteDataSource.getWarehouseSlots(
      accessToken: accessToken,
      warehouseId: warehouseId,
    );
  }

  @override
  Future<List<WarehouseSlotItem>> listWarehouseSlots({
    required String accessToken,
    String? warehouseId,
    String? date,
  }) {
    return remoteDataSource.listWarehouseSlots(
      accessToken: accessToken,
      warehouseId: warehouseId,
      date: date,
    );
  }

  @override
  Future<WarehouseSlotItem> createWarehouseSlot({
    required String accessToken,
    required String warehouseId,
    required String slotDate,
    required String startTime,
    required String endTime,
    required double capacityKg,
  }) {
    return remoteDataSource.createWarehouseSlot(
      accessToken: accessToken,
      warehouseId: warehouseId,
      slotDate: slotDate,
      startTime: startTime,
      endTime: endTime,
      capacityKg: capacityKg,
    );
  }

  @override
  Future<WarehouseSlotItem> updateWarehouseSlot({
    required String accessToken,
    required String slotId,
    String? status,
    double? capacityKg,
  }) {
    return remoteDataSource.updateWarehouseSlot(
      accessToken: accessToken,
      slotId: slotId,
      status: status,
      capacityKg: capacityKg,
    );
  }

  @override
  Future<void> deleteWarehouseSlot({
    required String accessToken,
    required String slotId,
  }) {
    return remoteDataSource.deleteWarehouseSlot(
      accessToken: accessToken,
      slotId: slotId,
    );
  }

  /// Aggregates active (non-cancelled) booking grain quantities for a warehouse
  /// when capacity is occupied by farmer bookings not yet logged in manual inventory.
  Future<List<WarehouseInventoryItem>> getBookedStockForWarehouse({
    required String accessToken,
    required String warehouseId,
  }) async {
    final ds = remoteDataSource;
    if (ds is FastApiWarehouseRemoteDataSource) {
      return ds.getBookedStockForWarehouse(
        accessToken: accessToken,
        warehouseId: warehouseId,
      );
    }
    return const [];
  }
}
