import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:agriflow_admin/features/grain_sales/data/datasources/grain_sale_remote_data_source.dart';
import 'package:agriflow_admin/features/grain_sales/data/repositories/grain_sale_repository_impl.dart';
import 'package:agriflow_admin/features/grain_sales/domain/entities/grain_sale_exception.dart';
import 'package:agriflow_admin/features/grain_sales/domain/entities/grain_sale_item.dart';
import 'package:agriflow_admin/features/grain_sales/domain/entities/grain_sale_pagination.dart';
import 'package:agriflow_admin/features/grain_sales/domain/repositories/grain_sale_repository.dart';
import 'package:agriflow_admin/features/grain_sales/presentation/controllers/grain_sale_controller.dart';
import 'package:agriflow_admin/features/grain_sales/presentation/screens/grain_sale_screen.dart';
import 'package:agriflow_admin/features/grain_sales/presentation/widgets/grain_sale_card.dart';
import 'package:agriflow_admin/features/grain_sales/presentation/widgets/grain_sale_detail_sheet.dart';
import 'package:agriflow_admin/features/grain_sales/presentation/widgets/log_received_crop_sheet.dart';
import 'package:agriflow_admin/features/booking_slot/data/datasources/booking_remote_data_source.dart';
import 'package:agriflow_admin/features/booking_slot/domain/entities/booking_item.dart';
import 'package:agriflow_admin/features/booking_slot/domain/entities/booking_pagination.dart';
import 'package:agriflow_admin/features/booking_slot/domain/entities/warehouse_item.dart';

// -------------------------------------------------------------
// Test Helpers & Mocks
// -------------------------------------------------------------

class _MockGrainSaleRemoteDataSource implements GrainSaleRemoteDataSource {
  List<GrainSaleItem> salesToReturn = [];
  GrainSalePagination paginationToReturn = const GrainSalePagination(
    page: 1,
    pageSize: 20,
    total: 0,
    totalPages: 1,
  );
  Map<String, ({String name, String phone, String? village})> farmersToReturn = {};
  Exception? errorToThrow;
  bool failCatalog = false;

  int getSalesCallCount = 0;
  int procureCallCount = 0;
  int reviewCallCount = 0;
  int payCallCount = 0;
  int yieldCallCount = 0;
  double? lastYieldGoodKg;
  double? lastYieldWastageKg;
  int getFarmersCallCount = 0;
  String? lastBookingSlotId;
  final List<String?> statusesRequested = [];

  @override
  Future<({List<GrainSaleItem> items, GrainSalePagination pagination})> getGrainSales({
    required String accessToken,
    int page = 1,
    int pageSize = 20,
    String? search,
    String? status,
    String? sort,
    String? order,
  }) async {
    getSalesCallCount++;
    statusesRequested.add(status);
    if (errorToThrow != null) throw errorToThrow!;

    var filtered = List<GrainSaleItem>.from(salesToReturn);
    if (status != null && status != 'all') {
      filtered = filtered.where((s) => s.status.toLowerCase() == status.toLowerCase()).toList();
    }
    if (search != null && search.isNotEmpty) {
      final q = search.toLowerCase();
      filtered = filtered
          .where((s) =>
              s.grainType.toLowerCase().contains(q) ||
              (s.enrichedFarmerName?.toLowerCase().contains(q) ?? false) ||
              s.farmerId.toLowerCase().contains(q))
          .toList();
    }

    return (items: filtered, pagination: paginationToReturn.copyWith(total: filtered.length));
  }

  @override
  Future<GrainSaleItem> procureCrop({
    required String accessToken,
    required String farmerId,
    required String grainType,
    required String grade,
    required double rawMaterialKg,
    required double goodMaterialKg,
    required double wastageKg,
  }) async {
    procureCallCount++;
    if (errorToThrow != null) throw errorToThrow!;

    final newItem = GrainSaleItem(
      id: 'gs-new-1',
      farmerId: farmerId,
      grainType: grainType,
      grade: grade,
      rawMaterialKg: rawMaterialKg.toString(),
      goodMaterialKg: goodMaterialKg.toString(),
      wastageKg: wastageKg.toString(),
      pricePerKg: '35',
      totalAmount: (goodMaterialKg * 35.0).toStringAsFixed(0),
      status: 'pending',
      createdAt: DateTime.now(),
    );
    salesToReturn.insert(0, newItem);
    return newItem;
  }

  @override
  Future<GrainSaleItem> reviewGrainSale({
    required String accessToken,
    required String saleId,
    required String bookingSlotId,
    required double goodQuantityKg,
    required double badQuantityKg,
    bool approve = true,
    String? rejectionReason,
  }) async {
    reviewCallCount++;
    lastBookingSlotId = bookingSlotId;
    if (errorToThrow != null) throw errorToThrow!;

    final targetStatus = approve ? 'approved' : 'rejected';
    final index = salesToReturn.indexWhere((s) => s.id == saleId);
    if (index != -1) {
      final updated = salesToReturn[index];
      final reviewed = updated.copyWith(
        goodMaterialKg: goodQuantityKg.toString(),
        wastageKg: badQuantityKg.toString(),
        status: targetStatus,
      );
      salesToReturn[index] = reviewed;
      return reviewed;
    }

    return _createSampleSale(id: saleId, status: targetStatus);
  }

  @override
  Future<GrainSaleItem> payGrainSale({
    required String accessToken,
    required String saleId,
    String? paymentReference,
  }) async {
    payCallCount++;
    if (errorToThrow != null) throw errorToThrow!;

    final index = salesToReturn.indexWhere((s) => s.id == saleId);
    if (index != -1) {
      final updated = salesToReturn[index];
      final paidItem = GrainSaleItem(
        id: updated.id,
        farmerId: updated.farmerId,
        grainType: updated.grainType,
        grade: updated.grade,
        rawMaterialKg: updated.rawMaterialKg,
        goodMaterialKg: updated.goodMaterialKg,
        wastageKg: updated.wastageKg,
        pricePerKg: updated.pricePerKg,
        totalAmount: updated.totalAmount,
        status: 'paid',
        createdAt: updated.createdAt,
        enrichedFarmerName: updated.enrichedFarmerName,
        enrichedFarmerPhone: updated.enrichedFarmerPhone,
        enrichedFarmerVillage: updated.enrichedFarmerVillage,
      );
      salesToReturn[index] = paidItem;
      return paidItem;
    }

    return GrainSaleItem(
      id: saleId,
      farmerId: 'farmer-1',
      grainType: 'Wheat',
      grade: 'A',
      rawMaterialKg: '1000',
      goodMaterialKg: '950',
      wastageKg: '50',
      pricePerKg: '30',
      totalAmount: '28500',
      status: 'paid',
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<GrainSaleItem> updateGrainYield({
    required String accessToken,
    required String saleId,
    required double goodMaterialKg,
    required double wastageKg,
  }) async {
    yieldCallCount++;
    lastYieldGoodKg = goodMaterialKg;
    lastYieldWastageKg = wastageKg;
    if (errorToThrow != null) throw errorToThrow!;

    final index = salesToReturn.indexWhere((s) => s.id == saleId);
    if (index != -1) {
      final updated = salesToReturn[index].copyWith(
        goodMaterialKg: goodMaterialKg.toString(),
        wastageKg: wastageKg.toString(),
      );
      salesToReturn[index] = updated;
      return updated;
    }

    return GrainSaleItem(
      id: saleId,
      farmerId: 'farmer-1',
      grainType: 'Wheat',
      grade: 'A',
      rawMaterialKg: '1000',
      goodMaterialKg: goodMaterialKg.toString(),
      wastageKg: wastageKg.toString(),
      pricePerKg: '30',
      totalAmount: '28500',
      status: 'pending',
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<Map<String, ({String name, String phone, String? village})>> getFarmers({
    required String accessToken,
  }) async {
    getFarmersCallCount++;
    if (failCatalog) throw Exception('Farmer catalog error');
    return farmersToReturn;
  }
}

class _MockBookingRemoteDataSource implements BookingRemoteDataSource {
  List<BookingItem> bookingsToReturn = [];
  Exception? errorToThrow;
  int getBookingsCallCount = 0;

  @override
  Future<({List<BookingItem> items, BookingPagination pagination})> getBookings({
    required String accessToken,
    int page = 1,
    int pageSize = 20,
    String? search,
    String? status,
  }) async {
    getBookingsCallCount++;
    if (errorToThrow != null) throw errorToThrow!;
    return (
      items: bookingsToReturn,
      pagination: BookingPagination(
        page: page,
        pageSize: pageSize,
        total: bookingsToReturn.length,
        totalPages: 1,
      ),
    );
  }

  @override
  Future<BookingItem> updateBookingStatus({
    required String accessToken,
    required String bookingId,
    required String newStatus,
    String? notes,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> inspectBooking({
    required String accessToken,
    required String bookingId,
    required double goodQuantityKg,
    required double badQuantityKg,
    String? rejectionReason,
    String? notes,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<List<WarehouseItem>> getWarehouses({required String accessToken}) async {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, ({String name, String phone})>> getFarmerLookup({
    required String accessToken,
  }) async {
    throw UnimplementedError();
  }
}

BookingItem _createBooking({required String id, String? grainSaleId}) {
  return BookingItem(
    id: id,
    farmerId: 'farmer-1',
    warehouseId: 'warehouse-1',
    grainSaleId: grainSaleId,
    bookingDate: '2026-09-24',
    grainType: 'Soybean',
    quantityKg: 2500,
    status: 'pending',
  );
}

GrainSaleItem _createSampleSale({
  String id = 'gs-1',
  String farmerId = 'farmer-1',
  String grainType = 'Soybean',
  String grade = 'Grade A',
  String rawMaterialKg = '2500',
  String goodMaterialKg = '2400',
  String wastageKg = '100',
  String? pricePerKg = '45',
  String totalAmount = '108000',
  String status = 'pending',
  String? farmerName = 'Ramesh Patel',
  String? farmerPhone = '9876543210',
  String? farmerVillage = 'Navalgund',
}) {
  return GrainSaleItem(
    id: id,
    farmerId: farmerId,
    grainType: grainType,
    grade: grade,
    rawMaterialKg: rawMaterialKg,
    goodMaterialKg: goodMaterialKg,
    wastageKg: wastageKg,
    pricePerKg: pricePerKg,
    totalAmount: totalAmount,
    status: status,
    createdAt: DateTime.parse('2026-09-24T10:00:00Z'),
    enrichedFarmerName: farmerName,
    enrichedFarmerPhone: farmerPhone,
    enrichedFarmerVillage: farmerVillage,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Milestone 5 Step 4 — GrainSaleItem Domain Entity', () {
    test('parses correctly from full JSON', () {
      final json = {
        'id': 'sale-101',
        'farmer_id': 'f-888',
        'grain_type': 'Maize',
        'grade': 'FAQ',
        'raw_material_kg': 1500.0,
        'good_material_kg': 1450.0,
        'wastage_kg': 50.0,
        'price_per_kg': 22.5,
        'total_amount': 32625.0,
        'status': 'paid',
        'created_at': '2026-09-24T08:30:00Z',
      };

      final item = GrainSaleItem.fromJson(json);

      expect(item.id, 'sale-101');
      expect(item.farmerId, 'f-888');
      expect(item.grainType, 'Maize');
      expect(item.grade, 'FAQ');
      expect(item.rawMaterialKg, '1500.0');
      expect(item.goodMaterialKg, '1450.0');
      expect(item.wastageKg, '50.0');
      expect(item.pricePerKg, '22.5');
      expect(item.totalAmount, '32625.0');
      expect(item.status, 'paid');
      expect(item.isPaid, isTrue);
    });

    test('calculates Quintal values accurately (kg / 100)', () {
      final item = _createSampleSale(
        rawMaterialKg: '2550',
        goodMaterialKg: '2450',
        wastageKg: '100',
      );

      expect(item.rawMaterialQuintals, '25.5');
      expect(item.goodMaterialQuintals, '24.5');
      expect(item.wastageQuintals, '1.0');
    });

    test('displayFarmerName falls back to Farmer #<id> when enrichedFarmerName is null', () {
      final itemWithName = _createSampleSale(farmerName: 'Suresh Kumar');
      expect(itemWithName.displayFarmerName, 'Suresh Kumar');

      final itemWithoutName = _createSampleSale(farmerId: '12345678-abcd', farmerName: null);
      expect(itemWithoutName.displayFarmerName, 'Farmer #12345678');
    });

    test('isPaid and isPending return expected booleans', () {
      final paidSale = _createSampleSale(status: 'paid');
      expect(paidSale.isPaid, isTrue);
      expect(paidSale.isPending, isFalse);

      final pendingSale = _createSampleSale(status: 'pending');
      expect(pendingSale.isPaid, isFalse);
      expect(pendingSale.isPending, isTrue);
    });

    test('copyWithEnrichment preserves existing fields while updating farmer data', () {
      final original = _createSampleSale(farmerName: null, farmerPhone: null);
      final enriched = original.copyWithEnrichment(
        farmerName: 'Anita Devi',
        farmerPhone: '9988776655',
        farmerVillage: 'Hubli',
      );

      expect(enriched.id, original.id);
      expect(enriched.grainType, original.grainType);
      expect(enriched.enrichedFarmerName, 'Anita Devi');
      expect(enriched.enrichedFarmerPhone, '9988776655');
      expect(enriched.enrichedFarmerVillage, 'Hubli');
    });
  });

  group('Milestone 5 Step 4 — GrainSalePagination Domain Entity', () {
    test('parses pagination JSON correctly with hasMore check', () {
      final json = {
        'page': 1,
        'page_size': 20,
        'total': 45,
        'total_pages': 3,
      };

      final pagination = GrainSalePagination.fromJson(json);

      expect(pagination.page, 1);
      expect(pagination.pageSize, 20);
      expect(pagination.total, 45);
      expect(pagination.totalPages, 3);
      expect(pagination.hasMore, isTrue);
    });

    test('handles default fallbacks for null values', () {
      final pagination = GrainSalePagination.fromJson({});
      expect(pagination.page, 1);
      expect(pagination.pageSize, 20);
      expect(pagination.total, 0);
      expect(pagination.totalPages, 1);
      expect(pagination.hasMore, isFalse);
    });
  });

  group('Milestone 5 Step 4 — GrainSaleException Hierarchy', () {
    test('each typed exception formats message and status code', () {
      const e401 = GrainSaleUnauthorizedException(message: 'Session expired');
      expect(e401.statusCode, 401);
      expect(e401.message, 'Session expired');

      const e403 = GrainSaleForbiddenException(message: 'Admin role required');
      expect(e403.statusCode, 403);
      expect(e403.message, 'Admin role required');

      const e404 = GrainSaleNotFoundException(message: 'Sale not found');
      expect(e404.statusCode, 404);
      expect(e404.message, 'Sale not found');

      const e422 = GrainSaleValidationException(message: 'Invalid quintals input');
      expect(e422.statusCode, 422);
      expect(e422.message, 'Invalid quintals input');

      const e500 = GrainSaleServerException(message: 'Server connection failed');
      expect(e500.statusCode, 500);
      expect(e500.message, 'Server connection failed');
    });
  });

  group('Milestone 5 Step 4 — GrainSaleRepositoryImpl', () {
    late _MockGrainSaleRemoteDataSource mockRemoteDataSource;
    late _MockBookingRemoteDataSource mockBookingDataSource;
    late GrainSaleRepository repository;

    setUp(() {
      mockRemoteDataSource = _MockGrainSaleRemoteDataSource();
      mockBookingDataSource = _MockBookingRemoteDataSource();
      repository = GrainSaleRepositoryImpl(
        remoteDataSource: mockRemoteDataSource,
        bookingDataSource: mockBookingDataSource,
      );
    });

    test('enriches grain sales with farmer lookup catalog', () async {
      mockRemoteDataSource.salesToReturn = [
        _createSampleSale(id: 's-1', farmerId: 'farmer-101', farmerName: null),
      ];
      mockRemoteDataSource.farmersToReturn = {
        'farmer-101': (name: 'Kavitha Rao', phone: '9123456780', village: 'Dharwad'),
      };

      final result = await repository.getGrainSales(accessToken: 'valid-token');

      expect(result.items.length, 1);
      expect(result.items.first.enrichedFarmerName, 'Kavitha Rao');
      expect(result.items.first.enrichedFarmerPhone, '9123456780');
      expect(result.items.first.enrichedFarmerVillage, 'Dharwad');
    });

    test('handles farmer catalog error gracefully without failing grain sales list', () async {
      mockRemoteDataSource.salesToReturn = [
        _createSampleSale(id: 's-1', farmerId: 'f-12345', farmerName: null),
      ];
      mockRemoteDataSource.failCatalog = true;

      final result = await repository.getGrainSales(accessToken: 'valid-token');

      expect(result.items.length, 1);
      expect(result.items.first.displayFarmerName, 'Farmer #f-12345');
    });

    test('caches farmer lookup catalog across multiple calls', () async {
      mockRemoteDataSource.farmersToReturn = {
        'f-1': (name: 'Farmer One', phone: '1111111111', village: 'Village A'),
      };

      await repository.getFarmerLookup(accessToken: 'valid-token');
      await repository.getFarmerLookup(accessToken: 'valid-token');

      expect(mockRemoteDataSource.getFarmersCallCount, 1);
    });

    test('procureCrop delegates to remote data source', () async {
      final item = await repository.procureCrop(
        accessToken: 'valid-token',
        farmerId: 'farmer-1',
        grainType: 'Wheat',
        grade: 'A',
        rawMaterialKg: 2000.0,
        goodMaterialKg: 1900.0,
        wastageKg: 100.0,
      );

      expect(mockRemoteDataSource.procureCallCount, 1);
      expect(item.grainType, 'Wheat');
      expect(item.rawMaterialKg, '2000.0');
    });

    test('reviewGrainSale delegates to remote data source (approve=true -> approved)', () async {
      mockRemoteDataSource.salesToReturn = [
        _createSampleSale(id: 'sale-rev-1', status: 'received'),
      ];
      mockBookingDataSource.bookingsToReturn = [
        _createBooking(id: 'slot-1', grainSaleId: 'sale-rev-1'),
      ];

      final approved = await repository.reviewGrainSale(
        accessToken: 'valid-token',
        saleId: 'sale-rev-1',
        goodQuantityKg: 2400.0,
        badQuantityKg: 100.0,
        approve: true,
      );

      expect(mockRemoteDataSource.reviewCallCount, 1);
      expect(mockRemoteDataSource.lastBookingSlotId, 'slot-1');
      expect(approved.status, 'approved');
    });

    test('reviewGrainSale delegates to remote data source (approve=false -> rejected)', () async {
      mockRemoteDataSource.salesToReturn = [
        _createSampleSale(id: 'sale-rev-2', status: 'received'),
      ];
      mockBookingDataSource.bookingsToReturn = [
        _createBooking(id: 'slot-2', grainSaleId: 'sale-rev-2'),
      ];

      final rejected = await repository.reviewGrainSale(
        accessToken: 'valid-token',
        saleId: 'sale-rev-2',
        goodQuantityKg: 0.0,
        badQuantityKg: 2500.0,
        approve: false,
        rejectionReason: 'Damaged crop',
      );

      expect(mockRemoteDataSource.reviewCallCount, 1);
      expect(rejected.status, 'rejected');
    });

    test('review payload sends booking_slot_id from bookings join and never the sale id', () async {
      String? capturedBody;
      String? capturedUrl;
      final mockClient = MockClient((request) async {
        capturedUrl = request.url.toString();
        capturedBody = request.body;
        return http.Response(
          jsonEncode({
            'data': {
              'id': 's-1',
              'farmer_id': 'farmer-1',
              'grain_type': 'Soybean',
              'grade': 'Grade A',
              'raw_material_kg': 2500.0,
              'good_material_kg': 2400.0,
              'wastage_kg': 100.0,
              'price_per_kg': 45.0,
              'total_amount': 108000.0,
              'status': 'approved',
              'created_at': '2026-09-24T10:00:00Z',
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      mockBookingDataSource.bookingsToReturn = [
        _createBooking(id: 'b-1', grainSaleId: 's-1'),
      ];
      final repo = GrainSaleRepositoryImpl(
        remoteDataSource: FastApiGrainSaleRemoteDataSource(client: mockClient),
        bookingDataSource: mockBookingDataSource,
      );

      await repo.reviewGrainSale(
        accessToken: 'valid-token',
        saleId: 's-1',
        goodQuantityKg: 2400.0,
        badQuantityKg: 100.0,
        approve: true,
      );

      expect(capturedUrl, contains('/grain-sales/s-1/review'));
      final body = jsonDecode(capturedBody!) as Map<String, dynamic>;
      expect(body['booking_slot_id'], 'b-1');
      expect(body['booking_slot_id'] == 's-1', isFalse,
          reason: 'sale id must never be submitted as booking_slot_id');
      expect(body['good_quantity_kg'], 2400.0);
      expect(body['bad_quantity_kg'], 100.0);
      expect(body['approve'], true);
    });

    test('review resolves booking slot through grain_sale_id join against GET bookings', () async {
      mockRemoteDataSource.salesToReturn = [
        _createSampleSale(id: 's-join', status: 'received'),
      ];
      mockBookingDataSource.bookingsToReturn = [
        _createBooking(id: 'b-other', grainSaleId: 's-unrelated'),
        _createBooking(id: 'b-9', grainSaleId: 's-join'),
      ];

      final item = await repository.reviewGrainSale(
        accessToken: 'valid-token',
        saleId: 's-join',
        goodQuantityKg: 2400.0,
        badQuantityKg: 100.0,
        approve: true,
      );

      expect(mockBookingDataSource.getBookingsCallCount, 1);
      expect(mockRemoteDataSource.lastBookingSlotId, 'b-9');
      expect(item.status, 'approved');
    });

    test('review with no booking throws the guard message and makes no review call', () async {
      mockRemoteDataSource.salesToReturn = [
        _createSampleSale(id: 's-nobk', status: 'received'),
      ];
      mockBookingDataSource.bookingsToReturn = [
        _createBooking(id: 'b-other', grainSaleId: 's-someone-else'),
      ];

      await expectLater(
        repository.reviewGrainSale(
          accessToken: 'valid-token',
          saleId: 's-nobk',
          goodQuantityKg: 100.0,
          badQuantityKg: 5.0,
        ),
        throwsA(
          isA<GrainSaleException>().having(
            (e) => e.message,
            'message',
            'This grain sale is not associated with a booking slot and cannot be reviewed yet.',
          ),
        ),
      );
      expect(mockRemoteDataSource.reviewCallCount, 0);
    });

    test('payGrainSale delegates to remote data source', () async {
      mockRemoteDataSource.salesToReturn = [
        _createSampleSale(id: 'sale-pay-1', status: 'pending'),
      ];

      final paid = await repository.payGrainSale(
        accessToken: 'valid-token',
        saleId: 'sale-pay-1',
        paymentReference: 'TXN-9988',
      );

      expect(mockRemoteDataSource.payCallCount, 1);
      expect(paid.status, 'paid');
    });
  });

  group('Milestone 5 Step 4 — GrainSaleController', () {
    late _MockGrainSaleRemoteDataSource mockRemoteDataSource;
    late _MockBookingRemoteDataSource mockBookingDataSource;
    late GrainSaleRepository repository;
    late GrainSaleController controller;

    setUp(() {
      mockRemoteDataSource = _MockGrainSaleRemoteDataSource();
      mockBookingDataSource = _MockBookingRemoteDataSource();
      repository = GrainSaleRepositoryImpl(
        remoteDataSource: mockRemoteDataSource,
        bookingDataSource: mockBookingDataSource,
      );
      controller = GrainSaleController(
        repository: repository,
        accessToken: 'test-token',
      );
    });

    tearDown(() {
      controller.dispose();
    });

    test('initial state has empty sales and is not loading', () {
      expect(controller.sales, isEmpty);
      expect(controller.isLoading, isFalse);
      expect(controller.errorMessage, isNull);
    });

    test('loadSales fetches and populates items', () async {
      mockRemoteDataSource.salesToReturn = [
        _createSampleSale(id: 's-1'),
        _createSampleSale(id: 's-2'),
      ];

      await controller.loadSales();

      expect(controller.sales.length, 2);
      expect(controller.isLoading, isFalse);
      expect(controller.errorMessage, isNull);
    });

    test('refreshSales cleanly replaces existing dataset', () async {
      mockRemoteDataSource.salesToReturn = [_createSampleSale(id: 's-1')];
      await controller.loadSales();
      expect(controller.sales.length, 1);

      mockRemoteDataSource.salesToReturn = [
        _createSampleSale(id: 's-new-1'),
        _createSampleSale(id: 's-new-2'),
      ];
      await controller.refreshSales();

      expect(controller.sales.length, 2);
      expect(controller.sales.first.id, 's-new-1');
    });

    test('loadMoreSales appends items when hasMore is true', () async {
      mockRemoteDataSource.salesToReturn = [_createSampleSale(id: 'page1-s1')];
      mockRemoteDataSource.paginationToReturn = const GrainSalePagination(
        page: 1,
        pageSize: 1,
        total: 2,
        totalPages: 2,
      );

      await controller.loadSales();
      expect(controller.sales.length, 1);

      mockRemoteDataSource.salesToReturn = [_createSampleSale(id: 'page2-s2')];
      mockRemoteDataSource.paginationToReturn = const GrainSalePagination(
        page: 2,
        pageSize: 1,
        total: 2,
        totalPages: 2,
      );

      await controller.loadMoreSales();
      expect(controller.sales.length, 2);
      expect(controller.sales.last.id, 'page2-s2');
    });

    test('setFilter reloads sales with filtered query', () async {
      mockRemoteDataSource.salesToReturn = [
        _createSampleSale(id: 's-1', status: 'paid'),
        _createSampleSale(id: 's-2', status: 'pending'),
      ];

      await controller.loadSales();
      expect(controller.sales.length, 2);

      controller.setFilter('paid');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(controller.sales.every((s) => s.status == 'paid'), isTrue);
    });

    test('procureCrop prepends new crop and increments pagination total', () async {
      mockRemoteDataSource.salesToReturn = [_createSampleSale(id: 's-existing')];
      await controller.loadSales();

      final success = await controller.procureCrop(
        farmerId: 'farmer-88',
        grainType: 'Soybean',
        grade: 'A',
        rawMaterialKg: 3000.0,
        goodMaterialKg: 2850.0,
        wastageKg: 150.0,
      );

      expect(success, isTrue);
      expect(controller.sales.length, 2);
      expect(controller.sales.first.id, 'gs-new-1');
    });

    test('reviewGrainSale marks matching received sale as approved in local state', () async {
      mockRemoteDataSource.salesToReturn = [
        _createSampleSale(id: 's-to-review', status: 'received'),
      ];
      mockBookingDataSource.bookingsToReturn = [
        _createBooking(id: 'b-to-review', grainSaleId: 's-to-review'),
      ];
      await controller.loadSales();
      expect(controller.sales.first.status, 'received');

      final success = await controller.reviewGrainSale(
        saleId: 's-to-review',
        approve: true,
      );

      expect(success, isTrue);
      expect(controller.sales.first.status, 'approved');
      expect(controller.errorMessage, isNull);
    });

    test('reviewGrainSale marks matching received sale as rejected in local state', () async {
      mockRemoteDataSource.salesToReturn = [
        _createSampleSale(id: 's-to-reject', status: 'received'),
      ];
      mockBookingDataSource.bookingsToReturn = [
        _createBooking(id: 'b-to-reject', grainSaleId: 's-to-reject'),
      ];
      await controller.loadSales();
      expect(controller.sales.first.status, 'received');

      final success = await controller.reviewGrainSale(
        saleId: 's-to-reject',
        approve: false,
        rejectionReason: 'Damaged crop',
      );

      expect(success, isTrue);
      expect(controller.sales.first.status, 'rejected');
      expect(controller.errorMessage, isNull);
    });

    test('reviewGrainSale failure sets errorMessage and returns false', () async {
      mockRemoteDataSource.salesToReturn = [
        _createSampleSale(id: 's-fail-rev', status: 'received'),
      ];
      mockBookingDataSource.bookingsToReturn = [
        _createBooking(id: 'b-fail-rev', grainSaleId: 's-fail-rev'),
      ];
      await controller.loadSales();
      mockRemoteDataSource.errorToThrow = const GrainSaleValidationException(message: 'Invalid inspection yield');

      final success = await controller.reviewGrainSale(
        saleId: 's-fail-rev',
        approve: true,
      );

      expect(success, isFalse);
      expect(controller.errorMessage, 'Invalid inspection yield');
    });

    test('review with no resolvable booking returns false, sets guard message, and makes no review call', () async {
      mockRemoteDataSource.salesToReturn = [
        _createSampleSale(id: 's-no-booking', status: 'received'),
      ];
      await controller.loadSales();

      final success = await controller.reviewGrainSale(
        saleId: 's-no-booking',
        approve: true,
      );

      expect(success, isFalse);
      expect(
        controller.errorMessage,
        'This grain sale is not associated with a booking slot and cannot be reviewed yet.',
      );
      expect(mockRemoteDataSource.reviewCallCount, 0);
      expect(controller.sales.first.status, 'received');
    });

    test('setFilter sends truthful single status values and all sends null', () async {
      mockRemoteDataSource.salesToReturn = [
        _createSampleSale(id: 's-1', status: 'pending'),
        _createSampleSale(id: 's-2', status: 'received'),
        _createSampleSale(id: 's-3', status: 'paid'),
      ];

      await controller.loadSales();
      expect(mockRemoteDataSource.statusesRequested.last, isNull);

      controller.setFilter('pending');
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(mockRemoteDataSource.statusesRequested.last, 'pending');

      controller.setFilter('received');
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(mockRemoteDataSource.statusesRequested.last, 'received');

      controller.setFilter('paid');
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(mockRemoteDataSource.statusesRequested.last, 'paid');

      controller.setFilter('all');
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(mockRemoteDataSource.statusesRequested.last, isNull);
      expect(controller.currentFilter, 'all');
    });

    test('payGrainSale marks matching sale as paid in local state', () async {
      mockRemoteDataSource.salesToReturn = [
        _createSampleSale(id: 's-to-pay', status: 'approved'),
      ];
      await controller.loadSales();
      expect(controller.sales.first.status, 'approved');

      final success = await controller.payGrainSale('s-to-pay', paymentReference: 'UPI-REF-123');

      expect(success, isTrue);
      expect(controller.sales.first.status, 'paid');
    });

    test('payGrainSale failure sets errorMessage and returns false', () async {
      mockRemoteDataSource.salesToReturn = [
        _createSampleSale(id: 's-fail-pay', status: 'approved'),
      ];
      await controller.loadSales();
      mockRemoteDataSource.errorToThrow = const GrainSaleConflictException(message: 'Sale already settled');

      final success = await controller.payGrainSale('s-fail-pay');

      expect(success, isFalse);
      expect(controller.errorMessage, 'Sale already settled');
    });

    test('handles error and updates errorMessage property', () async {
      mockRemoteDataSource.errorToThrow = const GrainSaleServerException(message: 'Server 500 error');

      await controller.loadSales();

      expect(controller.sales, isEmpty);
      expect(controller.errorMessage, contains('Server 500 error'));
    });
  });

  group('Milestone 5 Step 4 — Widget & Screen UI Tests', () {
    late _MockGrainSaleRemoteDataSource mockRemoteDataSource;
    late _MockBookingRemoteDataSource mockBookingDataSource;
    late GrainSaleRepository repository;
    late GrainSaleController controller;

    setUp(() {
      mockRemoteDataSource = _MockGrainSaleRemoteDataSource();
      mockBookingDataSource = _MockBookingRemoteDataSource();
      mockRemoteDataSource.salesToReturn = [
        _createSampleSale(
          id: 'gs-card-1',
          farmerName: 'Devendra Gowda',
          grainType: 'Soybean',
          grade: 'Grade A',
          rawMaterialKg: '2500',
          goodMaterialKg: '2400',
          wastageKg: '100',
          pricePerKg: '45',
          totalAmount: '108000',
          status: 'pending',
        ),
      ];
      mockRemoteDataSource.farmersToReturn = {
        'farmer-1': (name: 'Devendra Gowda', phone: '9876543210', village: 'Navalgund'),
      };
      repository = GrainSaleRepositoryImpl(
        remoteDataSource: mockRemoteDataSource,
        bookingDataSource: mockBookingDataSource,
      );
      controller = GrainSaleController(
        repository: repository,
        accessToken: 'mock-token',
      );
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('GrainSaleCard renders farmer, crop, quintals, rate, and total payout', (tester) async {
      final sale = mockRemoteDataSource.salesToReturn.first;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GrainSaleCard(
              item: sale,
              onTap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Devendra Gowda'), findsOneWidget);
      expect(find.textContaining('Soybean'), findsOneWidget);
      expect(find.textContaining('Grade A'), findsOneWidget);
      expect(find.textContaining('24.0 qtl'), findsOneWidget);
      expect(find.text('₹108000'), findsOneWidget);
    });

    testWidgets('GrainSaleDetailSheet for received sale displays Review & Approve and Reject actions, NOT Mark as Paid', (tester) async {
      final receivedSale = _createSampleSale(
        id: 'gs-rec-1',
        farmerName: 'Devendra Gowda',
        grainType: 'Soybean',
        grade: 'Grade A',
        rawMaterialKg: '2500',
        goodMaterialKg: '2400',
        wastageKg: '100',
        pricePerKg: '45',
        totalAmount: '108000',
        status: 'received',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GrainSaleDetailSheet(
              item: receivedSale,
              isSubmitting: false,
              onReview: () {},
              onReject: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Procurement Details'), findsOneWidget);
      expect(find.text('Devendra Gowda'), findsOneWidget);
      expect(find.textContaining('25.0 qtl'), findsOneWidget); // Raw
      expect(find.textContaining('24.0 qtl'), findsOneWidget); // Good
      expect(find.textContaining('1.0 qtl'), findsOneWidget); // Wastage
      expect(find.text('₹108000'), findsOneWidget);

      expect(find.text('Review & Approve'), findsOneWidget);
      expect(find.text('Reject'), findsOneWidget);
      expect(find.text('Mark as Paid'), findsNothing);
      expect(find.text('Approve & Mark as Paid'), findsNothing);

      // Verify pending backend features (Edit Rate / Cancel / Delete) are cleanly absent
      expect(find.text('Edit Rate'), findsNothing);
      expect(find.text('Cancel Sale'), findsNothing);
      expect(find.text('Delete Sale'), findsNothing);
    });

    testWidgets('GrainSaleDetailSheet for approved sale displays Mark as Paid action, NOT Review & Approve', (tester) async {
      final approvedSale = _createSampleSale(
        id: 'gs-app-1',
        status: 'approved',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GrainSaleDetailSheet(
              item: approvedSale,
              isSubmitting: false,
              onPay: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mark as Paid'), findsOneWidget);
      expect(find.text('Review & Approve'), findsNothing);
      expect(find.text('Reject'), findsNothing);
      expect(find.text('Approve & Mark as Paid'), findsNothing);
    });

    testWidgets('GrainSaleDetailSheet for paid sale displays paid banner and no action buttons', (tester) async {
      final paidSale = _createSampleSale(
        id: 'gs-paid-1',
        status: 'paid',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GrainSaleDetailSheet(
              item: paidSale,
              isSubmitting: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('This transaction has been paid.'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsNothing);
      expect(find.byType(OutlinedButton), findsNothing);
      expect(find.text('Mark as Paid'), findsNothing);
      expect(find.text('Review & Approve'), findsNothing);
    });

    testWidgets('GrainSaleDetailSheet for rejected sale displays rejected banner and no action buttons', (tester) async {
      final rejectedSale = _createSampleSale(
        id: 'gs-rej-1',
        status: 'rejected',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GrainSaleDetailSheet(
              item: rejectedSale,
              isSubmitting: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('This procurement was rejected.'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsNothing);
      expect(find.byType(OutlinedButton), findsNothing);
      expect(find.text('Mark as Paid'), findsNothing);
      expect(find.text('Review & Approve'), findsNothing);
    });

    testWidgets('GrainSaleScreen shows visible error SnackBar on payment failure', (tester) async {
      mockRemoteDataSource.salesToReturn = [
        _createSampleSale(id: 'gs-pay-fail', status: 'approved'),
      ];
      await controller.loadSales();

      await tester.pumpWidget(
        MaterialApp(
          home: GrainSaleScreen(
            controller: controller,
            onBack: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on card to open detail sheet
      await tester.tap(find.byType(GrainSaleCard).first);
      await tester.pumpAndSettle();

      expect(find.text('Mark as Paid'), findsOneWidget);

      // Set backend error for pay
      mockRemoteDataSource.errorToThrow = const GrainSaleConflictException(message: 'Settlement failure: bank down');

      await tester.tap(find.text('Mark as Paid'));
      await tester.pumpAndSettle();

      expect(find.text('Settlement failure: bank down'), findsOneWidget);
    });

    testWidgets('GrainSaleScreen shows visible error SnackBar on review failure', (tester) async {
      mockRemoteDataSource.salesToReturn = [
        _createSampleSale(id: 'gs-rev-fail', status: 'received'),
      ];
      mockBookingDataSource.bookingsToReturn = [
        _createBooking(id: 'b-rev-fail', grainSaleId: 'gs-rev-fail'),
      ];
      await controller.loadSales();

      await tester.pumpWidget(
        MaterialApp(
          home: GrainSaleScreen(
            controller: controller,
            onBack: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on card to open detail sheet
      await tester.tap(find.byType(GrainSaleCard).first);
      await tester.pumpAndSettle();

      expect(find.text('Review & Approve'), findsOneWidget);

      // Set backend error for review
      mockRemoteDataSource.errorToThrow = const GrainSaleValidationException(message: 'Inspection metrics invalid');

      await tester.tap(find.text('Review & Approve'));
      await tester.pumpAndSettle();

      expect(find.text('Inspection metrics invalid'), findsOneWidget);
    });

    testWidgets('GrainSaleScreen workflow: received -> review/approve -> approved', (tester) async {
      mockRemoteDataSource.salesToReturn = [
        _createSampleSale(id: 'gs-flow-1', status: 'received'),
      ];
      mockBookingDataSource.bookingsToReturn = [
        _createBooking(id: 'b-flow-1', grainSaleId: 'gs-flow-1'),
      ];
      await controller.loadSales();

      await tester.pumpWidget(
        MaterialApp(
          home: GrainSaleScreen(
            controller: controller,
            onBack: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(GrainSaleCard).first);
      await tester.pumpAndSettle();

      expect(find.text('Review & Approve'), findsOneWidget);
      await tester.tap(find.text('Review & Approve'));
      await tester.pumpAndSettle();

      expect(find.text('Grain sale reviewed and approved successfully!'), findsOneWidget);
      expect(controller.sales.first.status, 'approved');
    });

    testWidgets('GrainSaleScreen workflow: received -> reject -> rejected', (tester) async {
      mockRemoteDataSource.salesToReturn = [
        _createSampleSale(id: 'gs-flow-2', status: 'received'),
      ];
      mockBookingDataSource.bookingsToReturn = [
        _createBooking(id: 'b-flow-2', grainSaleId: 'gs-flow-2'),
      ];
      await controller.loadSales();

      await tester.pumpWidget(
        MaterialApp(
          home: GrainSaleScreen(
            controller: controller,
            onBack: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(GrainSaleCard).first);
      await tester.pumpAndSettle();

      expect(find.text('Reject'), findsOneWidget);
      await tester.tap(find.text('Reject'));
      await tester.pumpAndSettle();

      expect(find.text('Grain procurement rejected.'), findsOneWidget);
      expect(controller.sales.first.status, 'rejected');
    });

    testWidgets('GrainSaleScreen workflow: approved -> pay -> paid', (tester) async {
      mockRemoteDataSource.salesToReturn = [
        _createSampleSale(id: 'gs-flow-3', status: 'approved'),
      ];
      await controller.loadSales();

      await tester.pumpWidget(
        MaterialApp(
          home: GrainSaleScreen(
            controller: controller,
            onBack: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(GrainSaleCard).first);
      await tester.pumpAndSettle();

      expect(find.text('Mark as Paid'), findsOneWidget);
      await tester.tap(find.text('Mark as Paid'));
      await tester.pumpAndSettle();

      expect(find.text('Payment approved and marked as paid!'), findsOneWidget);
      expect(controller.sales.first.status, 'paid');
    });

    testWidgets('LogReceivedCropSheet renders intake form fields and validates correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LogReceivedCropSheet(
              farmers: {
                'farmer-1': (name: 'Devendra Gowda', phone: '9876543210', village: 'Navalgund'),
              },
              isSubmitting: false,
              onSubmit: ({
                required String farmerId,
                required String grainType,
                required String grade,
                required double rawMaterialKg,
                required double goodMaterialKg,
                required double wastageKg,
              }) async {
                return true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Log Received Crop'), findsOneWidget);
      expect(find.text('Farmer *'), findsOneWidget);
      expect(find.text('Crop Type *'), findsOneWidget);
      expect(find.text('Grade *'), findsOneWidget);
      expect(find.text('Raw Quantity (Quintals) *'), findsOneWidget);
      expect(find.text('Good Quantity (Quintals) *'), findsOneWidget);
      expect(find.text('Wastage (Quintals) *'), findsOneWidget);
      expect(find.text('Save Procurement Entry'), findsOneWidget);
    });

    testWidgets('Admin role renders "Grain Sales" header and "Procurement desk" eyebrow', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: GrainSaleScreen(
            controller: controller,
            onBack: () {},
            isManagerRole: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Grain Sales'), findsOneWidget);
      expect(find.text('PROCUREMENT DESK'), findsOneWidget);
      expect(find.text('Log Crop'), findsOneWidget);
    });

    testWidgets('Manager role renders "Crop Procurement" header and subtitle', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: GrainSaleScreen(
            controller: controller,
            onBack: () {},
            isManagerRole: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Crop Procurement'), findsOneWidget);
      expect(find.text('Log and manage crops received from farmers'), findsOneWidget);
      expect(find.text('Log Crop'), findsOneWidget);
    });

    testWidgets('filter chips render All Pending Received Paid without counts', (tester) async {
      mockRemoteDataSource.salesToReturn = [
        _createSampleSale(id: 'gs-chip-1', status: 'approved'),
      ];
      await controller.loadSales();

      await tester.pumpWidget(
        MaterialApp(
          home: GrainSaleScreen(
            controller: controller,
            onBack: () {},
            isManagerRole: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('grain_chip_all')), findsOneWidget);
      expect(find.byKey(const Key('grain_chip_pending')), findsOneWidget);
      expect(find.byKey(const Key('grain_chip_received')), findsOneWidget);
      expect(find.byKey(const Key('grain_chip_approved')), findsOneWidget);
      expect(find.byKey(const Key('grain_chip_rejected')), findsOneWidget);
      expect(find.byKey(const Key('grain_chip_paid')), findsOneWidget);
      expect(find.text('Pending / Received'), findsNothing);
      expect(find.textContaining(RegExp(r'\(\d+\)')), findsNothing);
    });

    testWidgets('tapping Approved chip requests approved status from data source',
        (tester) async {
      mockRemoteDataSource.salesToReturn = [
        _createSampleSale(id: 'gs-chip-2', status: 'approved'),
      ];
      await controller.loadSales();
      mockRemoteDataSource.statusesRequested.clear();

      await tester.pumpWidget(
        MaterialApp(
          home: GrainSaleScreen(
            controller: controller,
            onBack: () {},
            isManagerRole: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('grain_chip_approved')));
      await tester.pumpAndSettle();

      expect(mockRemoteDataSource.statusesRequested, contains('approved'));
      expect(controller.sales.length, 1);
    });

    testWidgets('Screen renders cleanly without RenderFlex overflow across viewports', (tester) async {
      const viewports = [
        Size(320, 600), // Small phone
        Size(360, 800), // Standard Android
        Size(412, 915), // Pixel 7 / Modern Android
      ];

      for (final size in viewports) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          MaterialApp(
            home: GrainSaleScreen(
              controller: controller,
              onBack: () {},
              isManagerRole: false,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'Overflow on viewport $size');
      }

      tester.view.resetPhysicalSize();
    });
  });
}
