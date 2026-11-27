import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:agriflow_admin/core/network/error_sanitizer.dart';
import 'package:agriflow_admin/features/seeds_inventory/domain/entities/seed_inventory_item.dart';
import 'package:agriflow_admin/features/seeds_inventory/domain/entities/seed_warehouse_brief.dart';
import 'package:agriflow_admin/features/seeds_inventory/domain/exceptions/seeds_inventory_exception.dart';
import 'package:agriflow_admin/features/seeds_inventory/domain/repositories/seeds_inventory_repository.dart';
import 'package:agriflow_admin/features/seeds_inventory/data/datasources/fast_api_seeds_inventory_remote_data_source.dart';
import 'package:agriflow_admin/features/seeds_inventory/data/repositories/seeds_inventory_repository_impl.dart';
import 'package:agriflow_admin/features/seeds_inventory/presentation/controllers/seeds_inventory_controller.dart';
import 'package:agriflow_admin/features/seeds_inventory/presentation/screens/seeds_inventory_screen.dart';
import 'package:agriflow_admin/features/seeds_inventory/presentation/widgets/seed_inventory_card.dart';
import 'package:agriflow_admin/features/seeds_inventory/presentation/widgets/add_edit_seed_sheet.dart';
import 'package:agriflow_admin/features/seeds_inventory/presentation/widgets/seed_image_picker.dart';

// =========================================================================
// MOCK REPOSITORY IMPLEMENTATION FOR TESTS
// =========================================================================

class MockSeedsInventoryRepository implements SeedsInventoryRepository {
  List<SeedInventoryItem> seeds = [];
  List<SeedWarehouseBrief> warehouses = [
    const SeedWarehouseBrief(
      id: 'wh-1',
      name: 'Kurnool Storage Facility',
      address: 'Industrial Estate, Kurnool',
      location: 'Kurnool',
    ),
    const SeedWarehouseBrief(
      id: 'wh-2',
      name: 'Nandyal Cold Storage',
      address: 'Market Yard, Nandyal',
      location: 'Nandyal',
    ),
    const SeedWarehouseBrief(
      id: 'wh-3',
      name: 'Dhone Regional Depot',
      address: 'Railway Station Road, Dhone',
      location: 'Dhone',
    ),
    const SeedWarehouseBrief(
      id: 'wh-4',
      name: 'Yemmiganur Warehouse',
      address: 'Adoni Road, Yemmiganur',
      location: 'Yemmiganur',
    ),
  ];

  bool shouldThrow = false;
  SeedsInventoryException? exceptionToThrow;

  @override
  Future<List<SeedInventoryItem>> getSeeds({required String accessToken}) async {
    if (shouldThrow) {
      throw exceptionToThrow ?? const SeedsInventoryServerException();
    }
    return List.from(seeds);
  }

  @override
  Future<SeedInventoryItem> getSeed({
    required String accessToken,
    required String seedId,
  }) async {
    if (shouldThrow) {
      throw exceptionToThrow ?? const SeedsInventoryServerException();
    }
    final index = seeds.indexWhere((s) => s.id == seedId);
    if (index == -1) {
      throw const SeedsInventoryNotFoundException();
    }
    return seeds[index];
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
  }) async {
    if (shouldThrow) {
      throw exceptionToThrow ?? const SeedsInventoryServerException();
    }
    final assignedWarehouses = warehouses
        .where((w) => (warehouseIds ?? []).contains(w.id))
        .toList();

    final item = SeedInventoryItem(
      id: 'mock-seed-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      cropType: cropType,
      variety: variety,
      pricePerKg: pricePerKg,
      priceGradeA: priceGradeA,
      priceGradeB: priceGradeB,
      priceGradeC: priceGradeC,
      maxOrderQuantityKg: maxOrderQuantityKg,
      stockKg: stockKg,
      warehouseIds: warehouseIds ?? [],
      warehouses: assignedWarehouses,
      description: description,
      imageUrl: imageUrl,
      isActive: true,
    );
    seeds.insert(0, item);
    return item;
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
  }) async {
    if (shouldThrow) {
      throw exceptionToThrow ?? const SeedsInventoryServerException();
    }
    final index = seeds.indexWhere((s) => s.id == seedId);
    if (index == -1) {
      throw const SeedsInventoryNotFoundException();
    }
    final existing = seeds[index];
    final updatedWarehouses = warehouseIds != null
        ? warehouses.where((w) => warehouseIds.contains(w.id)).toList()
        : existing.warehouses;

    final updated = existing.copyWith(
      name: name ?? existing.name,
      cropType: cropType ?? existing.cropType,
      variety: variety ?? existing.variety,
      pricePerKg: pricePerKg ?? existing.pricePerKg,
      priceGradeA: priceGradeA ?? existing.priceGradeA,
      priceGradeB: priceGradeB ?? existing.priceGradeB,
      priceGradeC: priceGradeC ?? existing.priceGradeC,
      maxOrderQuantityKg: maxOrderQuantityKg ?? existing.maxOrderQuantityKg,
      stockKg: stockKg ?? existing.stockKg,
      warehouseIds: warehouseIds ?? existing.warehouseIds,
      warehouses: updatedWarehouses,
      description: description ?? existing.description,
      imageUrl: imageUrl ?? existing.imageUrl,
      isActive: isActive ?? existing.isActive,
    );
    seeds[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteSeed({
    required String accessToken,
    required String seedId,
  }) async {
    if (shouldThrow) {
      throw exceptionToThrow ?? const SeedsInventoryServerException();
    }
    final index = seeds.indexWhere((s) => s.id == seedId);
    if (index != -1) {
      seeds[index] = seeds[index].copyWith(isActive: false);
    }
  }

  @override
  Future<List<SeedWarehouseBrief>> getWarehouses({required String accessToken}) async {
    if (shouldThrow) {
      throw exceptionToThrow ?? const SeedsInventoryServerException();
    }
    return List.from(warehouses);
  }

  @override
  Future<List<SeedWarehouseBrief>> getSeedWarehouses({
    required String accessToken,
    required String seedId,
  }) async {
    if (shouldThrow) {
      throw exceptionToThrow ?? const SeedsInventoryServerException();
    }
    final seed = seeds.firstWhere((s) => s.id == seedId, orElse: () => seeds.first);
    return seed.warehouses;
  }

  @override
  Future<List<SeedWarehouseBrief>> assignSeedWarehouses({
    required String accessToken,
    required String seedId,
    required List<String> warehouseIds,
  }) async {
    if (shouldThrow) {
      throw exceptionToThrow ?? const SeedsInventoryServerException();
    }
    final assigned = warehouses.where((w) => warehouseIds.contains(w.id)).toList();
    final index = seeds.indexWhere((s) => s.id == seedId);
    if (index != -1) {
      seeds[index] = seeds[index].copyWith(
        warehouseIds: warehouseIds,
        warehouses: assigned,
      );
    }
    return assigned;
  }

  @override
  Future<void> removeSeedWarehouse({
    required String accessToken,
    required String seedId,
    required String warehouseId,
  }) async {
    if (shouldThrow) {
      throw exceptionToThrow ?? const SeedsInventoryServerException();
    }
    final index = seeds.indexWhere((s) => s.id == seedId);
    if (index != -1) {
      final updatedIds = seeds[index].warehouseIds.where((id) => id != warehouseId).toList();
      final updatedWarehouses = seeds[index].warehouses.where((w) => w.id != warehouseId).toList();
      seeds[index] = seeds[index].copyWith(
        warehouseIds: updatedIds,
        warehouses: updatedWarehouses,
      );
    }
  }

  @override
  Future<String> uploadSeedImage({
    required String accessToken,
    required List<int> fileBytes,
    required String fileName,
    String contentType = 'image/jpeg',
  }) async {
    if (shouldThrow) {
      throw exceptionToThrow ?? const SeedsInventoryServerException(message: 'Upload failed');
    }
    return 'https://ajtlgnfezvbpvtildrok.supabase.co/storage/v1/object/public/uploads/seeds/$fileName';
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // =========================================================================
  // 1. DOMAIN LAYER TESTS (Model, Grade Prices, Max Order, Warehouses)
  // =========================================================================

  group('Milestone 5 Step 6 — Domain Entity (SeedInventoryItem)', () {
    test('parses from standard FastAPI SeedPublic JSON correctly', () {
      final json = {
        'id': '3fa85f64-5717-4562-b3fc-2c963f66afa6',
        'name': 'BPT-5204 (Samba Mahsuri)',
        'crop_type': 'Paddy',
        'variety': 'Fine Grain',
        'price_per_kg': '65.50',
        'price_grade_a': '75.00',
        'price_grade_b': '70.00',
        'price_grade_c': '65.00',
        'max_order_quantity_kg': '50.00',
        'stock_kg': '12500.00',
        'warehouse_id': 'wh-1',
        'warehouse_ids': ['wh-1', 'wh-2'],
        'warehouses': [
          {'id': 'wh-1', 'name': 'Kurnool Storage Facility'},
          {'id': 'wh-2', 'name': 'Nandyal Cold Storage'},
        ],
        'description': 'High yield variety',
        'image_url': 'https://example.com/seed.jpg',
        'is_active': true,
      };

      final item = SeedInventoryItem.fromJson(json);

      expect(item.id, '3fa85f64-5717-4562-b3fc-2c963f66afa6');
      expect(item.name, 'BPT-5204 (Samba Mahsuri)');
      expect(item.cropType, 'Paddy');
      expect(item.variety, 'Fine Grain');
      expect(item.pricePerKg, 65.50);
      expect(item.priceGradeA, 75.00);
      expect(item.priceGradeB, 70.00);
      expect(item.priceGradeC, 65.00);
      expect(item.maxOrderQuantityKg, 50.00);
      expect(item.stockKg, 12500.00);
      expect(item.warehouseId, 'wh-1');
      expect(item.warehouseIds, ['wh-1', 'wh-2']);
      expect(item.warehouses.length, 2);
      expect(item.assignedWarehouseNames, ['Kurnool Storage Facility', 'Nandyal Cold Storage']);
      expect(item.description, 'High yield variety');
      expect(item.imageUrl, 'https://example.com/seed.jpg');
      expect(item.isActive, isTrue);
    });

    test('handles numeric types and null variety/description safely', () {
      final json = {
        'id': 'seed-123',
        'name': 'Cotton Prime',
        'crop_type': null,
        'variety': null,
        'price_per_kg': 120,
        'price_grade_a': null,
        'price_grade_b': null,
        'price_grade_c': null,
        'max_order_quantity_kg': null,
        'stock_kg': 450,
        'warehouse_id': null,
        'warehouse_ids': null,
        'warehouses': null,
        'description': null,
        'image_url': null,
        'is_active': false,
      };

      final item = SeedInventoryItem.fromJson(json);

      expect(item.variety, isNull);
      expect(item.description, isNull);
      expect(item.imageUrl, isNull);
      expect(item.priceGradeA, isNull);
      expect(item.maxOrderQuantityKg, isNull);
      expect(item.warehouseIds, isEmpty);
      expect(item.warehouses, isEmpty);
      expect(item.pricePerKg, 120.0);
      expect(item.stockKg, 450.0);
      expect(item.isActive, isFalse);
    });

    test('calculates Quintal conversion accurately (1 Qtl = 100 Kg)', () {
      const item = SeedInventoryItem(
        id: 'seed-1',
        name: 'Wheat',
        pricePerKg: 30.0,
        stockKg: 1550.0,
      );

      // 1550 Kg / 100 = 15.5 Qtl
      expect(item.stockQtl, 15.5);
      expect(item.displayStockQtl, '15.50');
      expect(item.displayStockKg, '1550');
    });

    test('accurately triggers low stock threshold (< 500 Kg / < 5 Qtl)', () {
      const lowStockItem = SeedInventoryItem(
        id: 'seed-low-1',
        name: 'Maize',
        pricePerKg: 40.0,
        stockKg: 499.0, // < 500 kg
      );
      const normalStockItem = SeedInventoryItem(
        id: 'seed-normal',
        name: 'Maize',
        pricePerKg: 40.0,
        stockKg: 500.0, // boundary
      );

      expect(lowStockItem.isLowStock, isTrue);
      expect(normalStockItem.isLowStock, isFalse);
    });

    test('serializes to JSON correctly with grade prices and warehouses', () {
      const item = SeedInventoryItem(
        id: 'seed-1',
        name: 'Soybean',
        variety: 'JS-335',
        pricePerKg: 75.0,
        priceGradeA: 85.0,
        priceGradeB: 80.0,
        priceGradeC: 75.0,
        maxOrderQuantityKg: 50.0,
        stockKg: 2500.0,
        warehouseIds: ['wh-1'],
        warehouses: [SeedWarehouseBrief(id: 'wh-1', name: 'Kurnool Storage Facility')],
        description: 'Quality tested',
        isActive: true,
      );

      final json = item.toJson();

      expect(json['id'], 'seed-1');
      expect(json['name'], 'Soybean');
      expect(json['variety'], 'JS-335');
      expect(json['price_per_kg'], '75.00');
      expect(json['price_grade_a'], '85.00');
      expect(json['price_grade_b'], '80.00');
      expect(json['price_grade_c'], '75.00');
      expect(json['max_order_quantity_kg'], '50.00');
      expect(json['stock_kg'], '2500.00');
      expect(json['warehouse_ids'], ['wh-1']);
      expect(json['warehouses'].length, 1);
      expect(json['is_active'], isTrue);
    });

    test('supports copyWith and value equality', () {
      const item1 = SeedInventoryItem(
        id: 'seed-1',
        name: 'Gram',
        pricePerKg: 50.0,
        stockKg: 1000.0,
      );
      final item2 = item1.copyWith(pricePerKg: 55.0, maxOrderQuantityKg: 50.0);

      expect(item1 == item2, isFalse);
      expect(item2.pricePerKg, 55.0);
      expect(item2.maxOrderQuantityKg, 50.0);
      expect(item1 == item1.copyWith(), isTrue);
    });
  });

  group('Milestone 5 Step 6 — Domain Exceptions', () {
    test('exception types map correct HTTP status codes', () {
      expect(const SeedsInventoryUnauthorizedException().statusCode, 401);
      expect(const SeedsInventoryForbiddenException().statusCode, 403);
      expect(const SeedsInventoryNotFoundException().statusCode, 404);
      expect(const SeedsInventoryValidationException(message: 'err').statusCode, 422);
      expect(const SeedsInventoryServerException().statusCode, 500);
      expect(const SeedsInventoryNetworkException().isNetworkError, isTrue);
    });
  });

  // =========================================================================
  // 2. DATA SOURCE & REPOSITORY TESTS (CRUD, Warehouses, Upload)
  // =========================================================================

  group('Milestone 5 Step 6 — Data Source & Repository', () {
    test('getSeeds parses list successfully on 200 OK', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/api/v1/seeds');
        expect(request.headers['Authorization'], 'Bearer valid-token');
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Success',
            'data': [
              {
                'id': 'seed-1',
                'name': 'Paddy RNR',
                'variety': 'Telangana Sona',
                'price_per_kg': '60.00',
                'stock_kg': '5000.00',
                'description': 'Fine grain',
                'image_url': null,
                'is_active': true,
              }
            ]
          }),
          200,
        );
      });

      final dataSource = FastApiSeedsInventoryRemoteDataSource(client: mockClient);
      final repo = SeedsInventoryRepositoryImpl(remoteDataSource: dataSource);

      final result = await repo.getSeeds(accessToken: 'valid-token');
      expect(result.length, 1);
      expect(result.first.name, 'Paddy RNR');
      expect(result.first.stockQtl, 50.0);
    });

    test('createSeed sends SeedCreate payload and parses 201 Created', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/v1/seeds');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['name'], 'Cotton H4');
        expect(body['price_per_kg'], 150.0);
        expect(body['stock_kg'], 2000.0);
        expect(body['price_grade_a'], 160.0);
        expect(body['warehouse_ids'], ['wh-1', 'wh-2']);

        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'id': 'new-seed-1',
              'name': 'Cotton H4',
              'variety': 'Hybrid',
              'price_per_kg': '150.00',
              'price_grade_a': '160.00',
              'stock_kg': '2000.00',
              'warehouse_ids': ['wh-1', 'wh-2'],
              'description': null,
              'image_url': null,
              'is_active': true,
            }
          }),
          201,
        );
      });

      final dataSource = FastApiSeedsInventoryRemoteDataSource(client: mockClient);
      final repo = SeedsInventoryRepositoryImpl(remoteDataSource: dataSource);

      final item = await repo.createSeed(
        accessToken: 'token',
        name: 'Cotton H4',
        pricePerKg: 150.0,
        stockKg: 2000.0,
        priceGradeA: 160.0,
        warehouseIds: ['wh-1', 'wh-2'],
        variety: 'Hybrid',
      );

      expect(item.id, 'new-seed-1');
      expect(item.name, 'Cotton H4');
      expect(item.pricePerKg, 150.0);
      expect(item.priceGradeA, 160.0);
      expect(item.warehouseIds, ['wh-1', 'wh-2']);
    });

    test('updateSeed sends SeedUpdate payload and parses 200 OK', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'PATCH');
        expect(request.url.path, '/api/v1/seeds/seed-123');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['price_per_kg'], 80.0);
        expect(body['max_order_quantity_kg'], 50.0);
        expect(body['is_active'], false);

        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'id': 'seed-123',
              'name': 'Mustard Varuna',
              'variety': 'Oilseed',
              'price_per_kg': '80.00',
              'max_order_quantity_kg': '50.00',
              'stock_kg': '3000.00',
              'description': 'Updated',
              'image_url': null,
              'is_active': false,
            }
          }),
          200,
        );
      });

      final dataSource = FastApiSeedsInventoryRemoteDataSource(client: mockClient);
      final repo = SeedsInventoryRepositoryImpl(remoteDataSource: dataSource);

      final item = await repo.updateSeed(
        accessToken: 'token',
        seedId: 'seed-123',
        pricePerKg: 80.0,
        maxOrderQuantityKg: 50.0,
        isActive: false,
      );

      expect(item.pricePerKg, 80.0);
      expect(item.maxOrderQuantityKg, 50.0);
      expect(item.isActive, isFalse);
    });

    test('getWarehouses parses list from /api/v1/warehouses', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/api/v1/warehouses');
        return http.Response(
          jsonEncode({
            'success': true,
            'data': [
              {'id': 'wh-1', 'name': 'Kurnool Storage Facility', 'location': 'Kurnool'},
              {'id': 'wh-2', 'name': 'Nandyal Cold Storage', 'location': 'Nandyal'},
            ]
          }),
          200,
        );
      });

      final dataSource = FastApiSeedsInventoryRemoteDataSource(client: mockClient);
      final repo = SeedsInventoryRepositoryImpl(remoteDataSource: dataSource);

      final list = await repo.getWarehouses(accessToken: 'token');
      expect(list.length, 2);
      expect(list[0].name, 'Kurnool Storage Facility');
      expect(list[1].name, 'Nandyal Cold Storage');
    });

    test('assignSeedWarehouses posts to /api/v1/seeds/{id}/warehouses', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/v1/seeds/seed-1/warehouses');
        final body = jsonDecode(request.body);
        expect(body['warehouse_ids'], ['wh-1', 'wh-2']);

        return http.Response(
          jsonEncode({
            'success': true,
            'data': [
              {'id': 'wh-1', 'name': 'Kurnool Storage Facility'},
              {'id': 'wh-2', 'name': 'Nandyal Cold Storage'},
            ]
          }),
          200,
        );
      });

      final dataSource = FastApiSeedsInventoryRemoteDataSource(client: mockClient);
      final repo = SeedsInventoryRepositoryImpl(remoteDataSource: dataSource);

      final result = await repo.assignSeedWarehouses(
        accessToken: 'token',
        seedId: 'seed-1',
        warehouseIds: ['wh-1', 'wh-2'],
      );
      expect(result.length, 2);
      expect(result.first.name, 'Kurnool Storage Facility');
    });

    test('uploadSeedImage posts multipart file to /api/v1/uploads', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/v1/uploads');
        expect(request.headers['Authorization'], 'Bearer token');

        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'public_url': 'https://supabase.co/storage/seeds/sample.jpg',
              'object_path': 'seeds/sample.jpg',
              'size_bytes': 1024,
              'content_type': 'image/jpeg',
            }
          }),
          201,
        );
      });

      final dataSource = FastApiSeedsInventoryRemoteDataSource(client: mockClient);
      final repo = SeedsInventoryRepositoryImpl(remoteDataSource: dataSource);

      final url = await repo.uploadSeedImage(
        accessToken: 'token',
        fileBytes: [1, 2, 3],
        fileName: 'sample.jpg',
      );
      expect(url, 'https://supabase.co/storage/seeds/sample.jpg');
    });

    test('deleteSeed handles 204 No Content', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'DELETE');
        expect(request.url.path, '/api/v1/seeds/seed-999');
        return http.Response('', 204);
      });

      final dataSource = FastApiSeedsInventoryRemoteDataSource(client: mockClient);
      final repo = SeedsInventoryRepositoryImpl(remoteDataSource: dataSource);

      await expectLater(
        repo.deleteSeed(accessToken: 'token', seedId: 'seed-999'),
        completes,
      );
    });

    test('maps 401, 403, 404, 422, 500 error responses correctly', () async {
      void checkError(int status, Type expectedType) async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({'detail': 'Simulated error message'}),
            status,
          );
        });
        final repo = SeedsInventoryRepositoryImpl(
          remoteDataSource: FastApiSeedsInventoryRemoteDataSource(client: mockClient),
        );
        expect(
          () => repo.getSeeds(accessToken: 'token'),
          throwsA(isA<SeedsInventoryException>().having((e) => e.runtimeType, 'type', expectedType)),
        );
      }

      checkError(401, SeedsInventoryUnauthorizedException);
      checkError(403, SeedsInventoryForbiddenException);
      checkError(404, SeedsInventoryNotFoundException);
      checkError(422, SeedsInventoryValidationException);
      checkError(500, SeedsInventoryServerException);
    });
  });

  // =========================================================================
  // 3. CONTROLLER TESTS (Search, Filter, Grade Pricing, Warehouses, RBAC)
  // =========================================================================

  group('Milestone 5 Step 6 — SeedsInventoryController', () {
    late MockSeedsInventoryRepository mockRepo;
    late SeedsInventoryController controller;

    setUp(() {
      mockRepo = MockSeedsInventoryRepository();
      mockRepo.seeds = [
        const SeedInventoryItem(
          id: 's-1',
          name: 'Paddy BPT',
          variety: 'Rice',
          pricePerKg: 65.0,
          priceGradeA: 75.0,
          maxOrderQuantityKg: 50.0,
          stockKg: 1000.0, // Normal stock (10 Qtl)
          warehouseIds: ['wh-1'],
          warehouses: [SeedWarehouseBrief(id: 'wh-1', name: 'Kurnool Storage Facility')],
          isActive: true,
        ),
        const SeedInventoryItem(
          id: 's-2',
          name: 'Cotton Bt',
          variety: 'Cash Crop',
          pricePerKg: 150.0,
          stockKg: 200.0, // Low stock (< 500 Kg)
          warehouseIds: ['wh-2'],
          warehouses: [SeedWarehouseBrief(id: 'wh-2', name: 'Nandyal Cold Storage')],
          isActive: true,
        ),
        const SeedInventoryItem(
          id: 's-3',
          name: 'Maize Pioneer',
          variety: 'Coarse Grain',
          pricePerKg: 45.0,
          stockKg: 800.0,
          isActive: false, // Inactive
        ),
      ];

      controller = SeedsInventoryController(
        repository: mockRepo,
        accessToken: 'test-token',
      );
    });

    test('initial state is clean and idle', () {
      expect(controller.allSeeds, isEmpty);
      expect(controller.isLoading, isFalse);
      expect(controller.errorMessage, isNull);
      expect(controller.searchQuery, isEmpty);
      expect(controller.currentFilter, 'all');
    });

    test('loadSeeds populates items, warehouses, and calculates metrics', () async {
      await controller.loadSeeds();

      expect(controller.isLoading, isFalse);
      expect(controller.allSeeds.length, 3);
      expect(controller.warehouses.length, 4);
      expect(controller.totalSeedsCount, 3);
      expect(controller.activeSeedsCount, 2);
      expect(controller.inactiveSeedsCount, 1);
      expect(controller.lowStockCount, 1);
      expect(controller.filteredSeeds.length, 3);
    });

    test('search query filters reactively by name, variety, and warehouse', () async {
      await controller.loadSeeds();

      // Search by name
      controller.setSearchQuery('cotton');
      expect(controller.filteredSeeds.length, 1);
      expect(controller.filteredSeeds.first.name, 'Cotton Bt');

      // Search by warehouse name
      controller.setSearchQuery('kurnool');
      expect(controller.filteredSeeds.length, 1);
      expect(controller.filteredSeeds.first.name, 'Paddy BPT');

      // Clear search
      controller.setSearchQuery('');
      expect(controller.filteredSeeds.length, 3);
    });

    test('filter tabs filter by active and low-stock states', () async {
      await controller.loadSeeds();

      controller.setFilter('active');
      expect(controller.filteredSeeds.length, 2);

      controller.setFilter('low_stock');
      expect(controller.filteredSeeds.length, 1);
      expect(controller.filteredSeeds.first.name, 'Cotton Bt');

      controller.setFilter('all');
      expect(controller.filteredSeeds.length, 3);

      controller.setFilter('inactive');
      expect(controller.filteredSeeds.length, 1);
      expect(controller.filteredSeeds.first.name, 'Maize Pioneer');
    });

    test('addSeed supports grade pricing and multi-warehouse assignment', () async {
      await controller.loadSeeds();

      final ok = await controller.addSeed(
        name: 'Wheat Sharbati',
        pricePerKg: 40.0,
        stockKg: 5000.0,
        variety: 'Wheat',
        priceGradeA: 48.0,
        priceGradeB: 44.0,
        maxOrderQuantityKg: 50.0,
        warehouseIds: ['wh-1', 'wh-4'],
      );

      expect(ok, isTrue);
      expect(controller.totalSeedsCount, 4);
      expect(controller.activeSeedsCount, 3);
      final newlyAdded = controller.allSeeds.first;
      expect(newlyAdded.name, 'Wheat Sharbati');
      expect(newlyAdded.priceGradeA, 48.0);
      expect(newlyAdded.maxOrderQuantityKg, 50.0);
      expect(newlyAdded.warehouseIds, ['wh-1', 'wh-4']);
      expect(controller.successMessage, contains('added successfully'));
    });

    test('updateSeed mutates seed in-place', () async {
      await controller.loadSeeds();

      final ok = await controller.updateSeed(
        seedId: 's-1',
        pricePerKg: 70.0,
        priceGradeA: 80.0,
        stockKg: 2000.0,
        warehouseIds: ['wh-1', 'wh-2', 'wh-3'],
      );

      expect(ok, isTrue);
      final updated = controller.allSeeds.firstWhere((s) => s.id == 's-1');
      expect(updated.pricePerKg, 70.0);
      expect(updated.priceGradeA, 80.0);
      expect(updated.stockKg, 2000.0);
      expect(updated.warehouseIds, ['wh-1', 'wh-2', 'wh-3']);
    });

    test('deleteSeed performs soft-delete, updates active count, and filters correctly', () async {
      await controller.loadSeeds();

      expect(controller.totalSeedsCount, 3);
      expect(controller.activeSeedsCount, 2);
      expect(controller.inactiveSeedsCount, 1);

      final ok = await controller.deleteSeed('s-2');

      expect(ok, isTrue);
      expect(controller.totalSeedsCount, 3);
      expect(controller.activeSeedsCount, 1);
      expect(controller.inactiveSeedsCount, 2);
      expect(controller.allSeeds.firstWhere((s) => s.id == 's-2').isActive, isFalse);

      // Verify 'all' tab still shows total seeds (active + inactive)
      controller.setFilter('all');
      expect(controller.filteredSeeds.length, 3);
      expect(controller.filteredSeeds.any((s) => s.id == 's-2'), isTrue);

      // Verify 'active' tab excludes soft-deleted seed
      controller.setFilter('active');
      expect(controller.filteredSeeds.length, 1);
      expect(controller.filteredSeeds.any((s) => s.id == 's-2'), isFalse);

      // Verify 'low_stock' tab excludes soft-deleted seed
      controller.setFilter('low_stock');
      expect(controller.filteredSeeds.length, 0);
      expect(controller.filteredSeeds.any((s) => s.id == 's-2'), isFalse);

      // Verify inactive tab includes soft-deleted seed
      controller.setFilter('inactive');
      expect(controller.filteredSeeds.length, 2);
      expect(controller.filteredSeeds.any((s) => s.id == 's-2'), isTrue);

      // Verify refresh preserves the soft-deleted state
      await controller.loadSeeds(refresh: true);
      expect(controller.totalSeedsCount, 3);
      expect(controller.activeSeedsCount, 1);
      expect(controller.inactiveSeedsCount, 2);
      expect(controller.allSeeds.firstWhere((s) => s.id == 's-2').isActive, isFalse);

      controller.setFilter('all');
      expect(controller.filteredSeeds.length, 3);

      controller.setFilter('active');
      expect(controller.filteredSeeds.any((s) => s.id == 's-2'), isFalse);

      controller.setFilter('low_stock');
      expect(controller.filteredSeeds.any((s) => s.id == 's-2'), isFalse);

      controller.setFilter('inactive');
      expect(controller.filteredSeeds.any((s) => s.id == 's-2'), isTrue);
    });

    test('uploadImage calls repository and sets public url', () async {
      final url = await controller.uploadImage(fileBytes: [1, 2, 3], fileName: 'seed.jpg');
      expect(url, contains('supabase.co'));
      expect(controller.errorMessage, isNull);
    });

    test('handles 403 Forbidden mutation with visible user feedback', () async {
      mockRepo.shouldThrow = true;
      mockRepo.exceptionToThrow = const SeedsInventoryForbiddenException(
        message: 'Permission denied',
      );

      final okAdd = await controller.addSeed(name: 'Seed', pricePerKg: 10, stockKg: 100);
      expect(okAdd, isFalse);
      expect(controller.errorMessage, contains('Manager role does not have permission'));
    });
  });

  // =========================================================================
  // 4. WIDGET & SCREEN TESTS (Cards, Form, Checkboxes, Roles)
  // =========================================================================

  group('Milestone 5 Step 6 — Widget & Screen UI Tests', () {
    late MockSeedsInventoryRepository mockRepo;
    late SeedsInventoryController controller;

    setUp(() {
      mockRepo = MockSeedsInventoryRepository();
      mockRepo.seeds = [
        const SeedInventoryItem(
          id: 'seed-admin-1',
          name: 'Paddy BPT-5204',
          cropType: 'Paddy',
          variety: 'Rice',
          pricePerKg: 65.50,
          priceGradeA: 75.00,
          priceGradeB: 70.00,
          priceGradeC: 65.00,
          maxOrderQuantityKg: 50.0,
          stockKg: 400.0, // Low stock (< 500 Kg)
          warehouses: [
            SeedWarehouseBrief(id: 'wh-1', name: 'Kurnool Storage Facility'),
            SeedWarehouseBrief(id: 'wh-2', name: 'Nandyal Cold Storage'),
          ],
          description: 'High yield pest resistant seeds',
          isActive: true,
        ),
        const SeedInventoryItem(
          id: 'seed-admin-2',
          name: 'Cotton Super-9',
          variety: 'Hybrid',
          pricePerKg: 140.00,
          stockKg: 1500.0, // Normal stock
          description: 'Rainfed variety',
          isActive: false,
        ),
      ];

      controller = SeedsInventoryController(
        repository: mockRepo,
        accessToken: 'token',
      );
    });

    testWidgets('SeedInventoryCard displays grade pricing, warehouses, and low stock badge', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SeedInventoryCard(
              seed: mockRepo.seeds[0],
              isAdmin: true,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Paddy BPT-5204'), findsOneWidget);
      expect(find.text('Paddy • Rice'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('₹65.50/kg'), findsOneWidget);
      expect(find.text('4 Qtl (400 kg)'), findsOneWidget);
      expect(find.text('LOW STOCK'), findsOneWidget); // < 500 kg badge
      expect(find.text('Max: 50 kg'), findsOneWidget);
      expect(find.text('Grade Prices: '), findsOneWidget);
      expect(find.text('Kurnool Storage Facility'), findsOneWidget);
      expect(find.text('Nandyal Cold Storage'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget); // Admin buttons
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('SeedInventoryCard hides action buttons for Manager (READ-ONLY)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SeedInventoryCard(
              seed: mockRepo.seeds[1],
              isAdmin: false, // Manager role
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Cotton Super-9'), findsOneWidget);
      expect(find.text('Inactive'), findsOneWidget);
      expect(find.text('15 Qtl (1500 kg)'), findsOneWidget);
      expect(find.text('Edit'), findsNothing);
      expect(find.text('Delete'), findsNothing);
    });

    testWidgets('SeedsInventoryScreen renders Admin controls when isAdmin = true', (tester) async {
      await controller.loadSeeds();

      await tester.pumpWidget(
        MaterialApp(
          home: SeedsInventoryScreen(
            controller: controller,
            isAdmin: true,
            onBack: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Seeds Inventory'), findsOneWidget);
      expect(find.text('Add Seed'), findsOneWidget); // Add Seed button visible for Admin
    });

    testWidgets('SeedsInventoryScreen hides Add Seed button when isAdmin = false (Manager)', (tester) async {
      await controller.loadSeeds();

      await tester.pumpWidget(
        MaterialApp(
          home: SeedsInventoryScreen(
            controller: controller,
            isAdmin: false,
            onBack: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Seeds Inventory'), findsOneWidget);
      expect(find.text('Add Seed'), findsNothing); // Add Seed button hidden for Manager
      expect(find.text('Edit'), findsNothing); // Edit button hidden for Manager
      expect(find.text('Delete'), findsNothing); // Delete button hidden for Manager
    });

    testWidgets('SeedsInventoryScreen soft-delete flow updates chip counts and persists after refresh', (tester) async {
      await controller.loadSeeds();

      await tester.pumpWidget(
        MaterialApp(
          home: SeedsInventoryScreen(
            controller: controller,
            isAdmin: true,
            onBack: () {},
          ),
        ),
      );
      await tester.pump();

      // Check filter chips (All shows total count: 2)
      expect(find.text('All (2)'), findsOneWidget);
      expect(find.text('Active (1)'), findsOneWidget);
      expect(find.text('Low Stock (1)'), findsOneWidget);
      expect(find.text('Inactive (1)'), findsOneWidget);

      // Default 'All' view shows both active and inactive seeds
      expect(find.text('Paddy BPT-5204'), findsOneWidget);
      expect(find.text('Cotton Super-9'), findsOneWidget);

      // Tap Inactive chip
      await tester.tap(find.text('Inactive (1)'));
      await tester.pump();

      expect(find.text('Cotton Super-9'), findsOneWidget);
      expect(find.text('Paddy BPT-5204'), findsNothing);

      // Tap Active chip
      await tester.tap(find.text('Active (1)'));
      await tester.pump();

      expect(find.text('Paddy BPT-5204'), findsOneWidget);
      expect(find.text('Cotton Super-9'), findsNothing);
    });

    testWidgets('AddEditSeedSheet validates input and renders multi-warehouse checkboxes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddEditSeedSheet(
              seed: mockRepo.seeds[0], // Edit mode
              availableWarehouses: mockRepo.warehouses,
              onAdd: ({
                required name,
                required pricePerKg,
                required stockKg,
                cropType,
                variety,
                priceGradeA,
                priceGradeB,
                priceGradeC,
                maxOrderQuantityKg,
                warehouseIds,
                description,
                imageUrl,
              }) async =>
                  true,
              onEdit: ({
                required seedId,
                name,
                cropType,
                variety,
                pricePerKg,
                priceGradeA,
                priceGradeB,
                priceGradeC,
                maxOrderQuantityKg,
                stockKg,
                warehouseIds,
                description,
                imageUrl,
                isActive,
              }) async =>
                  true,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Edit Seed Product'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
      expect(find.text('Grade Pricing (₹/kg) — Optional'), findsOneWidget);
      expect(find.text('Fulfillment Warehouses (Multi-Select)'), findsOneWidget);
      expect(find.text('Kurnool Storage Facility'), findsOneWidget);
      expect(find.text('Nandyal Cold Storage'), findsOneWidget);
      expect(find.text('Dhone Regional Depot'), findsOneWidget);
      expect(find.text('Yemmiganur Warehouse'), findsOneWidget);
    });
  });

  // =========================================================================
  // 5. RESPONSIVE SCREEN TESTS (320x568, 360x640, 412x860, 412x960)
  // =========================================================================

  group('Milestone 5 Step 6 — Responsive Layout Verification', () {
    late MockSeedsInventoryRepository mockRepo;
    late SeedsInventoryController controller;

    setUp(() {
      mockRepo = MockSeedsInventoryRepository();
      mockRepo.seeds = List.generate(
        10,
        (i) => SeedInventoryItem(
          id: 'seed-resp-$i',
          name: 'Crop Variety Seed $i',
          cropType: 'Crop $i',
          variety: 'Variety $i',
          pricePerKg: 50.0 + (i * 5),
          priceGradeA: 60.0 + (i * 5),
          maxOrderQuantityKg: 50.0,
          stockKg: (i % 2 == 0) ? 350.0 : 2500.0,
          warehouseIds: ['wh-1'],
          warehouses: const [SeedWarehouseBrief(id: 'wh-1', name: 'Kurnool Storage Facility')],
          description: 'Description for seed product number $i in responsive catalog.',
          isActive: i % 3 != 0,
        ),
      );

      controller = SeedsInventoryController(
        repository: mockRepo,
        accessToken: 'token',
      );
    });

    void testOnResolution(Size size, String label) {
      testWidgets('Renders without overflow on $label (${size.width.toInt()}x${size.height.toInt()})', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await controller.loadSeeds();

        await tester.pumpWidget(
          MaterialApp(
            home: SeedsInventoryScreen(
              controller: controller,
              isAdmin: true,
              onBack: () {},
            ),
          ),
        );
        await tester.pump();

        // Verify key widgets are present
        expect(find.text('Seeds Inventory'), findsOneWidget);
        expect(find.byType(ListView), findsOneWidget);
        expect(tester.takeException(), isNull); // ZERO RenderFlex overflow
      });
    }

    testOnResolution(const Size(320, 568), 'Compact iPhone SE / Small Android');
    testOnResolution(const Size(360, 640), 'Standard Android');
    testOnResolution(const Size(412, 860), 'Modern Android');
    testOnResolution(const Size(412, 960), 'Large Android Flagship');
  });

  // =========================================================================
  // 6. MILESTONE — SEED IMAGE UPLOAD FIX
  // =========================================================================
  group('Milestone 5 — Seed Image Upload Fix', () {
    test('resolveSeedImageMimeType maps extensions and prefers declared MIME type', () {
      expect(resolveSeedImageMimeType('seed.jpg'), 'image/jpeg');
      expect(resolveSeedImageMimeType('seed.jpeg'), 'image/jpeg');
      expect(resolveSeedImageMimeType('seed.PNG'), 'image/png');
      expect(resolveSeedImageMimeType('seed.webp'), 'image/webp');
      expect(resolveSeedImageMimeType('seed.gif'), 'image/gif');
      expect(resolveSeedImageMimeType('no-extension'), 'image/jpeg');
      // Declared type wins when usable.
      expect(resolveSeedImageMimeType('seed.png', 'image/webp'), 'image/webp');
      // Octet-stream placeholder falls back to extension.
      expect(
        resolveSeedImageMimeType('seed.png', 'application/octet-stream'),
        'image/png',
      );
    });

    test('uploadSeedImage sends file field, bucket=seeds, and applied content type', () async {
      http.Request? captured;
      final mockClient = MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'public_url': 'https://cdn.example.com/seeds/photo.png',
              'object_path': 'seeds/photo.png',
              'size_bytes': 3,
              'content_type': 'image/png',
            },
          }),
          201,
        );
      });

      final dataSource = FastApiSeedsInventoryRemoteDataSource(client: mockClient);
      final url = await dataSource.uploadSeedImage(
        accessToken: 'token',
        fileBytes: [10, 20, 30],
        fileName: 'photo.png',
        contentType: 'image/png',
      );

      expect(url, 'https://cdn.example.com/seeds/photo.png');
      expect(captured, isNotNull);
      expect(captured!.method, 'POST');
      expect(captured!.url.path, '/api/v1/uploads');
      expect(captured!.headers['Authorization'], 'Bearer token');
      final contentTypeHeader =
          captured!.headers['content-type'] ?? captured!.headers['Content-Type'];
      expect(contentTypeHeader, isNotNull);
      expect(contentTypeHeader!, startsWith('multipart/form-data; boundary='));

      final body = latin1.decode(captured!.bodyBytes);
      expect(body, contains('name="bucket"\r\n\r\nseeds'));
      expect(body, contains('name="file"; filename="photo.png"'));
      // The picked image content type is applied — not the default image/jpeg.
      expect(body.toLowerCase(), contains('content-type: image/png'));
      expect(body, isNot(contains('image/jpeg')));
    });

    test('uploadSeedImage parses data.public_url and root-level public_url fallback', () async {
      final nestedClient = MockClient((_) async => http.Response(
            jsonEncode({
              'success': true,
              'data': {'public_url': 'https://cdn.example.com/seeds/nested.jpg'},
            }),
            201,
          ));
      final nestedDs = FastApiSeedsInventoryRemoteDataSource(client: nestedClient);
      expect(
        await nestedDs.uploadSeedImage(
          accessToken: 'token',
          fileBytes: [1],
          fileName: 'a.jpg',
        ),
        'https://cdn.example.com/seeds/nested.jpg',
      );

      final rootClient = MockClient((_) async => http.Response(
            jsonEncode({'public_url': 'https://cdn.example.com/seeds/root.jpg'}),
            200,
          ));
      final rootDs = FastApiSeedsInventoryRemoteDataSource(client: rootClient);
      expect(
        await rootDs.uploadSeedImage(
          accessToken: 'token',
          fileBytes: [1],
          fileName: 'b.jpg',
        ),
        'https://cdn.example.com/seeds/root.jpg',
      );
    });

    test('uploadSeedImage throws fixed missing-URL message when public_url absent', () async {
      final bodies = [
        jsonEncode({
          'success': true,
          'data': {'object_path': 'seeds/x.png'},
        }),
        jsonEncode({'public_url': ''}),
        jsonEncode({
          'data': {'public_url': '   '},
        }),
      ];
      for (final body in bodies) {
        final mockClient = MockClient((_) async => http.Response(body, 201));
        final dataSource = FastApiSeedsInventoryRemoteDataSource(client: mockClient);
        await expectLater(
          dataSource.uploadSeedImage(
            accessToken: 'token',
            fileBytes: [1],
            fileName: 'x.png',
          ),
          throwsA(isA<SeedsInventoryException>().having(
            (e) => e.message,
            'message',
            'Image upload completed, but the server did not return a public image URL.',
          )),
        );
      }
    });

    test('upload maps HTTP 401/422/500 to fixed sanitized messages without backend detail', () async {
      Future<String> messageFor(int status, String detail) async {
        final mockClient = MockClient(
          (_) async => http.Response(jsonEncode({'detail': detail}), status),
        );
        final dataSource = FastApiSeedsInventoryRemoteDataSource(client: mockClient);
        try {
          await dataSource.uploadSeedImage(
            accessToken: 'token',
            fileBytes: [1],
            fileName: 'x.jpg',
          );
          fail('Expected SeedsInventoryException for HTTP $status');
        } on SeedsInventoryException catch (e) {
          return e.message;
        }
      }

      final m401 = await messageFor(401, 'Internal auth key XYZ-SECRET-42');
      expect(m401, 'Image upload is not authorized.');
      expect(m401, isNot(contains('XYZ-SECRET-42')));

      final m422 = await messageFor(422, 'Field validation dump: {"db":"users"}');
      expect(m422, 'Image upload was rejected by the server.');
      expect(m422, isNot(contains('"db"')));

      final m500 = await messageFor(500, 'Traceback at /srv/app/main.py line 42');
      expect(m500, 'Image upload service is temporarily unavailable.');
      expect(m500, isNot(contains('Traceback')));
      expect(m500, isNot(contains('main.py')));
    });

    test('upload surfaces SocketException as the fixed connection message', () async {
      final mockClient = MockClient(
        (_) async => throw const SocketException(
          'failed host lookup: agriflow-backend-t8o4.onrender.com',
        ),
      );
      final dataSource = FastApiSeedsInventoryRemoteDataSource(client: mockClient);
      try {
        await dataSource.uploadSeedImage(
          accessToken: 'token',
          fileBytes: [1],
          fileName: 'x.jpg',
        );
        fail('Expected SeedsInventoryException for network failure');
      } on SeedsInventoryException catch (e) {
        expect(e.message, 'Unable to upload image. Check your connection.');
        expect(e.isNetworkError, isTrue);
        expect(e.message, isNot(contains('render.com')));
      }
    });

    test('createSeed and updateSeed send image_url while preserving other fields', () async {
      Map<String, dynamic>? createBody;
      Map<String, dynamic>? updateBody;
      final mockClient = MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        if (request.method == 'POST') {
          createBody = body;
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'id': 's-9',
                'name': body['name'],
                'price_per_kg': body['price_per_kg'],
                'stock_kg': body['stock_kg'],
                'is_active': true,
                'image_url': body['image_url'],
              },
            }),
            201,
          );
        }
        updateBody = body;
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'id': 's-9',
              'name': 'Sunflower',
              'price_per_kg': 42,
              'stock_kg': 500,
              'is_active': body['is_active'] ?? true,
              'image_url': body['image_url'],
            },
          }),
          200,
        );
      });

      final dataSource = FastApiSeedsInventoryRemoteDataSource(client: mockClient);
      final created = await dataSource.createSeed(
        accessToken: 'token',
        name: 'Sunflower',
        pricePerKg: 42,
        stockKg: 500,
        imageUrl: 'https://cdn.example.com/seeds/sunflower.jpg',
      );
      expect(createBody, isNotNull);
      expect(createBody!['image_url'], 'https://cdn.example.com/seeds/sunflower.jpg');
      expect(createBody!['name'], 'Sunflower');
      expect(createBody!['price_per_kg'], 42);
      expect(createBody!['stock_kg'], 500);
      expect(created.imageUrl, 'https://cdn.example.com/seeds/sunflower.jpg');

      final updated = await dataSource.updateSeed(
        accessToken: 'token',
        seedId: 's-9',
        imageUrl: 'https://cdn.example.com/seeds/sunflower-v2.jpg',
        isActive: true,
      );
      expect(updateBody, isNotNull);
      expect(updateBody!['image_url'], 'https://cdn.example.com/seeds/sunflower-v2.jpg');
      expect(updateBody!['is_active'], true);
      expect(updated.imageUrl, 'https://cdn.example.com/seeds/sunflower-v2.jpg');
    });

    test('image URL survives reload when backend returns it', () async {
      final mockRepo = MockSeedsInventoryRepository();
      mockRepo.seeds = [
        const SeedInventoryItem(
          id: 's-img',
          name: 'Paddy',
          pricePerKg: 65,
          stockKg: 800,
          imageUrl: 'https://cdn.example.com/seeds/paddy.jpg',
          isActive: true,
        ),
      ];
      final controller = SeedsInventoryController(
        repository: mockRepo,
        accessToken: 'token',
      );
      await controller.loadSeeds();
      expect(
        controller.allSeeds.first.imageUrl,
        'https://cdn.example.com/seeds/paddy.jpg',
      );

      // Backend JSON round-trip keeps image_url (fresh reload path).
      final parsed = SeedInventoryItem.fromJson({
        'id': 's-img2',
        'name': 'Wheat',
        'price_per_kg': 40,
        'stock_kg': 1000,
        'is_active': true,
        'image_url': 'https://cdn.example.com/seeds/wheat.jpg',
      });
      expect(parsed.imageUrl, 'https://cdn.example.com/seeds/wheat.jpg');
      expect(
        parsed.toJson()['image_url'],
        'https://cdn.example.com/seeds/wheat.jpg',
      );

      // Editing the image URL updates the controller-held entity.
      final ok = await controller.updateSeed(
        seedId: 's-img',
        imageUrl: 'https://cdn.example.com/seeds/updated.jpg',
      );
      expect(ok, isTrue);
      expect(
        controller.allSeeds.first.imageUrl,
        'https://cdn.example.com/seeds/updated.jpg',
      );
    });

    test('controller.uploadImage rethrows sanitized error and exposes errorMessage', () async {
      final mockRepo = MockSeedsInventoryRepository();
      mockRepo.shouldThrow = true;
      mockRepo.exceptionToThrow = const SeedsInventoryUnauthorizedException(
        message: 'Session expired. Please log in again.',
      );
      final controller = SeedsInventoryController(
        repository: mockRepo,
        accessToken: 'token',
      );

      await expectLater(
        controller.uploadImage(fileBytes: [1], fileName: 'x.jpg'),
        throwsA(
          isA<SeedsInventoryException>().having(
            (e) => e.message,
            'message',
            'Session expired. Please log in again.',
          ),
        ),
      );
      expect(controller.errorMessage, 'Session expired. Please log in again.');
      expect(controller.isUploadingImage, isFalse);
    });

    test('controller maps non-exception upload failure to fixed generic message', () async {
      final mockRepo = _ThrowingNonDomainRepo();
      final controller = SeedsInventoryController(
        repository: mockRepo,
        accessToken: 'token',
      );

      await expectLater(
        controller.uploadImage(fileBytes: [1], fileName: 'x.jpg'),
        throwsA(
          isA<SeedsInventoryException>().having(
            (e) => e.message,
            'message',
            ErrorSanitizer.genericErrorMessage,
          ),
        ),
      );
      expect(controller.errorMessage, ErrorSanitizer.genericErrorMessage);
      expect(
        controller.errorMessage,
        isNot(contains('boom')),
      );
    });

    test('production upload flow contains no hardcoded sample PNG bytes', () {
      final sheetSource = File(
        'lib/features/seeds_inventory/presentation/widgets/add_edit_seed_sheet.dart',
      ).readAsStringSync();
      expect(sheetSource, contains('_handleImageUpload'));
      expect(sheetSource, isNot(contains('_handleSampleUpload')));
      expect(sheetSource, isNot(contains('1x1 transparent PNG')));
      expect(sheetSource, isNot(contains('0x89, 0x50, 0x4E, 0x47')));
      expect(sheetSource, isNot(contains('sampleBytes')));

      final controllerSource = File(
        'lib/features/seeds_inventory/presentation/controllers/seeds_inventory_controller.dart',
      ).readAsStringSync();
      expect(controllerSource, isNot(contains('0x89, 0x50, 0x4E, 0x47')));
    });

    group('widget upload integration', () {
      Widget buildUploadSheet({
        SeedImagePicker? picker,
        Future<String?> Function({
          required List<int> fileBytes,
          required String fileName,
          required String contentType,
        })? onUploadImage,
      }) {
        return MaterialApp(
          home: Scaffold(
            body: AddEditSeedSheet(
              availableWarehouses: const [],
              imagePicker: picker,
              onAdd: ({
                required name,
                required pricePerKg,
                required stockKg,
                cropType,
                variety,
                priceGradeA,
                priceGradeB,
                priceGradeC,
                maxOrderQuantityKg,
                warehouseIds,
                description,
                imageUrl,
              }) async =>
                  true,
              onEdit: ({
                required seedId,
                name,
                cropType,
                variety,
                pricePerKg,
                priceGradeA,
                priceGradeB,
                priceGradeC,
                maxOrderQuantityKg,
                stockKg,
                warehouseIds,
                description,
                imageUrl,
                isActive,
              }) async =>
                  true,
              onUploadImage: onUploadImage,
            ),
          ),
        );
      }

      testWidgets(
        'Upload Image opens picker, uploads the real selection, and stores its URL',
        (tester) async {
          const picked = SeedPickedImage(
            bytes: [10, 20, 30],
            fileName: 'bajra.webp',
            mimeType: 'image/webp',
          );
          var pickerCalls = 0;
          List<int>? sentBytes;
          String? sentName;
          String? sentType;

          await tester.pumpWidget(buildUploadSheet(
            picker: SeedImagePicker(
              pick: () async {
                pickerCalls++;
                return picked;
              },
            ),
            onUploadImage: ({
              required fileBytes,
              required fileName,
              required contentType,
            }) async {
              sentBytes = fileBytes;
              sentName = fileName;
              sentType = contentType;
              return 'https://cdn.example.com/seeds/bajra.webp';
            },
          ));
          await tester.pump();

          expect(find.text('Upload Image'), findsOneWidget);
          await tester.ensureVisible(find.text('Upload Image'));
          await tester.tap(find.text('Upload Image'));
          await tester.pumpAndSettle();

          expect(pickerCalls, 1);
          expect(sentBytes, [10, 20, 30]);
          expect(sentName, 'bajra.webp');
          expect(sentType, 'image/webp');
          expect(
            find.text('https://cdn.example.com/seeds/bajra.webp'),
            findsOneWidget,
          );
          expect(find.text(ErrorSanitizer.genericErrorMessage), findsNothing);
          expect(find.text('Uploading...'), findsNothing);
        },
      );

      testWidgets('Cancelling the gallery picker returns to idle without errors', (tester) async {
        var pickerCalls = 0;
        var uploadCalls = 0;

        await tester.pumpWidget(buildUploadSheet(
          picker: SeedImagePicker(
            pick: () async {
              pickerCalls++;
              return null;
            },
          ),
          onUploadImage: ({
            required fileBytes,
            required fileName,
            required contentType,
          }) async {
            uploadCalls++;
            return 'https://cdn.example.com/seeds/never.jpg';
          },
        ));
        await tester.pump();

        await tester.ensureVisible(find.text('Upload Image'));
        await tester.tap(find.text('Upload Image'));
        await tester.pumpAndSettle();

        expect(pickerCalls, 1);
        expect(uploadCalls, 0);
        expect(find.text('Uploading...'), findsNothing);
        expect(find.text(ErrorSanitizer.genericErrorMessage), findsNothing);
        final button = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Upload Image'),
        );
        expect(button.onPressed, isNotNull);
      });

      testWidgets('Typed upload exception is shown inline as a fixed message', (tester) async {
        await tester.pumpWidget(buildUploadSheet(
          picker: SeedImagePicker(
            pick: () async => const SeedPickedImage(
              bytes: [1],
              fileName: 'x.jpg',
              mimeType: 'image/jpeg',
            ),
          ),
          onUploadImage: ({
            required fileBytes,
            required fileName,
            required contentType,
          }) async {
            throw const SeedsInventoryUnauthorizedException(
              message: 'Image upload is not authorized.',
            );
          },
        ));
        await tester.pump();

        await tester.ensureVisible(find.text('Upload Image'));
        await tester.tap(find.text('Upload Image'));
        await tester.pumpAndSettle();

        expect(find.text('Image upload is not authorized.'), findsOneWidget);
        expect(find.text(ErrorSanitizer.genericErrorMessage), findsNothing);
        expect(find.text('Uploading...'), findsNothing);
        final button = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Upload Image'),
        );
        expect(button.onPressed, isNotNull);
      });

      testWidgets('Non-exception failure never displays raw exception text', (tester) async {
        await tester.pumpWidget(buildUploadSheet(
          picker: SeedImagePicker(
            pick: () async => const SeedPickedImage(
              bytes: [1],
              fileName: 'x.jpg',
              mimeType: 'image/jpeg',
            ),
          ),
          onUploadImage: ({
            required fileBytes,
            required fileName,
            required contentType,
          }) async {
            throw StateError('boom-secret-internal-detail');
          },
        ));
        await tester.pump();

        await tester.ensureVisible(find.text('Upload Image'));
        await tester.tap(find.text('Upload Image'));
        await tester.pumpAndSettle();

        expect(find.text(ErrorSanitizer.genericErrorMessage), findsOneWidget);
        expect(find.textContaining('boom'), findsNothing);
        expect(find.textContaining('StateError'), findsNothing);
        expect(find.text('Uploading...'), findsNothing);
      });
    });

    group('Inactive->Active edit, inline errors, and narrow layout', () {
      testWidgets('AddEditSeedSheet renders without overflow on 320px width and shows errorProvider message on failed submit',
          (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        bool? submittedActive;
        String? controllerError;

        final inactiveSeed = SeedInventoryItem.fromJson(const {
          'id': 'seed-inactive-1',
          'name': 'Bajra Hybrid',
          'crop_type': 'Other',
          'variety': 'seeds',
          'price_per_kg': 290.0,
          'stock_kg': 7400.0,
          'is_active': false,
        });

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AddEditSeedSheet(
                seed: inactiveSeed,
                errorProvider: () => controllerError,
                onAdd: ({
                  required name,
                  required pricePerKg,
                  required stockKg,
                  cropType,
                  variety,
                  priceGradeA,
                  priceGradeB,
                  priceGradeC,
                  maxOrderQuantityKg,
                  warehouseIds,
                  description,
                  imageUrl,
                }) async =>
                    false,
                onEdit: ({
                  required seedId,
                  name,
                  cropType,
                  variety,
                  pricePerKg,
                  priceGradeA,
                  priceGradeB,
                  priceGradeC,
                  maxOrderQuantityKg,
                  stockKg,
                  warehouseIds,
                  description,
                  imageUrl,
                  isActive,
                }) async {
                  submittedActive = isActive;
                  controllerError = 'Session expired. Please log in again.';
                  return false;
                },
                onUploadImage: ({
                  required fileBytes,
                  required fileName,
                  required contentType,
                }) async =>
                    null,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        final switchFinder = find.byType(Switch);
        await tester.ensureVisible(switchFinder);
        await tester.tap(switchFinder);
        await tester.pump();

        final saveFinder = find.text('Save Changes');
        await tester.ensureVisible(saveFinder);
        await tester.tap(saveFinder);
        await tester.pumpAndSettle();

        expect(submittedActive, isTrue);
        expect(find.text('Session expired. Please log in again.'), findsWidgets);
        expect(tester.takeException(), isNull);
      });

      testWidgets('SeedsInventoryScreen keeps All, Active, Low Stock, Inactive chips on one line at 360px width',
          (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final items = [
          for (int i = 0; i < 8; i++)
            SeedInventoryItem.fromJson({
              'id': 'active-$i',
              'name': 'Active Seed $i',
              'price_per_kg': 70.0,
              'stock_kg': 1000.0,
              'is_active': true,
            }),
          for (int i = 0; i < 27; i++)
            SeedInventoryItem.fromJson({
              'id': 'inactive-$i',
              'name': 'Inactive Seed $i',
              'price_per_kg': 70.0,
              'stock_kg': 1000.0,
              'is_active': false,
            }),
        ];
        final repo = MockSeedsInventoryRepository()..seeds = items;
        final ctrl = SeedsInventoryController(
          repository: repo,
          accessToken: 'token',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: SeedsInventoryScreen(
              controller: ctrl,
              isAdmin: true,
              onBack: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        final allChip = tester.getCenter(find.text('All (35)'));
        final activeChip = tester.getCenter(find.text('Active (8)'));
        final lowStockChip = tester.getCenter(find.text('Low Stock (0)'));
        final inactiveChip = tester.getCenter(find.text('Inactive (27)'));

        expect((allChip.dy - activeChip.dy).abs(), lessThan(2.0));
        expect((activeChip.dy - lowStockChip.dy).abs(), lessThan(2.0));
        expect((lowStockChip.dy - inactiveChip.dy).abs(), lessThan(2.0));
        expect(tester.takeException(), isNull);
      });
    });
  });
}

/// Repository double whose upload path throws a non-domain exception.
class _ThrowingNonDomainRepo implements SeedsInventoryRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #uploadSeedImage) {
      throw StateError('boom-raw-transport-detail');
    }
    throw UnimplementedError('Not used in this test');
  }
}
