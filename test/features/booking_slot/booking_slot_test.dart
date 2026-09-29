import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agriflow_admin/features/booking_slot/data/datasources/booking_remote_data_source.dart';
import 'package:agriflow_admin/features/booking_slot/data/repositories/booking_repository_impl.dart';
import 'package:agriflow_admin/features/booking_slot/domain/entities/booking_exception.dart';
import 'package:agriflow_admin/features/booking_slot/domain/entities/booking_item.dart';
import 'package:agriflow_admin/features/booking_slot/domain/entities/booking_pagination.dart';
import 'package:agriflow_admin/features/booking_slot/domain/entities/warehouse_item.dart';
import 'package:agriflow_admin/features/booking_slot/domain/repositories/booking_repository.dart';
import 'package:agriflow_admin/features/booking_slot/presentation/controllers/booking_controller.dart';
import 'package:agriflow_admin/features/booking_slot/presentation/screens/booking_slot_screen.dart';
import 'package:agriflow_admin/features/booking_slot/presentation/widgets/booking_card.dart';
import 'package:agriflow_admin/features/booking_slot/presentation/widgets/booking_detail_sheet.dart';
import 'package:agriflow_admin/features/booking_slot/presentation/widgets/date_selector_strip.dart';
import 'package:agriflow_admin/features/dashboard/shared/presentation/widgets/dashboard_state_views.dart';

// -------------------------------------------------------------
// Test Helpers & Mocks
// -------------------------------------------------------------

class _MockBookingRemoteDataSource implements BookingRemoteDataSource {
  List<BookingItem> bookingsToReturn = [];
  BookingPagination paginationToReturn = BookingPagination.empty();
  List<WarehouseItem> warehousesToReturn = [];
  Map<String, ({String name, String phone})> farmersToReturn = {};
  Exception? errorToThrow;
  bool failCatalog = false;

  int getBookingsCallCount = 0;
  int updateStatusCallCount = 0;
  String? lastUpdatedStatus;
  String? lastUpdatedId;
  int inspectCallCount = 0;
  double? lastInspectGoodKg;
  double? lastInspectBadKg;
  String? lastInspectBookingId;

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
    return (items: bookingsToReturn, pagination: paginationToReturn);
  }

  @override
  Future<BookingItem> updateBookingStatus({
    required String accessToken,
    required String bookingId,
    required String newStatus,
    String? notes,
  }) async {
    updateStatusCallCount++;
    lastUpdatedId = bookingId;
    lastUpdatedStatus = newStatus;
    if (errorToThrow != null) throw errorToThrow!;

    final existing = bookingsToReturn.firstWhere(
      (b) => b.id == bookingId,
      orElse: () => BookingItem(
        id: bookingId,
        farmerId: 'farmer-1',
        warehouseId: 'wh-1',
        bookingDate: '2026-09-24',
        grainType: 'Cotton (Kapus)',
        quantityKg: 2000,
        status: 'pending',
      ),
    );
    return existing.copyWithStatus(newStatus, newNotes: notes);
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
    inspectCallCount++;
    lastInspectBookingId = bookingId;
    lastInspectGoodKg = goodQuantityKg;
    lastInspectBadKg = badQuantityKg;
    if (errorToThrow != null) throw errorToThrow!;
  }

  @override
  Future<List<WarehouseItem>> getWarehouses({required String accessToken}) async {
    if (failCatalog) throw Exception('Failed to load warehouses');
    return warehousesToReturn;
  }

  @override
  Future<Map<String, ({String name, String phone})>> getFarmerLookup({
    required String accessToken,
  }) async {
    if (failCatalog) throw Exception('Failed to load farmers');
    return farmersToReturn;
  }
}

class _MockBookingRepository implements BookingRepository {
  List<BookingItem> itemsToReturn = [];
  BookingPagination paginationToReturn = BookingPagination.empty();
  Exception? errorToThrow;
  int getBookingsCallCount = 0;
  int updateStatusCallCount = 0;
  int inspectCallCount = 0;
  double? lastInspectGoodKg;
  double? lastInspectBadKg;
  String? lastFilter;
  String? lastSearch;
  int? lastPage;
  String? lastUpdatedId;
  String? lastUpdatedStatus;

  @override
  Future<({List<BookingItem> items, BookingPagination pagination})> getBookings({
    required String accessToken,
    int page = 1,
    int pageSize = 20,
    String? search,
    String? status,
  }) async {
    getBookingsCallCount++;
    lastPage = page;
    lastFilter = status;
    lastSearch = search;
    if (errorToThrow != null) throw errorToThrow!;
    return (items: itemsToReturn, pagination: paginationToReturn);
  }

  @override
  Future<BookingItem> updateBookingStatus({
    required String accessToken,
    required String bookingId,
    required String newStatus,
    String? notes,
  }) async {
    updateStatusCallCount++;
    lastUpdatedId = bookingId;
    lastUpdatedStatus = newStatus;
    if (errorToThrow != null) throw errorToThrow!;

    final existing = itemsToReturn.firstWhere(
      (b) => b.id == bookingId,
      orElse: () => BookingItem(
        id: bookingId,
        farmerId: 'farmer-1',
        warehouseId: 'wh-1',
        bookingDate: '2026-09-24',
        grainType: 'Cotton (Kapus)',
        quantityKg: 2000,
        status: 'pending',
      ),
    );
    return existing.copyWithStatus(newStatus, newNotes: notes);
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
    inspectCallCount++;
    lastInspectGoodKg = goodQuantityKg;
    lastInspectBadKg = badQuantityKg;
    if (errorToThrow != null) throw errorToThrow!;
  }

  @override
  Future<List<WarehouseItem>> getWarehouses({required String accessToken}) async => [];

  @override
  Future<Map<String, ({String name, String phone})>> getFarmerLookup({
    required String accessToken,
  }) async =>
      {};
}

BookingItem _createSampleBooking({
  String id = 'bk-001',
  String farmerId = 'farmer-01',
  String warehouseId = 'wh-01',
  String bookingDate = '2026-09-24',
  String grainType = 'Cotton (Kapus)',
  double quantityKg = 2500.0,
  String status = 'pending',
  String? notes,
  String? farmerName = 'Ramesh Kumar',
  String? farmerPhone = '9876543210',
  String? warehouseName = 'Kurnool Central Hub',
  String? warehouseAddress = 'NH-44, Kurnool, AP',
}) {
  return BookingItem(
    id: id,
    farmerId: farmerId,
    warehouseId: warehouseId,
    bookingDate: bookingDate,
    grainType: grainType,
    quantityKg: quantityKg,
    status: status,
    notes: notes,
    enrichedFarmerName: farmerName,
    enrichedFarmerPhone: farmerPhone,
    enrichedWarehouseName: warehouseName,
    enrichedWarehouseAddress: warehouseAddress,
  );
}

void main() {
  group('Booking Slot Domain & Entity Tests', () {
    test('BookingItem.fromJson parses backend JSON strictly', () {
      final json = {
        'id': '78579eb8-ebc4-46f4-97d2-ee27ff31a421',
        'farmer_id': '2258a1f6-49ac-466e-b793-70bb527912a7',
        'warehouse_id': '8812308e-eacf-4774-9473-7f534f2a594b',
        'warehouse_slot_id': 'd71975a6-d7a0-4d8e-83b4-872f31999a2b',
        'grain_sale_id': null,
        'booking_date': '2026-09-24',
        'grain_type': 'Cotton (Kapus)',
        'quantity_kg': '2000.00',
        'status': 'PENDING',
        'notes': 'Urgent unloading',
      };

      final item = BookingItem.fromJson(json);

      expect(item.id, '78579eb8-ebc4-46f4-97d2-ee27ff31a421');
      expect(item.farmerId, '2258a1f6-49ac-466e-b793-70bb527912a7');
      expect(item.warehouseId, '8812308e-eacf-4774-9473-7f534f2a594b');
      expect(item.warehouseSlotId, 'd71975a6-d7a0-4d8e-83b4-872f31999a2b');
      expect(item.grainSaleId, isNull);
      expect(item.bookingDate, '2026-09-24');
      expect(item.grainType, 'Cotton (Kapus)');
      expect(item.quantityKg, 2000.0);
      expect(item.quantityQtl, 20.0);
      expect(item.status, 'pending');
      expect(item.notes, 'Urgent unloading');
      expect(item.isPending, isTrue);
      expect(item.isConfirmed, isFalse);
      expect(item.isDelivered, isFalse);
      expect(item.isCancelled, isFalse);
    });

    test('BookingItem display helpers fall back safely without enrichment', () {
      final raw = BookingItem(
        id: '12345678',
        farmerId: 'far-12345678',
        warehouseId: 'wh-12345678',
        bookingDate: '2026-09-24',
        grainType: 'Wheat',
        quantityKg: 1000,
        status: 'confirmed',
      );

      expect(raw.displayName, contains('Farmer #'));
      expect(raw.displayPhone, isEmpty);
      expect(raw.displayWarehouse, contains('Warehouse #'));
      expect(raw.displayAddress, isEmpty);
      expect(raw.isConfirmed, isTrue);
      expect(raw.isPending, isFalse);
    });

    test('copyWithEnrichment keeps backend native fields separate from display fields', () {
      final raw = BookingItem.fromJson({
        'id': 'bk-1',
        'farmer_id': 'f-1',
        'warehouse_id': 'w-1',
        'booking_date': '2026-09-24',
        'grain_type': 'Maize',
        'quantity_kg': 500,
        'status': 'pending',
      });

      final enriched = raw.copyWithEnrichment(
        farmerName: 'Venkat Rao',
        farmerPhone: '9123456780',
        warehouseName: 'Warangal Hub',
        warehouseAddress: 'NH-163',
      );

      expect(enriched.id, 'bk-1');
      expect(enriched.farmerId, 'f-1');
      expect(enriched.warehouseId, 'w-1');
      expect(enriched.quantityKg, 500);
      expect(enriched.status, 'pending');

      expect(enriched.displayName, 'Venkat Rao');
      expect(enriched.displayPhone, '9123456780');
      expect(enriched.displayWarehouse, 'Warangal Hub');
      expect(enriched.displayAddress, 'NH-163');
    });

    test('BookingPagination correctly computes hasMore', () {
      final p1 = BookingPagination(page: 1, pageSize: 20, total: 45, totalPages: 3);
      expect(p1.hasMore, isTrue);

      final pLast = BookingPagination(page: 3, pageSize: 20, total: 45, totalPages: 3);
      expect(pLast.hasMore, isFalse);

      final empty = BookingPagination.empty();
      expect(empty.total, 0);
      expect(empty.hasMore, isFalse);
    });

    test('WarehouseItem.fromJson parses warehouse schema strictly', () {
      final json = {
        'id': 'wh-uuid-1',
        'name': 'Central Warehouse Hub',
        'address': 'NH-44, Kurnool, AP',
        'total_capacity_kg': '500000.00',
        'current_load_kg': '125000.00',
        'is_active': true,
      };

      final item = WarehouseItem.fromJson(json);
      expect(item.id, 'wh-uuid-1');
      expect(item.name, 'Central Warehouse Hub');
      expect(item.address, 'NH-44, Kurnool, AP');
      expect(item.totalCapacityKg, 500000.0);
      expect(item.currentLoadKg, 125000.0);
      expect(item.isActive, isTrue);
    });
  });

  group('Booking Slot Repository & Relationship Enrichment Tests', () {
    test('BookingRepositoryImpl enriches items using warehouses and farmer lookup', () async {
      final mockDataSource = _MockBookingRemoteDataSource();
      mockDataSource.bookingsToReturn = [
        BookingItem(
          id: 'bk-01',
          farmerId: 'f-01',
          warehouseId: 'w-01',
          bookingDate: '2026-09-24',
          grainType: 'Paddy',
          quantityKg: 3000,
          status: 'pending',
        ),
      ];
      mockDataSource.paginationToReturn = BookingPagination(page: 1, pageSize: 20, total: 1, totalPages: 1);
      mockDataSource.warehousesToReturn = [
        const WarehouseItem(
          id: 'w-01',
          name: 'Nizamabad Grain Hub',
          address: 'Main Road',
          totalCapacityKg: 100000,
          currentLoadKg: 20000,
          isActive: true,
        ),
      ];
      mockDataSource.farmersToReturn = {
        'f-01': (name: 'Rajesh Goud', phone: '9888877777'),
      };

      final repository = BookingRepositoryImpl(remoteDataSource: mockDataSource);
      final result = await repository.getBookings(accessToken: 'dummy-token');

      expect(result.items.length, 1);
      final item = result.items.first;
      expect(item.displayName, 'Rajesh Goud');
      expect(item.displayPhone, '9888877777');
      expect(item.displayWarehouse, 'Nizamabad Grain Hub');
      expect(item.displayAddress, 'Main Road');
    });

    test('BookingRepositoryImpl gracefully falls back if lookups fail', () async {
      final mockDataSource = _MockBookingRemoteDataSource();
      mockDataSource.failCatalog = true;
      mockDataSource.bookingsToReturn = [
        BookingItem(
          id: 'bk-01',
          farmerId: 'f-missing',
          warehouseId: 'w-missing',
          bookingDate: '2026-09-24',
          grainType: 'Cotton',
          quantityKg: 1500,
          status: 'pending',
        ),
      ];

      final repository = BookingRepositoryImpl(remoteDataSource: mockDataSource);
      final result = await repository.getBookings(accessToken: 'dummy-token');

      expect(result.items.length, 1);
      expect(result.items.first.displayName, contains('Farmer #'));
      expect(result.items.first.displayWarehouse, contains('Warehouse #'));
    });
  });

  group('Booking Controller Tests', () {
    test('loadBookings transitions from loading to success with items', () async {
      final mockRepo = _MockBookingRepository();
      mockRepo.itemsToReturn = [_createSampleBooking()];
      mockRepo.paginationToReturn = BookingPagination(page: 1, pageSize: 20, total: 1, totalPages: 1);

      final controller = BookingController(repository: mockRepo, accessToken: 'token');

      expect(controller.status, BookingViewStatus.initial);
      await controller.loadBookings();

      expect(controller.status, BookingViewStatus.success);
      expect(controller.bookings.length, 1);
      expect(controller.pagination.total, 1);
      expect(mockRepo.getBookingsCallCount, 1);
    });

    test('refreshBookings replaces dataset completely', () async {
      final mockRepo = _MockBookingRepository();
      mockRepo.itemsToReturn = [_createSampleBooking(id: 'item-1')];
      final controller = BookingController(repository: mockRepo, accessToken: 'token');
      await controller.loadBookings();
      expect(controller.bookings.first.id, 'item-1');

      // Update backend data and refresh
      mockRepo.itemsToReturn = [_createSampleBooking(id: 'item-2-replaced')];
      await controller.refreshBookings();

      expect(controller.bookings.length, 1);
      expect(controller.bookings.first.id, 'item-2-replaced');
    });

    test('loadMoreBookings appends data to current dataset', () async {
      final mockRepo = _MockBookingRepository();
      mockRepo.itemsToReturn = [_createSampleBooking(id: 'page1-item')];
      mockRepo.paginationToReturn = BookingPagination(page: 1, pageSize: 20, total: 40, totalPages: 2);

      final controller = BookingController(repository: mockRepo, accessToken: 'token');
      await controller.loadBookings();
      expect(controller.bookings.length, 1);

      mockRepo.itemsToReturn = [_createSampleBooking(id: 'page2-item')];
      mockRepo.paginationToReturn = BookingPagination(page: 2, pageSize: 20, total: 40, totalPages: 2);

      await controller.loadMoreBookings();

      expect(controller.bookings.length, 2);
      expect(controller.bookings[0].id, 'page1-item');
      expect(controller.bookings[1].id, 'page2-item');
      expect(mockRepo.lastPage, 2);
    });

    test('setFilter triggers reload with status parameter', () async {
      final mockRepo = _MockBookingRepository();
      final controller = BookingController(repository: mockRepo, accessToken: 'token');

      controller.setFilter('confirmed');
      await Future.delayed(Duration.zero);

      expect(controller.activeFilter, 'confirmed');
      expect(mockRepo.lastFilter, 'confirmed');
    });

    test('setDateFilter filters loaded bookings by date', () async {
      final mockRepo = _MockBookingRepository();
      mockRepo.itemsToReturn = [
        _createSampleBooking(id: 'b-today', bookingDate: '2026-09-24'),
        _createSampleBooking(id: 'b-tomorrow', bookingDate: '2026-09-25'),
      ];
      final controller = BookingController(repository: mockRepo, accessToken: 'token');
      await controller.loadBookings();
      expect(controller.bookings.length, 2);

      // Select 2026-09-24
      controller.setDateFilter(DateTime(2026, 9, 24));
      expect(controller.bookings.length, 1);
      expect(controller.bookings.first.id, 'b-today');

      // Clear date filter
      controller.setDateFilter(null);
      expect(controller.bookings.length, 2);
    });

    test('setSearch triggers reload with search query parameter', () async {
      final mockRepo = _MockBookingRepository();
      final controller = BookingController(repository: mockRepo, accessToken: 'token');

      controller.setSearch('Cotton');
      await Future.delayed(Duration.zero);

      expect(controller.searchQuery, 'Cotton');
      expect(mockRepo.lastSearch, 'Cotton');
    });

    test('updateStatus authoritatively updates status in place using backend response', () async {
      final mockRepo = _MockBookingRepository();
      mockRepo.itemsToReturn = [
        _createSampleBooking(id: 'bk-100', status: 'pending'),
      ];
      final controller = BookingController(repository: mockRepo, accessToken: 'token');
      await controller.loadBookings();
      expect(controller.bookings.first.isPending, isTrue);

      final success = await controller.updateStatus(bookingId: 'bk-100', newStatus: 'confirmed');

      expect(success, isTrue);
      expect(controller.bookings.first.status, 'confirmed');
      expect(controller.bookings.first.isConfirmed, isTrue);
      expect(mockRepo.lastUpdatedStatus, 'confirmed');
      expect(mockRepo.lastUpdatedId, 'bk-100');
    });

    test('handles 401/403/404/5xx exceptions explicitly', () async {
      final mockRepo = _MockBookingRepository();
      mockRepo.errorToThrow = BookingException('Session expired. Please log in again.', statusCode: 401);

      final controller = BookingController(repository: mockRepo, accessToken: 'token');
      await controller.loadBookings();

      expect(controller.status, BookingViewStatus.error);
      expect(controller.errorMessage, 'Session expired. Please log in again.');
    });
  });

  group('BookingSlotScreen UI & Widget Tests', () {
    testWidgets('Renders loading view when controller is loading or initial', (tester) async {
      final mockRepo = _MockBookingRepository();
      final controller = BookingController(repository: mockRepo, accessToken: 'token');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookingSlotScreen(
              controller: controller,
              onBack: () {},
            ),
          ),
        ),
      );

      expect(find.byType(DashboardLoadingView), findsOneWidget);
    });

    testWidgets('Renders error view when controller has error', (tester) async {
      final mockRepo = _MockBookingRepository();
      mockRepo.errorToThrow = BookingException('Network connection failed', statusCode: 0, isNetworkError: true);
      final controller = BookingController(repository: mockRepo, accessToken: 'token');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookingSlotScreen(
              controller: controller,
              onBack: () {},
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(DashboardErrorView), findsOneWidget);
      expect(find.text('Network connection failed'), findsOneWidget);
    });

    testWidgets('Renders complete Booking Slot screen matching HTML UX', (tester) async {
      final mockRepo = _MockBookingRepository();
      mockRepo.itemsToReturn = [
        _createSampleBooking(id: 'bk-1', farmerName: 'Ramesh Kumar', status: 'pending'),
      ];
      mockRepo.paginationToReturn = BookingPagination(page: 1, pageSize: 20, total: 1, totalPages: 1);

      final controller = BookingController(repository: mockRepo, accessToken: 'token');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookingSlotScreen(
              controller: controller,
              onBack: () {},
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Header
      expect(find.text('Booking Slots'), findsOneWidget);
      expect(find.text('Farmer delivery bookings'), findsOneWidget);

      // Date Selector Strip
      expect(find.byType(DateSelectorStrip), findsOneWidget);
      expect(find.text('All'), findsOneWidget);

      // Search bar
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search by farmer or grain...'), findsOneWidget);

      // Filter chips
      expect(find.widgetWithText(FilterChip, 'All (1)'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Pending'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Confirmed'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Cancelled'), findsOneWidget);

      // Card
      expect(find.byType(BookingCard), findsOneWidget);
      expect(find.text('Ramesh Kumar'), findsOneWidget);
      expect(find.text('Cotton (Kapus) · 25.00 Qtl (2500 kg)'), findsOneWidget);
      expect(find.text('Approve'), findsOneWidget);
      expect(find.text('Reject'), findsOneWidget);
    });

    testWidgets('Reject action triggers confirmation dialog with safe cancel', (tester) async {
      final mockRepo = _MockBookingRepository();
      mockRepo.itemsToReturn = [
        _createSampleBooking(id: 'bk-1', farmerName: 'Ramesh Kumar', status: 'pending'),
      ];
      final controller = BookingController(repository: mockRepo, accessToken: 'token');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookingSlotScreen(
              controller: controller,
              onBack: () {},
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap Reject button
      await tester.tap(find.text('Reject'));
      await tester.pumpAndSettle();

      // Verify Rejection Dialog
      expect(find.text('Reject Booking Slot?'), findsOneWidget);
      expect(find.textContaining('Are you sure you want to cancel the booking for Ramesh Kumar'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Confirm Reject'), findsOneWidget);

      // Tap Cancel - should dismiss without mutating
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(mockRepo.updateStatusCallCount, 0);
      expect(find.text('Reject Booking Slot?'), findsNothing);
    });

    testWidgets('Confirming Reject calls updateStatus with cancelled', (tester) async {
      final mockRepo = _MockBookingRepository();
      mockRepo.itemsToReturn = [
        _createSampleBooking(id: 'bk-1', farmerName: 'Ramesh Kumar', status: 'pending'),
      ];
      final controller = BookingController(repository: mockRepo, accessToken: 'token');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookingSlotScreen(
              controller: controller,
              onBack: () {},
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap Reject button
      await tester.tap(find.text('Reject'));
      await tester.pumpAndSettle();

      // Tap confirm Confirm Reject
      await tester.tap(find.text('Confirm Reject'));
      await tester.pumpAndSettle();

      expect(mockRepo.updateStatusCallCount, 1);
      expect(mockRepo.lastUpdatedStatus, 'cancelled');
      expect(mockRepo.lastUpdatedId, 'bk-1');
    });

    testWidgets('Tapping Approve calls updateStatus with confirmed directly', (tester) async {
      final mockRepo = _MockBookingRepository();
      mockRepo.itemsToReturn = [
        _createSampleBooking(id: 'bk-1', farmerName: 'Ramesh Kumar', status: 'pending'),
      ];
      final controller = BookingController(repository: mockRepo, accessToken: 'token');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookingSlotScreen(
              controller: controller,
              onBack: () {},
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap Approve button
      await tester.tap(find.text('Approve'));
      await tester.pumpAndSettle();

      expect(mockRepo.updateStatusCallCount, 1);
      expect(mockRepo.lastUpdatedStatus, 'confirmed');
      expect(mockRepo.lastUpdatedId, 'bk-1');
    });

    testWidgets('Tapping card opens BookingDetailSheet', (tester) async {
      final mockRepo = _MockBookingRepository();
      mockRepo.itemsToReturn = [
        _createSampleBooking(id: 'bk-1', farmerName: 'Ramesh Kumar', status: 'pending'),
      ];
      final controller = BookingController(repository: mockRepo, accessToken: 'token');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookingSlotScreen(
              controller: controller,
              onBack: () {},
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap card
      await tester.tap(find.byType(BookingCard));
      await tester.pumpAndSettle();

      expect(find.byType(BookingDetailSheet), findsOneWidget);
      expect(find.text('BOOKING DETAILS'), findsOneWidget);
      expect(find.text('Grain Type'), findsOneWidget);
      expect(find.text('Warehouse Hub'), findsOneWidget);
    });

    testWidgets('Screen renders with zero overflow on multiple mobile screen sizes', (tester) async {
      final screenSizes = [
        const Size(320, 568), // Small device (iPhone SE 1st gen)
        const Size(360, 640), // Standard small Android
        const Size(412, 860), // Medium Android
        const Size(412, 960), // Large Android
      ];

      for (final size in screenSizes) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        final mockRepo = _MockBookingRepository();
        mockRepo.itemsToReturn = [
          _createSampleBooking(id: 'bk-1', status: 'pending'),
          _createSampleBooking(id: 'bk-2', status: 'confirmed'),
        ];
        mockRepo.paginationToReturn = BookingPagination(page: 1, pageSize: 20, total: 2, totalPages: 1);

        final controller = BookingController(repository: mockRepo, accessToken: 'token');

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BookingSlotScreen(
                controller: controller,
                onBack: () {},
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Expect zero RenderFlex overflow errors
        expect(tester.takeException(), isNull);

        addTearDown(tester.view.resetPhysicalSize);
      }
    });
  });
}
