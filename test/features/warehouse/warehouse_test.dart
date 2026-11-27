import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:agriflow_admin/features/warehouse/domain/entities/warehouse_item.dart';
import 'package:agriflow_admin/features/warehouse/domain/entities/warehouse_inventory_item.dart';
import 'package:agriflow_admin/features/warehouse/domain/entities/warehouse_slot_item.dart';
import 'package:agriflow_admin/features/warehouse/domain/exceptions/warehouse_exception.dart';
import 'package:agriflow_admin/features/warehouse/domain/repositories/warehouse_repository.dart';
import 'package:agriflow_admin/features/warehouse/data/datasources/fast_api_warehouse_remote_data_source.dart';
import 'package:agriflow_admin/features/warehouse/data/repositories/warehouse_repository_impl.dart';
import 'package:agriflow_admin/features/warehouse/presentation/controllers/warehouse_controller.dart';
import 'package:agriflow_admin/features/warehouse/presentation/screens/warehouse_screen.dart';
import 'package:agriflow_admin/features/warehouse/presentation/widgets/warehouse_card.dart';
import 'package:agriflow_admin/features/warehouse/presentation/widgets/warehouse_detail_sheet.dart';
import 'package:agriflow_admin/features/warehouse/presentation/widgets/add_edit_warehouse_sheet.dart';
import 'package:agriflow_admin/features/warehouse/presentation/widgets/add_inventory_sheet.dart';
import 'package:agriflow_admin/features/warehouse/presentation/widgets/create_slot_sheet.dart';

// =========================================================================
// MOCK REPOSITORY IMPLEMENTATION FOR TESTS
// =========================================================================

class MockWarehouseRepository implements WarehouseRepository {
  List<WarehouseItem> warehouses = [];
  Map<String, List<WarehouseInventoryItem>> inventoryMap = {};
  Map<String, List<WarehouseSlotItem>> slotsMap = {};

  bool shouldThrow = false;
  WarehouseException? exceptionToThrow;

  @override
  Future<List<WarehouseItem>> getWarehouses({required String accessToken}) async {
    if (shouldThrow) {
      throw exceptionToThrow ?? const WarehouseServerException();
    }
    return List.from(warehouses);
  }

  @override
  Future<WarehouseItem> getWarehouse({
    required String accessToken,
    required String warehouseId,
  }) async {
    if (shouldThrow) {
      throw exceptionToThrow ?? const WarehouseServerException();
    }
    final index = warehouses.indexWhere((w) => w.id == warehouseId);
    if (index == -1) {
      throw const WarehouseNotFoundException();
    }
    return warehouses[index];
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
    bool isActive = true,
  }) async {
    if (shouldThrow) {
      throw exceptionToThrow ?? const WarehouseServerException();
    }
    final item = WarehouseItem(
      id: 'wh-${warehouses.length + 1}',
      name: name,
      address: address,
      totalCapacityKg: totalCapacityKg,
      currentLoadKg: 0.0,
      location: location,
      contactNumber: contactNumber,
      managerId: managerId,
      isActive: isActive,
    );
    warehouses.add(item);
    return item;
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
  }) async {
    if (shouldThrow) {
      throw exceptionToThrow ?? const WarehouseServerException();
    }
    final index = warehouses.indexWhere((w) => w.id == warehouseId);
    if (index == -1) {
      throw const WarehouseNotFoundException();
    }
    final current = warehouses[index];
    final updated = current.copyWith(
      name: name ?? current.name,
      address: address ?? current.address,
      totalCapacityKg: totalCapacityKg ?? current.totalCapacityKg,
      location: location ?? current.location,
      contactNumber: contactNumber ?? current.contactNumber,
      managerId: managerId ?? current.managerId,
      isActive: isActive ?? current.isActive,
    );
    warehouses[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteWarehouse({
    required String accessToken,
    required String warehouseId,
  }) async {
    if (shouldThrow) {
      throw exceptionToThrow ?? const WarehouseServerException();
    }
    warehouses.removeWhere((w) => w.id == warehouseId);
  }

  @override
  Future<List<WarehouseInventoryItem>> getWarehouseInventory({
    required String accessToken,
    required String warehouseId,
  }) async {
    if (shouldThrow) {
      throw exceptionToThrow ?? const WarehouseServerException();
    }
    return List.from(inventoryMap[warehouseId] ?? []);
  }

  @override
  Future<WarehouseInventoryItem> addWarehouseInventory({
    required String accessToken,
    required String warehouseId,
    required String grainType,
    required double quantityKg,
  }) async {
    if (shouldThrow) {
      throw exceptionToThrow ?? const WarehouseServerException();
    }
    final item = WarehouseInventoryItem(
      id: 'inv-${DateTime.now().millisecondsSinceEpoch}',
      warehouseId: warehouseId,
      grainType: grainType,
      quantityKg: quantityKg,
    );
    inventoryMap.putIfAbsent(warehouseId, () => []).add(item);

    // Update warehouse current load
    final whIndex = warehouses.indexWhere((w) => w.id == warehouseId);
    if (whIndex != -1) {
      final currentWh = warehouses[whIndex];
      warehouses[whIndex] = currentWh.copyWith(
        currentLoadKg: currentWh.currentLoadKg + quantityKg,
      );
    }
    return item;
  }

  @override
  Future<List<WarehouseSlotItem>> getWarehouseSlots({
    required String accessToken,
    required String warehouseId,
  }) async {
    if (shouldThrow) {
      throw exceptionToThrow ?? const WarehouseServerException();
    }
    return List.from(slotsMap[warehouseId] ?? []);
  }

  @override
  Future<List<WarehouseSlotItem>> listWarehouseSlots({
    required String accessToken,
    String? warehouseId,
    String? date,
  }) async {
    if (shouldThrow) {
      throw exceptionToThrow ?? const WarehouseServerException();
    }
    if (warehouseId != null) {
      return List.from(slotsMap[warehouseId] ?? []);
    }
    final allSlots = <WarehouseSlotItem>[];
    for (final list in slotsMap.values) {
      allSlots.addAll(list);
    }
    return allSlots;
  }

  @override
  Future<WarehouseSlotItem> createWarehouseSlot({
    required String accessToken,
    required String warehouseId,
    required String slotDate,
    required String startTime,
    required String endTime,
    required double capacityKg,
  }) async {
    if (shouldThrow) {
      throw exceptionToThrow ?? const WarehouseServerException();
    }
    final item = WarehouseSlotItem(
      id: 'slot-${DateTime.now().millisecondsSinceEpoch}',
      warehouseId: warehouseId,
      slotDate: slotDate,
      startTime: startTime,
      endTime: endTime,
      capacityKg: capacityKg,
      bookedKg: 0.0,
      status: 'active',
    );
    slotsMap.putIfAbsent(warehouseId, () => []).add(item);
    return item;
  }

  @override
  Future<WarehouseSlotItem> updateWarehouseSlot({
    required String accessToken,
    required String slotId,
    String? status,
    double? capacityKg,
  }) async {
    if (shouldThrow) {
      throw exceptionToThrow ?? const WarehouseServerException();
    }
    for (final entry in slotsMap.entries) {
      final list = entry.value;
      final index = list.indexWhere((s) => s.id == slotId);
      if (index != -1) {
        final current = list[index];
        final updated = current.copyWith(
          status: status ?? current.status,
          capacityKg: capacityKg ?? current.capacityKg,
        );
        list[index] = updated;
        return updated;
      }
    }
    throw const WarehouseNotFoundException();
  }

  @override
  Future<void> deleteWarehouseSlot({
    required String accessToken,
    required String slotId,
  }) async {
    if (shouldThrow) {
      throw exceptionToThrow ?? const WarehouseServerException();
    }
    for (final entry in slotsMap.entries) {
      entry.value.removeWhere((s) => s.id == slotId);
    }
  }
}

// =========================================================================
// TEST SUITE
// =========================================================================

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // =========================================================================
  // 1. DOMAIN LAYER TESTS (Entity, Computations, Capacity, Conversions)
  // =========================================================================

  group('Milestone 5 Step 7 — Domain Entity (WarehouseItem)', () {
    test('parses from standard FastAPI WarehouseResponse JSON correctly', () {
      final json = {
        'id': 'wh-001',
        'name': 'Kurnool Central Grain Terminal',
        'address': 'Industrial Area, NH-44, Kurnool, AP',
        'total_capacity_kg': '100000.00',
        'current_load_kg': '45000.00',
        'location': 'Kurnool',
        'contact_number': '+91 9876543210',
        'manager_id': 'mgr-001',
        'is_active': true,
      };

      final item = WarehouseItem.fromJson(json);

      expect(item.id, 'wh-001');
      expect(item.name, 'Kurnool Central Grain Terminal');
      expect(item.address, 'Industrial Area, NH-44, Kurnool, AP');
      expect(item.totalCapacityKg, 100000.0);
      expect(item.currentLoadKg, 45000.0);
      expect(item.location, 'Kurnool');
      expect(item.contactNumber, '+91 9876543210');
      expect(item.managerId, 'mgr-001');
      expect(item.isActive, isTrue);
    });

    test('handles numeric types and null optional fields safely', () {
      final json = {
        'id': 'wh-002',
        'name': 'Adoni Storage Depot',
        'address': 'Cotton Market Road, Adoni',
        'total_capacity_kg': 50000,
        'current_load_kg': 0,
        'location': null,
        'contact_number': null,
        'manager_id': null,
        'is_active': false,
      };

      final item = WarehouseItem.fromJson(json);

      expect(item.location, isNull);
      expect(item.contactNumber, isNull);
      expect(item.managerId, isNull);
      expect(item.totalCapacityKg, 50000.0);
      expect(item.currentLoadKg, 0.0);
      expect(item.isActive, isFalse);
    });

    test('calculates Quintal conversion accurately (1 Qtl = 100 Kg)', () {
      const item = WarehouseItem(
        id: 'wh-003',
        name: 'Nandyal Depot',
        address: 'Market Yard',
        totalCapacityKg: 50000.0,
        currentLoadKg: 25000.0,
      );

      // 50,000 Kg / 100 = 500 Qtl
      expect(item.totalCapacityQtl, 500.0);
      expect(item.displayTotalCapacityQtl, '500.00');

      // 25,000 Kg / 100 = 250 Qtl
      expect(item.currentLoadQtl, 250.0);
      expect(item.displayCurrentLoadQtl, '250.00');

      // Available: 25,000 Kg = 250 Qtl
      expect(item.availableCapacityKg, 25000.0);
      expect(item.availableCapacityQtl, 250.0);
      expect(item.displayAvailableCapacityQtl, '250.00');
    });

    test('protects against zero total capacity and division by zero', () {
      const zeroCapacityItem = WarehouseItem(
        id: 'wh-zero',
        name: 'Empty Shell',
        address: 'Nowhere',
        totalCapacityKg: 0.0,
        currentLoadKg: 0.0,
      );

      expect(zeroCapacityItem.occupancyPercent, 0.0);
      expect(zeroCapacityItem.displayOccupancyPercent, '0.0');
      expect(zeroCapacityItem.isSafeOccupancy, isTrue);
      expect(zeroCapacityItem.isOverCapacity, isFalse);
    });

    test('accurately calculates occupancy percentage and thresholds', () {
      // 1. Safe (< 60%)
      const safeItem = WarehouseItem(
        id: 'wh-safe',
        name: 'Safe',
        address: 'A',
        totalCapacityKg: 10000.0,
        currentLoadKg: 5000.0, // 50%
      );
      expect(safeItem.occupancyPercent, 50.0);
      expect(safeItem.isSafeOccupancy, isTrue);
      expect(safeItem.isModerateOccupancy, isFalse);
      expect(safeItem.isNearCapacity, isFalse);
      expect(safeItem.isOverCapacity, isFalse);

      // 2. Moderate (60% - 80%)
      const moderateItem = WarehouseItem(
        id: 'wh-mod',
        name: 'Moderate',
        address: 'B',
        totalCapacityKg: 10000.0,
        currentLoadKg: 7500.0, // 75%
      );
      expect(moderateItem.occupancyPercent, 75.0);
      expect(moderateItem.isSafeOccupancy, isFalse);
      expect(moderateItem.isModerateOccupancy, isTrue);
      expect(moderateItem.isNearCapacity, isFalse);
      expect(moderateItem.isOverCapacity, isFalse);

      // 3. Near Capacity (> 80% and < 100%)
      const nearItem = WarehouseItem(
        id: 'wh-near',
        name: 'Near',
        address: 'C',
        totalCapacityKg: 10000.0,
        currentLoadKg: 8500.0, // 85%
      );
      expect(nearItem.occupancyPercent, 85.0);
      expect(nearItem.isSafeOccupancy, isFalse);
      expect(nearItem.isModerateOccupancy, isFalse);
      expect(nearItem.isNearCapacity, isTrue);
      expect(nearItem.isOverCapacity, isFalse);

      // 4. Over Capacity (>= 100%)
      const overItem = WarehouseItem(
        id: 'wh-over',
        name: 'Over',
        address: 'D',
        totalCapacityKg: 10000.0,
        currentLoadKg: 10500.0, // 105%
      );
      expect(overItem.occupancyPercent, 105.0);
      expect(overItem.isSafeOccupancy, isFalse);
      expect(overItem.isModerateOccupancy, isFalse);
      expect(overItem.isNearCapacity, isFalse);
      expect(overItem.isOverCapacity, isTrue);
      expect(overItem.availableCapacityKg, 0.0);
    });

    test('serializes to JSON correctly', () {
      const item = WarehouseItem(
        id: 'wh-001',
        name: 'Kurnool Depot',
        address: 'NH-44',
        totalCapacityKg: 50000.0,
        currentLoadKg: 15000.0,
        location: 'Kurnool',
        contactNumber: '1234567890',
        managerId: 'mgr-1',
        isActive: true,
      );

      final json = item.toJson();
      expect(json['id'], 'wh-001');
      expect(json['name'], 'Kurnool Depot');
      expect(json['total_capacity_kg'], 50000.0);
      expect(json['current_load_kg'], 15000.0);
      expect(json['is_active'], isTrue);
    });
  });

  group('Milestone 5 Step 7 — Domain Entity (WarehouseInventoryItem)', () {
    test('parses JSON and calculates Qtl correctly', () {
      final json = {
        'id': 'inv-1',
        'warehouse_id': 'wh-1',
        'grain_type': 'Paddy',
        'quantity_kg': '15500.00',
        'created_at': '2026-09-27T10:00:00Z',
      };

      final item = WarehouseInventoryItem.fromJson(json);

      expect(item.id, 'inv-1');
      expect(item.warehouseId, 'wh-1');
      expect(item.grainType, 'Paddy');
      expect(item.quantityKg, 15500.0);
      expect(item.quantityQtl, 155.0);
      expect(item.displayQuantityQtl, '155.00');
      expect(item.displayQuantityKg, '15500');
    });
  });

  group('Milestone 5 Step 7 — Domain Entity (WarehouseSlotItem)', () {
    test('parses JSON, computes available capacity, and detects active/cancelled', () {
      final json = {
        'id': 'slot-1',
        'warehouse_id': 'wh-1',
        'slot_date': '2026-10-01',
        'start_time': '09:00:00',
        'end_time': '12:00:00',
        'capacity_kg': '10000.00',
        'booked_kg': '4000.00',
        'status': 'active',
      };

      final item = WarehouseSlotItem.fromJson(json);

      expect(item.id, 'slot-1');
      expect(item.capacityKg, 10000.0);
      expect(item.bookedKg, 4000.0);
      expect(item.capacityQtl, 100.0);
      expect(item.bookedQtl, 40.0);
      expect(item.availableKg, 6000.0);
      expect(item.availableQtl, 60.0);
      expect(item.isActive, isTrue);
      expect(item.isCancelled, isFalse);
      expect(item.displayTimeRange, '09:00 - 12:00');
    });

    test('detects cancelled status accurately', () {
      final json = {
        'id': 'slot-2',
        'warehouse_id': 'wh-1',
        'slot_date': '2026-10-01',
        'start_time': '13:00',
        'end_time': '16:00',
        'capacity_kg': 5000,
        'booked_kg': 0,
        'status': 'cancelled',
      };

      final item = WarehouseSlotItem.fromJson(json);
      expect(item.isActive, isFalse);
      expect(item.isCancelled, isTrue);
    });
  });

  group('Milestone 5 Step 7 — Exceptions', () {
    test('exception hierarchy preserves messages', () {
      const e401 = WarehouseUnauthorizedException(message: 'Unauthorized token');
      expect(e401.message, 'Unauthorized token');

      const e403 = WarehouseForbiddenException(message: 'Admin only');
      expect(e403.message, 'Admin only');

      const e404 = WarehouseNotFoundException(message: 'Warehouse not found');
      expect(e404.message, 'Warehouse not found');

      const e409 = WarehouseConflictException(message: 'Slot conflict');
      expect(e409.message, 'Slot conflict');

      const e422 = WarehouseValidationException(message: 'Invalid capacity');
      expect(e422.message, 'Invalid capacity');

      const e500 = WarehouseServerException(message: 'Internal error');
      expect(e500.message, 'Internal error');

      const eNet = WarehouseNetworkException(message: 'Network lost');
      expect(eNet.message, 'Network lost');
    });
  });

  // =========================================================================
  // 2. DATA SOURCE & REPOSITORY TESTS (HTTP, Status Codes, Mappings)
  // =========================================================================

  group('Milestone 5 Step 7 — Data Source & Repository', () {
    test('getWarehouses parses JSON array correctly', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/v1/warehouses') {
          return http.Response(
            jsonEncode([
              {
                'id': 'wh-1',
                'name': 'Kurnool Depot',
                'address': 'NH-44',
                'total_capacity_kg': 50000.0,
                'current_load_kg': 10000.0,
                'is_active': true,
              }
            ]),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final dataSource = FastApiWarehouseRemoteDataSource(
        baseUrl: 'https://test.api.com',
        client: mockClient,
      );
      final repo = WarehouseRepositoryImpl(remoteDataSource: dataSource);

      final list = await repo.getWarehouses(accessToken: 'token');
      expect(list.length, 1);
      expect(list.first.name, 'Kurnool Depot');
      expect(list.first.totalCapacityKg, 50000.0);
    });

    test('createWarehouse sends POST and parses response', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/v1/warehouses' && request.method == 'POST') {
          final body = jsonDecode(request.body);
          expect(body['name'], 'New Terminal');
          expect(body['total_capacity_kg'], 60000.0);

          return http.Response(
            jsonEncode({
              'id': 'wh-new',
              'name': body['name'],
              'address': body['address'],
              'total_capacity_kg': body['total_capacity_kg'],
              'current_load_kg': 0.0,
              'is_active': true,
            }),
            201,
          );
        }
        return http.Response('Error', 400);
      });

      final dataSource = FastApiWarehouseRemoteDataSource(
        baseUrl: 'https://test.api.com',
        client: mockClient,
      );
      final repo = WarehouseRepositoryImpl(remoteDataSource: dataSource);

      final created = await repo.createWarehouse(
        accessToken: 'token',
        name: 'New Terminal',
        address: 'Main Road',
        totalCapacityKg: 60000.0,
      );

      expect(created.id, 'wh-new');
      expect(created.name, 'New Terminal');
    });

    test('updateWarehouse sends PATCH with fields', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/v1/warehouses/wh-1' && request.method == 'PATCH') {
          final body = jsonDecode(request.body);
          expect(body['name'], 'Updated Name');
          return http.Response(
            jsonEncode({
              'id': 'wh-1',
              'name': 'Updated Name',
              'address': 'Address 1',
              'total_capacity_kg': 50000.0,
              'current_load_kg': 10000.0,
              'is_active': true,
            }),
            200,
          );
        }
        return http.Response('Error', 400);
      });

      final dataSource = FastApiWarehouseRemoteDataSource(
        baseUrl: 'https://test.api.com',
        client: mockClient,
      );
      final repo = WarehouseRepositoryImpl(remoteDataSource: dataSource);

      final updated = await repo.updateWarehouse(
        accessToken: 'token',
        warehouseId: 'wh-1',
        name: 'Updated Name',
      );

      expect(updated.name, 'Updated Name');
    });

    test('deleteWarehouse sends DELETE', () async {
      bool deleted = false;
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/v1/warehouses/wh-1' && request.method == 'DELETE') {
          deleted = true;
          return http.Response('', 204);
        }
        return http.Response('Error', 400);
      });

      final dataSource = FastApiWarehouseRemoteDataSource(
        baseUrl: 'https://test.api.com',
        client: mockClient,
      );
      final repo = WarehouseRepositoryImpl(remoteDataSource: dataSource);

      await repo.deleteWarehouse(accessToken: 'token', warehouseId: 'wh-1');
      expect(deleted, isTrue);
    });

    test('maps HTTP status codes to typed exceptions correctly', () async {
      void testStatus(int code, Type expectedType) async {
        final mockClient = MockClient((request) async {
          return http.Response(jsonEncode({'detail': 'Test Error'}), code);
        });

        final dataSource = FastApiWarehouseRemoteDataSource(
          baseUrl: 'https://test.api.com',
          client: mockClient,
        );
        final repo = WarehouseRepositoryImpl(remoteDataSource: dataSource);

        expect(
          () => repo.getWarehouses(accessToken: 'token'),
          throwsA(isA<WarehouseException>().having((e) => e.runtimeType, 'type', expectedType)),
        );
      }

      testStatus(401, WarehouseUnauthorizedException);
      testStatus(403, WarehouseForbiddenException);
      testStatus(404, WarehouseNotFoundException);
      testStatus(409, WarehouseConflictException);
      testStatus(422, WarehouseValidationException);
      testStatus(500, WarehouseServerException);
    });

    test('addWarehouseInventory sends POST /warehouses/{id}/inventory', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/v1/warehouses/wh-1/inventory' && request.method == 'POST') {
          final body = jsonDecode(request.body);
          expect(body['grain_type'], 'Wheat');
          expect(body['quantity_kg'], 5000.0);

          return http.Response(
            jsonEncode({
              'id': 'inv-101',
              'warehouse_id': 'wh-1',
              'grain_type': 'Wheat',
              'quantity_kg': 5000.0,
            }),
            201,
          );
        }
        return http.Response('Error', 400);
      });

      final dataSource = FastApiWarehouseRemoteDataSource(
        baseUrl: 'https://test.api.com',
        client: mockClient,
      );
      final repo = WarehouseRepositoryImpl(remoteDataSource: dataSource);

      final inv = await repo.addWarehouseInventory(
        accessToken: 'token',
        warehouseId: 'wh-1',
        grainType: 'Wheat',
        quantityKg: 5000.0,
      );

      expect(inv.id, 'inv-101');
      expect(inv.quantityKg, 5000.0);
    });

    test('createWarehouseSlot sends POST /warehouse-slots', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/v1/warehouse-slots' && request.method == 'POST') {
          final body = jsonDecode(request.body);
          expect(body['warehouse_id'], 'wh-1');
          expect(body['capacity_kg'], 10000.0);

          return http.Response(
            jsonEncode({
              'id': 'slot-new',
              'warehouse_id': 'wh-1',
              'slot_date': '2026-10-02',
              'start_time': '09:00',
              'end_time': '12:00',
              'capacity_kg': 10000.0,
              'booked_kg': 0.0,
              'status': 'active',
            }),
            201,
          );
        }
        return http.Response('Error', 400);
      });

      final dataSource = FastApiWarehouseRemoteDataSource(
        baseUrl: 'https://test.api.com',
        client: mockClient,
      );
      final repo = WarehouseRepositoryImpl(remoteDataSource: dataSource);

      final slot = await repo.createWarehouseSlot(
        accessToken: 'token',
        warehouseId: 'wh-1',
        slotDate: '2026-10-02',
        startTime: '09:00',
        endTime: '12:00',
        capacityKg: 10000.0,
      );

      expect(slot.id, 'slot-new');
      expect(slot.status, 'active');
    });

    test('updateWarehouseSlot with status cancelled sends PATCH', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/v1/warehouse-slots/slot-1' && request.method == 'PATCH') {
          final body = jsonDecode(request.body);
          expect(body['status'], 'cancelled');

          return http.Response(
            jsonEncode({
              'id': 'slot-1',
              'warehouse_id': 'wh-1',
              'slot_date': '2026-10-02',
              'start_time': '09:00',
              'end_time': '12:00',
              'capacity_kg': 10000.0,
              'booked_kg': 0.0,
              'status': 'cancelled',
            }),
            200,
          );
        }
        return http.Response('Error', 400);
      });

      final dataSource = FastApiWarehouseRemoteDataSource(
        baseUrl: 'https://test.api.com',
        client: mockClient,
      );
      final repo = WarehouseRepositoryImpl(remoteDataSource: dataSource);

      final updated = await repo.updateWarehouseSlot(
        accessToken: 'token',
        slotId: 'slot-1',
        status: 'cancelled',
      );

      expect(updated.isCancelled, isTrue);
    });

    test('deleteWarehouseSlot sends DELETE /warehouse-slots/{id}', () async {
      bool deleted = false;
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/v1/warehouse-slots/slot-1' && request.method == 'DELETE') {
          deleted = true;
          return http.Response('', 204);
        }
        return http.Response('Error', 400);
      });

      final dataSource = FastApiWarehouseRemoteDataSource(
        baseUrl: 'https://test.api.com',
        client: mockClient,
      );
      final repo = WarehouseRepositoryImpl(remoteDataSource: dataSource);

      await repo.deleteWarehouseSlot(accessToken: 'token', slotId: 'slot-1');
      expect(deleted, isTrue);
    });
  });

  // =========================================================================
  // 3. CONTROLLER TESTS (State management, Search, Filters, Mutations, RBAC)
  // =========================================================================

  group('Milestone 5 Step 7 — Controller', () {
    late MockWarehouseRepository mockRepo;
    late WarehouseController controller;

    setUp(() {
      mockRepo = MockWarehouseRepository();
      mockRepo.warehouses = [
        const WarehouseItem(
          id: 'wh-1',
          name: 'Kurnool Storage Hub',
          address: 'Industrial Area, Kurnool',
          totalCapacityKg: 100000.0,
          currentLoadKg: 40000.0,
          location: 'Kurnool',
          isActive: true,
        ),
        const WarehouseItem(
          id: 'wh-2',
          name: 'Nandyal Depot',
          address: 'Market Yard, Nandyal',
          totalCapacityKg: 50000.0,
          currentLoadKg: 45000.0,
          location: 'Nandyal',
          isActive: true,
        ),
        const WarehouseItem(
          id: 'wh-3',
          name: 'Adoni Inactive Storage',
          address: 'Gooty Road, Adoni',
          totalCapacityKg: 20000.0,
          currentLoadKg: 0.0,
          location: 'Adoni',
          isActive: false,
        ),
      ];

      controller = WarehouseController(
        repository: mockRepo,
        accessToken: 'mock-token',
      );
    });

    test('loads warehouses successfully', () async {
      expect(controller.isLoading, isFalse);
      final future = controller.loadWarehouses();
      expect(controller.isLoading, isTrue);
      await future;

      expect(controller.isLoading, isFalse);
      expect(controller.warehouses.length, 3);
      expect(controller.filteredWarehouses.length, 3);
      expect(controller.errorMessage, isNull);
    });

    test('filters warehouses by search query', () async {
      await controller.loadWarehouses();

      controller.setSearchQuery('Nandyal');
      expect(controller.filteredWarehouses.length, 1);
      expect(controller.filteredWarehouses.first.name, 'Nandyal Depot');

      controller.setSearchQuery('Industrial');
      expect(controller.filteredWarehouses.length, 1);
      expect(controller.filteredWarehouses.first.name, 'Kurnool Storage Hub');

      controller.setSearchQuery('NonExistent');
      expect(controller.filteredWarehouses, isEmpty);

      controller.clearSearch();
      expect(controller.filteredWarehouses.length, 3);
    });

    test('filters warehouses by status filter', () async {
      await controller.loadWarehouses();

      controller.setFilter('active');
      expect(controller.filteredWarehouses.length, 2);

      controller.setFilter('near_full');
      // wh-2 is at 90% load (45,000 / 50,000 kg), which matches near_full (>80%)
      expect(controller.filteredWarehouses.length, 1);

      controller.setFilter('all');
      expect(controller.filteredWarehouses.length, 3);
    });

    test('selectWarehouse loads detail, inventory, and slots', () async {
      await controller.loadWarehouses();

      mockRepo.inventoryMap['wh-1'] = [
        const WarehouseInventoryItem(
          id: 'inv-1',
          warehouseId: 'wh-1',
          grainType: 'Paddy',
          quantityKg: 20000.0,
        ),
      ];
      mockRepo.slotsMap['wh-1'] = [
        const WarehouseSlotItem(
          id: 'slot-1',
          warehouseId: 'wh-1',
          slotDate: '2026-10-01',
          startTime: '09:00',
          endTime: '12:00',
          capacityKg: 5000.0,
          bookedKg: 1000.0,
          status: 'active',
        ),
      ];

      await controller.selectWarehouse(controller.warehouses.first);

      expect(controller.selectedWarehouse, isNotNull);
      expect(controller.selectedWarehouse!.id, 'wh-1');
      expect(controller.selectedInventory.length, 1);
      expect(controller.selectedSlots.length, 1);
    });

    test('createWarehouse adds warehouse and reloads list', () async {
      await controller.loadWarehouses();
      expect(controller.warehouses.length, 3);

      final success = await controller.createWarehouse(
        name: 'Dhone Warehouse',
        address: 'Station Road, Dhone',
        totalCapacityKg: 30000.0, // 300 Qtl = 30,000 Kg
        location: 'Dhone',
      );

      expect(success, isTrue);
      expect(controller.warehouses.length, 4);
      final created = controller.warehouses.firstWhere((w) => w.name == 'Dhone Warehouse');
      expect(created.totalCapacityKg, 30000.0);
    });

    test('updateWarehouse modifies warehouse', () async {
      await controller.loadWarehouses();

      final success = await controller.updateWarehouse(
        warehouseId: 'wh-1',
        name: 'Kurnool Mega Storage',
      );

      expect(success, isTrue);
      final updated = controller.warehouses.firstWhere((w) => w.id == 'wh-1');
      expect(updated.name, 'Kurnool Mega Storage');
    });

    test('deleteWarehouse removes warehouse', () async {
      await controller.loadWarehouses();
      expect(controller.warehouses.length, 3);

      final success = await controller.deleteWarehouse('wh-3');
      expect(success, isTrue);
      expect(controller.warehouses.length, 2);
      expect(controller.warehouses.any((w) => w.id == 'wh-3'), isFalse);
    });

    test('addInventory adds stock in Qtl and updates warehouse current load', () async {
      await controller.loadWarehouses();
      await controller.selectWarehouse(controller.warehouses.first);
      expect(controller.selectedWarehouse!.currentLoadKg, 40000.0);

      final success = await controller.addInventory(
        warehouseId: 'wh-1',
        grainType: 'Wheat',
        quantityKg: 5000.0, // 50 Qtl = 5,000 Kg
      );

      expect(success, isTrue);
      expect(controller.selectedInventory.any((i) => i.grainType == 'Wheat'), isTrue);
      expect(controller.selectedWarehouse!.currentLoadKg, 45000.0);
    });

    test('createSlot creates a slot with converted capacity', () async {
      await controller.loadWarehouses();
      await controller.selectWarehouse(controller.warehouses.first);

      final success = await controller.createSlot(
        warehouseId: 'wh-1',
        slotDate: '2026-10-05',
        startTime: '10:00',
        endTime: '13:00',
        capacityKg: 10000.0, // 100 Qtl = 10,000 Kg
      );

      expect(success, isTrue);
      expect(controller.selectedSlots.length, 1);
      expect(controller.selectedSlots.first.capacityKg, 10000.0);
    });

    test('cancelSlot updates slot status to cancelled', () async {
      await controller.loadWarehouses();
      mockRepo.slotsMap['wh-1'] = [
        const WarehouseSlotItem(
          id: 'slot-10',
          warehouseId: 'wh-1',
          slotDate: '2026-10-05',
          startTime: '10:00',
          endTime: '13:00',
          capacityKg: 10000.0,
          bookedKg: 0.0,
          status: 'active',
        ),
      ];
      await controller.selectWarehouse(controller.warehouses.first);

      final success = await controller.cancelSlot('slot-10');

      expect(success, isTrue);
      expect(controller.selectedSlots.first.status, 'cancelled');
      expect(controller.selectedSlots.first.isCancelled, isTrue);
    });

    test('deleteSlot removes slot from list', () async {
      await controller.loadWarehouses();
      mockRepo.slotsMap['wh-1'] = [
        const WarehouseSlotItem(
          id: 'slot-10',
          warehouseId: 'wh-1',
          slotDate: '2026-10-05',
          startTime: '10:00',
          endTime: '13:00',
          capacityKg: 10000.0,
          bookedKg: 0.0,
          status: 'active',
        ),
      ];
      await controller.selectWarehouse(controller.warehouses.first);
      expect(controller.selectedSlots.length, 1);

      final success = await controller.deleteSlot('slot-10');

      expect(success, isTrue);
      expect(controller.selectedSlots, isEmpty);
    });

    test('handles 403 Forbidden gracefully without corrupting state', () async {
      await controller.loadWarehouses();
      mockRepo.shouldThrow = true;
      mockRepo.exceptionToThrow = const WarehouseForbiddenException(message: 'You do not have permission to delete this warehouse.');

      final success = await controller.deleteWarehouse('wh-1');

      expect(success, isFalse);
      expect(controller.errorMessage, 'You do not have permission to delete this warehouse.');
      expect(controller.warehouses.length, 3); // Unchanged state
    });
  });

  // =========================================================================
  // 4. WIDGET & UI TESTS
  // =========================================================================

  group('Milestone 5 Step 7 — Widget Tests', () {
    late MockWarehouseRepository mockRepo;
    late WarehouseController controller;

    setUp(() {
      mockRepo = MockWarehouseRepository();
      mockRepo.warehouses = [
        const WarehouseItem(
          id: 'wh-1',
          name: 'Kurnool Storage Hub',
          address: 'Industrial Area, Kurnool',
          totalCapacityKg: 100000.0,
          currentLoadKg: 40000.0, // 40% (Green)
          location: 'Kurnool',
          isActive: true,
        ),
        const WarehouseItem(
          id: 'wh-2',
          name: 'Nandyal Depot',
          address: 'Market Yard, Nandyal',
          totalCapacityKg: 100000.0,
          currentLoadKg: 70000.0, // 70% (Amber)
          location: 'Nandyal',
          isActive: true,
        ),
        const WarehouseItem(
          id: 'wh-3',
          name: 'Adoni Terminal',
          address: 'Cotton Market, Adoni',
          totalCapacityKg: 100000.0,
          currentLoadKg: 90000.0, // 90% (Red)
          location: 'Adoni',
          isActive: true,
        ),
        const WarehouseItem(
          id: 'wh-4',
          name: 'Overloaded Hub',
          address: 'Highway, Dhone',
          totalCapacityKg: 100000.0,
          currentLoadKg: 105000.0, // 105% (Over-capacity)
          location: 'Dhone',
          isActive: true,
        ),
      ];

      controller = WarehouseController(
        repository: mockRepo,
        accessToken: 'token',
      );
    });

    testWidgets('WarehouseCard renders name, location, occupancy, and status pill', (tester) async {
      const item = WarehouseItem(
        id: 'wh-1',
        name: 'Kurnool Storage Hub',
        address: 'Industrial Area, Kurnool',
        totalCapacityKg: 100000.0,
        currentLoadKg: 40000.0,
        location: 'Kurnool',
        isActive: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WarehouseCard(
              warehouse: item,
              isAdmin: true,
              onTap: () {},
              onEdit: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      expect(find.text('Kurnool Storage Hub'), findsOneWidget);
      expect(find.text('Kurnool • Industrial Area, Kurnool'), findsOneWidget);
      expect(find.text('40.0%'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
    });

    testWidgets('WarehouseCard hides Admin mutation menu for Manager', (tester) async {
      const item = WarehouseItem(
        id: 'wh-1',
        name: 'Kurnool Storage Hub',
        address: 'Industrial Area, Kurnool',
        totalCapacityKg: 100000.0,
        currentLoadKg: 40000.0,
        isActive: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WarehouseCard(
              warehouse: item,
              isAdmin: false, // Manager role
              onTap: () {},
            ),
          ),
        ),
      );

      // PopupMenuButton should not be present for Manager
      expect(find.byType(PopupMenuButton<String>), findsNothing);
    });

    testWidgets('WarehouseScreen renders list, search bar, and summary strip', (tester) async {
      await controller.loadWarehouses();

      await tester.pumpWidget(
        MaterialApp(
          home: WarehouseScreen(
            controller: controller,
            isAdmin: true,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Warehouses'), findsOneWidget);
      expect(find.text('Kurnool Storage Hub'), findsOneWidget);
      expect(find.text('Nandyal Depot'), findsOneWidget);
      expect(find.text('Adoni Terminal'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget); // Admin has FAB
    });

    testWidgets('WarehouseScreen hides FAB for Manager', (tester) async {
      await controller.loadWarehouses();

      await tester.pumpWidget(
        MaterialApp(
          home: WarehouseScreen(
            controller: controller,
            isAdmin: false, // Manager role
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('AddEditWarehouseSheet validates required fields', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddEditWarehouseSheet(
              onSave: ({
                required name,
                required address,
                required totalCapacityKg,
                location,
                contactNumber,
                managerId,
                isActive,
              }) async => true,
            ),
          ),
        ),
      );

      // Tap save without filling fields
      await tester.ensureVisible(find.text('Create Warehouse'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create Warehouse'));
      await tester.pump();

      expect(find.text('Warehouse name must be at least 2 characters.'), findsOneWidget);
      expect(find.text('Address must be at least 4 characters.'), findsOneWidget);
      expect(find.text('Enter a valid positive capacity in Quintals.'), findsOneWidget);
    });

    testWidgets('AddInventorySheet validates grain type and quantity', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddInventorySheet(
              warehouseId: 'wh-1',
              warehouseName: 'Kurnool Depot',
              onAdd: ({
                required warehouseId,
                required grainType,
                required quantityKg,
              }) async => true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Add Inventory'));
      await tester.pump();

      expect(find.text('Enter a valid positive quantity in Quintals.'), findsOneWidget);
    });

    testWidgets('CreateSlotSheet validates date and time inputs', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CreateSlotSheet(
              warehouseId: 'wh-1',
              warehouseName: 'Kurnool Depot',
              onCreate: ({
                required warehouseId,
                required slotDate,
                required startTime,
                required endTime,
                required capacityKg,
              }) async => true,
            ),
          ),
        ),
      );

      expect(find.text('Open Booking Window'), findsOneWidget);
      expect(find.text('Create Slot'), findsOneWidget);
    });

    testWidgets('WarehouseDetailSheet displays warehouse metrics and tabs', (tester) async {
      await controller.loadWarehouses();
      await controller.selectWarehouse(controller.warehouses.first);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WarehouseDetailSheet(
              controller: controller,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Kurnool Storage Hub'), findsOneWidget);
      expect(find.text('Grain Stock'), findsOneWidget);
      expect(find.text('Booking Slots'), findsOneWidget);
    });

    testWidgets('WarehouseDetailSheet displays booked grain stock when stored inventory is empty', (tester) async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/v1/warehouses') {
          return http.Response(
            jsonEncode([
              {
                'id': 'wh-booked',
                'name': '134e5267890-',
                'address': 'bfehjebfdhjkn',
                'total_capacity_kg': 300.0,
                'current_load_kg': 300.0,
                'is_active': true,
              },
            ]),
            200,
          );
        }
        if (request.url.path == '/api/v1/warehouses/wh-booked/inventory') {
          return http.Response(jsonEncode([]), 200);
        }
        if (request.url.path == '/api/v1/warehouses/wh-booked/slots') {
          return http.Response(jsonEncode([]), 200);
        }
        if (request.url.path == '/api/v1/bookings') {
          return http.Response(
            jsonEncode({
              'data': [
                {
                  'id': 'bk-1',
                  'warehouse_id': 'wh-booked',
                  'grain_type': 'Groundnut (Pods)',
                  'quantity_kg': 300.0,
                  'status': 'confirmed',
                },
                {
                  'id': 'bk-2',
                  'warehouse_id': 'wh-booked',
                  'grain_type': 'Paddy',
                  'quantity_kg': 50.0,
                  'status': 'cancelled',
                },
              ],
              'pagination': {'page': 1, 'page_size': 100, 'total': 2, 'total_pages': 1},
            }),
            200,
          );
        }
        return http.Response('Not found', 404);
      });

      final repo = WarehouseRepositoryImpl(
        remoteDataSource: FastApiWarehouseRemoteDataSource(
          baseUrl: 'https://test.api.com',
          client: mockClient,
        ),
      );
      final bookedController = WarehouseController(
        repository: repo,
        accessToken: 'token',
      );
      await bookedController.loadWarehouses();
      await bookedController.selectWarehouse(bookedController.warehouses.first);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WarehouseDetailSheet(
              controller: bookedController,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Stored Commodities (1)'), findsOneWidget);
      expect(find.text('Groundnut (Pods)'), findsOneWidget);
      expect(find.textContaining('Booked Intake'), findsOneWidget);
      expect(find.text('3.0 Qtl'), findsWidgets);
      expect(find.text('Paddy'), findsNothing);
      bookedController.dispose();
    });

    testWidgets('AddInventorySheet shows inline capacity error and backend errorMessage without closing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddInventorySheet(
              warehouseId: 'wh-1',
              warehouseName: 'john',
              availableCapacityKg: 334.0,
              errorMessage: () => 'Warehouse quota exceeded',
              onAdd: ({
                required warehouseId,
                required grainType,
                required quantityKg,
              }) async => false,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField).last, '50');
      await tester.tap(find.text('Add Inventory'));
      await tester.pump();
      expect(
        find.text('Exceeds available warehouse space (3.3 Qtl available).'),
        findsOneWidget,
      );

      await tester.enterText(find.byType(TextField).last, '2');
      await tester.tap(find.text('Add Inventory'));
      await tester.pumpAndSettle();
      expect(find.text('Warehouse quota exceeded'), findsOneWidget);
    });

    testWidgets('CreateSlotSheet validates time window and surfaces backend errorMessage', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CreateSlotSheet(
              warehouseId: 'wh-1',
              warehouseName: 'john',
              errorMessage: () => 'Token expired on server',
              onCreate: ({
                required warehouseId,
                required slotDate,
                required startTime,
                required endTime,
                required capacityKg,
              }) async => false,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Create Slot'));
      await tester.pumpAndSettle();
      expect(find.text('Token expired on server'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('AddEditWarehouseSheet editing mode has Material ancestor and renders server error inline', (tester) async {
      const existing = WarehouseItem(
        id: 'wh-1',
        name: 'QA Warehouses 2026-09-29',
        address: 'QA Automation Address',
        totalCapacityKg: 2000.0,
        currentLoadKg: 500.0,
        location: 'QA Test Lab',
        contactNumber: '+91 9000000001',
        isActive: true,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddEditWarehouseSheet(
              warehouse: existing,
              errorMessage: () => 'Cannot update facility capacity',
              onSave: ({
                required name,
                required address,
                required totalCapacityKg,
                location,
                contactNumber,
                managerId,
                isActive,
              }) async => false,
            ),
          ),
        ),
      );

      await tester.ensureVisible(find.text('Save Changes'));
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(find.text('Cannot update facility capacity'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('WarehouseScreen renders single-line fitted filter chips without clipping', (tester) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await controller.loadWarehouses();
      await tester.pumpWidget(
        MaterialApp(
          home: WarehouseScreen(
            controller: controller,
            isAdmin: true,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('All Locations (4)'), findsOneWidget);
      expect(find.text('Active (4)'), findsOneWidget);
      expect(find.text('Inactive (0)'), findsOneWidget);
      expect(find.text('Near/Over Full (2)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('WarehouseScreen Inactive filter chip filters inactive warehouses and supports reactivation', (tester) async {
      mockRepo.warehouses = [
        ...mockRepo.warehouses,
        const WarehouseItem(
          id: 'wh-inactive-1',
          name: 'abhi testings',
          address: 'kurnool main road',
          totalCapacityKg: 300.0,
          currentLoadKg: 0.0,
          location: 'kurnool',
          isActive: false,
        ),
      ];
      await controller.loadWarehouses();
      expect(controller.inactiveWarehousesCount, 1);

      await tester.pumpWidget(
        MaterialApp(
          home: WarehouseScreen(
            controller: controller,
            isAdmin: true,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Inactive (1)'), findsOneWidget);
      await tester.tap(find.text('Inactive (1)'));
      await tester.pump();

      expect(find.text('abhi testings'), findsOneWidget);
      expect(find.text('Kurnool Storage Hub'), findsNothing);

      final reactivated = await controller.updateWarehouse(
        warehouseId: 'wh-inactive-1',
        isActive: true,
      );
      expect(reactivated, isTrue);
      expect(controller.inactiveWarehousesCount, 0);
    });
  });

  // =========================================================================
  // 5. RESPONSIVE TESTS (Zero RenderFlex Overflow)
  // =========================================================================

  group('Milestone 5 Step 7 — Responsive Tests (0 RenderFlex Overflows)', () {
    late MockWarehouseRepository mockRepo;
    late WarehouseController controller;

    setUp(() {
      mockRepo = MockWarehouseRepository();
      mockRepo.warehouses = [
        const WarehouseItem(
          id: 'wh-1',
          name: 'Kurnool Regional Storage and Grain Terminal',
          address: 'Plot 42-A, Industrial Growth Center, NH-44 Highway, Kurnool District, Andhra Pradesh',
          totalCapacityKg: 100000.0,
          currentLoadKg: 65000.0,
          location: 'Kurnool Industrial Corridor',
          contactNumber: '+91 9876543210',
          isActive: true,
        ),
        const WarehouseItem(
          id: 'wh-2',
          name: 'Nandyal Central Cold and Dry Storage',
          address: 'Near Agricultural Market Yard, Railway Feed Road, Nandyal',
          totalCapacityKg: 80000.0,
          currentLoadKg: 78000.0,
          location: 'Nandyal Market Yard',
          contactNumber: '+91 9876543211',
          isActive: true,
        ),
      ];

      controller = WarehouseController(
        repository: mockRepo,
        accessToken: 'token',
      );
    });

    void testOnResolution(Size size, String label) {
      testWidgets('Renders without overflow on $label (${size.width.toInt()}x${size.height.toInt()})', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await controller.loadWarehouses();

        await tester.pumpWidget(
          MaterialApp(
            home: WarehouseScreen(
              controller: controller,
              isAdmin: true,
              onBack: () {},
            ),
          ),
        );
        await tester.pump();

        // Verify key widgets are present
        expect(find.text('Warehouses'), findsOneWidget);
        expect(find.byType(CustomScrollView), findsOneWidget);
        expect(tester.takeException(), isNull); // ZERO RenderFlex overflow
      });
    }

    testOnResolution(const Size(320, 568), 'Compact iPhone SE / Small Android');
    testOnResolution(const Size(360, 640), 'Standard Android');
    testOnResolution(const Size(412, 860), 'Modern Android');
    testOnResolution(const Size(412, 960), 'Large Android Flagship');
  });
}
