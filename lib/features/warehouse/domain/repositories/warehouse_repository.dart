import '../entities/warehouse_inventory_item.dart';
import '../entities/warehouse_item.dart';
import '../entities/warehouse_slot_item.dart';

/// Domain contract for Warehouse operations.
abstract class WarehouseRepository {
  /// Fetch all active warehouse locations.
  Future<List<WarehouseItem>> getWarehouses({
    required String accessToken,
  });

  /// Fetch single warehouse details by UUID.
  Future<WarehouseItem> getWarehouse({
    required String accessToken,
    required String warehouseId,
  });

  /// Create a new warehouse facility (Admin only).
  Future<WarehouseItem> createWarehouse({
    required String accessToken,
    required String name,
    required String address,
    required double totalCapacityKg,
    String? location,
    String? contactNumber,
    String? managerId,
  });

  /// Update warehouse metadata & capacity (Admin only).
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
  });

  /// Hard delete a warehouse facility (Admin only).
  Future<void> deleteWarehouse({
    required String accessToken,
    required String warehouseId,
  });

  /// Get inventory grain breakdown for a warehouse.
  Future<List<WarehouseInventoryItem>> getWarehouseInventory({
    required String accessToken,
    required String warehouseId,
  });

  /// Add grain stock intake to a warehouse.
  Future<WarehouseInventoryItem> addWarehouseInventory({
    required String accessToken,
    required String warehouseId,
    required String grainType,
    required double quantityKg,
  });

  /// List booking slots for a specific warehouse.
  Future<List<WarehouseSlotItem>> getWarehouseSlots({
    required String accessToken,
    required String warehouseId,
  });

  /// Query booking slots with optional warehouseId or date filter.
  Future<List<WarehouseSlotItem>> listWarehouseSlots({
    required String accessToken,
    String? warehouseId,
    String? date,
  });

  /// Create a new booking slot for farmer grain intake.
  Future<WarehouseSlotItem> createWarehouseSlot({
    required String accessToken,
    required String warehouseId,
    required String slotDate,
    required String startTime,
    required String endTime,
    required double capacityKg,
  });

  /// Update slot status ('active' | 'cancelled') or capacity.
  Future<WarehouseSlotItem> updateWarehouseSlot({
    required String accessToken,
    required String slotId,
    String? status,
    double? capacityKg,
  });

  /// Delete a booking slot by ID.
  Future<void> deleteWarehouseSlot({
    required String accessToken,
    required String slotId,
  });
}
