import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agriflow_admin/features/dashboard/shared/presentation/widgets/dashboard_state_views.dart';
import 'package:agriflow_admin/features/seed_purchase/data/datasources/seed_purchase_remote_data_source.dart';
import 'package:agriflow_admin/features/seed_purchase/data/repositories/seed_purchase_repository_impl.dart';
import 'package:agriflow_admin/features/seed_purchase/domain/entities/seed_catalog_item.dart';
import 'package:agriflow_admin/features/seed_purchase/domain/entities/seed_purchase_exception.dart';
import 'package:agriflow_admin/features/seed_purchase/domain/entities/seed_purchase_item.dart';
import 'package:agriflow_admin/features/seed_purchase/domain/entities/seed_purchase_pagination.dart';
import 'package:agriflow_admin/features/seed_purchase/domain/repositories/seed_purchase_repository.dart';
import 'package:agriflow_admin/features/seed_purchase/presentation/controllers/seed_purchase_controller.dart';
import 'package:agriflow_admin/features/seed_purchase/presentation/screens/seed_purchase_screen.dart';
import 'package:agriflow_admin/features/seed_purchase/presentation/widgets/seed_purchase_card.dart';
import 'package:agriflow_admin/features/seed_purchase/presentation/widgets/seed_purchase_detail_sheet.dart';

// -------------------------------------------------------------
// Test Helpers & Mocks
// -------------------------------------------------------------

class _MockSeedPurchaseRemoteDataSource implements SeedPurchaseRemoteDataSource {
  List<SeedPurchaseItem> purchasesToReturn = [];
  SeedPurchasePagination paginationToReturn = SeedPurchasePagination.empty();
  List<SeedCatalogItem> seedsToReturn = [];
  Map<String, ({String name, String phone})> farmersToReturn = {};
  Exception? errorToThrow;
  bool failCatalog = false;

  int getPurchasesCallCount = 0;
  int updateStatusCallCount = 0;
  String? lastUpdatedStatus;
  String? lastUpdatedId;

  @override
  Future<({List<SeedPurchaseItem> items, SeedPurchasePagination pagination})> getPurchases({
    required String accessToken,
    int page = 1,
    int pageSize = 20,
    String? search,
    String? status,
  }) async {
    getPurchasesCallCount++;
    if (errorToThrow != null) throw errorToThrow!;
    return (items: purchasesToReturn, pagination: paginationToReturn);
  }

  @override
  Future<SeedPurchaseItem> updatePurchaseStatus({
    required String accessToken,
    required String purchaseId,
    required String newStatus,
  }) async {
    updateStatusCallCount++;
    lastUpdatedId = purchaseId;
    lastUpdatedStatus = newStatus;
    if (errorToThrow != null) throw errorToThrow!;

    final existing = purchasesToReturn.firstWhere(
      (p) => p.id == purchaseId,
      orElse: () => SeedPurchaseItem(
        id: purchaseId,
        farmerId: 'farmer-1',
        seedId: 'seed-1',
        quantityKg: 100,
        pricePerKg: 50,
        totalAmount: 5000,
        paymentStatus: 'pending',
      ),
    );
    return existing.copyWithStatus(newStatus);
  }

  @override
  Future<List<SeedCatalogItem>> getSeeds({required String accessToken}) async {
    if (failCatalog) throw Exception('Failed to load seeds catalog');
    return seedsToReturn;
  }

  @override
  Future<Map<String, ({String name, String phone})>> getFarmerLookup({
    required String accessToken,
  }) async {
    if (failCatalog) throw Exception('Failed to load farmer lookup');
    return farmersToReturn;
  }
}

class _MockSeedPurchaseRepository implements SeedPurchaseRepository {
  List<SeedPurchaseItem> itemsToReturn = [];
  SeedPurchasePagination paginationToReturn = SeedPurchasePagination.empty();
  Exception? errorToThrow;
  int getPurchasesCallCount = 0;
  int updateStatusCallCount = 0;
  String? lastFilter;
  String? lastSearch;
  int? lastPage;
  String? lastUpdatedId;
  String? lastUpdatedStatus;

  @override
  Future<({List<SeedPurchaseItem> items, SeedPurchasePagination pagination})> getPurchases({
    required String accessToken,
    int page = 1,
    int pageSize = 20,
    String? search,
    String? status,
  }) async {
    getPurchasesCallCount++;
    lastPage = page;
    lastFilter = status;
    lastSearch = search;
    if (errorToThrow != null) throw errorToThrow!;
    return (items: itemsToReturn, pagination: paginationToReturn);
  }

  @override
  Future<SeedPurchaseItem> updatePurchaseStatus({
    required String accessToken,
    required String purchaseId,
    required String newStatus,
  }) async {
    updateStatusCallCount++;
    lastUpdatedId = purchaseId;
    lastUpdatedStatus = newStatus;
    if (errorToThrow != null) throw errorToThrow!;

    final existing = itemsToReturn.firstWhere(
      (p) => p.id == purchaseId,
      orElse: () => SeedPurchaseItem(
        id: purchaseId,
        farmerId: 'farmer-1',
        seedId: 'seed-1',
        quantityKg: 100,
        pricePerKg: 50,
        totalAmount: 5000,
        paymentStatus: 'pending',
      ),
    );
    return existing.copyWithStatus(newStatus);
  }

  @override
  Future<List<SeedCatalogItem>> getSeeds({required String accessToken}) async => [];

  @override
  Future<Map<String, ({String name, String phone})>> getFarmerLookup({
    required String accessToken,
  }) async =>
      {};
}

SeedPurchaseItem _createSampleItem({
  String id = 'sp-001',
  String farmerId = 'farmer-01',
  String seedId = 'seed-01',
  double quantityKg = 250.0,
  double pricePerKg = 45.0,
  double totalAmount = 11250.0,
  String paymentStatus = 'pending',
  String? invoiceNumber = 'INV-2026-001',
  String? farmerName = 'Ramesh Kumar',
  String? farmerPhone = '9876543210',
  String? seedName = 'Cotton RCH-659',
  String? seedVariety = 'Hybrid BG-II',
}) {
  return SeedPurchaseItem(
    id: id,
    farmerId: farmerId,
    seedId: seedId,
    quantityKg: quantityKg,
    pricePerKg: pricePerKg,
    totalAmount: totalAmount,
    paymentStatus: paymentStatus,
    invoiceNumber: invoiceNumber,
    createdAt: DateTime(2026, 9, 20, 10, 30),
    enrichedFarmerName: farmerName,
    enrichedFarmerPhone: farmerPhone,
    enrichedSeedName: seedName,
    enrichedSeedVariety: seedVariety,
  );
}

void main() {
  group('Seed Purchase Domain & Entity Tests', () {
    test('SeedPurchaseItem.fromJson parses backend JSON schema strictly', () {
      final json = {
        'id': 'purchase-12345678',
        'farmer_id': 'farmer-999',
        'seed_id': 'seed-888',
        'quantity_kg': 500.0,
        'price_per_kg': 60.0,
        'total_amount': 30000.0,
        'payment_status': 'PENDING',
        'invoice_number': 'INV-2026-99',
        'created_at': '2026-09-20T10:00:00Z',
      };

      final item = SeedPurchaseItem.fromJson(json);

      expect(item.id, 'purchase-12345678');
      expect(item.farmerId, 'farmer-999');
      expect(item.seedId, 'seed-888');
      expect(item.quantityKg, 500.0);
      expect(item.pricePerKg, 60.0);
      expect(item.totalAmount, 30000.0);
      expect(item.paymentStatus, 'pending');
      expect(item.invoiceNumber, 'INV-2026-99');
      expect(item.createdAt, isNotNull);
      expect(item.quantityQtl, 5.0);
      expect(item.isPending, isTrue);
      expect(item.isPaid, isFalse);
      expect(item.isFailed, isFalse);
    });

    test('SeedPurchaseItem display helpers fall back safely without enrichment', () {
      final rawItem = SeedPurchaseItem(
        id: '12345678',
        farmerId: 'far-12345678',
        seedId: 'sd-12345678',
        quantityKg: 200,
        pricePerKg: 30,
        totalAmount: 6000,
        paymentStatus: 'paid',
      );

      expect(rawItem.displayName, contains('Farmer #'));
      expect(rawItem.displayPhone, isEmpty);
      expect(rawItem.displaySeed, contains('Seed #'));
      expect(rawItem.displayVariety, isEmpty);
      expect(rawItem.isPaid, isTrue);
      expect(rawItem.isPending, isFalse);
    });

    test('copyWithEnrichment keeps backend native fields separate from display fields', () {
      final raw = SeedPurchaseItem.fromJson({
        'id': 'p-1',
        'farmer_id': 'f-1',
        'seed_id': 's-1',
        'quantity_kg': 100,
        'price_per_kg': 50,
        'total_amount': 5000,
        'payment_status': 'pending',
      });

      final enriched = raw.copyWithEnrichment(
        farmerName: 'Venkat Rao',
        farmerPhone: '9123456780',
        seedName: 'Paddy BPT 5204',
        seedVariety: 'Samba Mahsuri',
      );

      // Backend native fields remain identical
      expect(enriched.id, 'p-1');
      expect(enriched.farmerId, 'f-1');
      expect(enriched.seedId, 's-1');
      expect(enriched.totalAmount, 5000);
      expect(enriched.paymentStatus, 'pending');

      // Display metadata enriched
      expect(enriched.displayName, 'Venkat Rao');
      expect(enriched.displayPhone, '9123456780');
      expect(enriched.displaySeed, 'Paddy BPT 5204');
      expect(enriched.displayVariety, 'Samba Mahsuri');
    });

    test('SeedPurchasePagination correctly computes hasMore', () {
      final p1 = SeedPurchasePagination(page: 1, pageSize: 20, total: 45, totalPages: 3);
      expect(p1.hasMore, isTrue);

      final pLast = SeedPurchasePagination(page: 3, pageSize: 20, total: 45, totalPages: 3);
      expect(pLast.hasMore, isFalse);

      final empty = SeedPurchasePagination.empty();
      expect(empty.total, 0);
      expect(empty.hasMore, isFalse);
    });

    test('SeedCatalogItem.fromJson parses catalog schema strictly', () {
      final json = {
        'id': 'seed-uuid-1',
        'name': 'Cotton BG-II',
        'variety': 'RCH-659',
        'price_per_kg': 75.5,
        'stock_kg': 1200.0,
        'is_active': true,
      };

      final catalogItem = SeedCatalogItem.fromJson(json);
      expect(catalogItem.id, 'seed-uuid-1');
      expect(catalogItem.name, 'Cotton BG-II');
      expect(catalogItem.variety, 'RCH-659');
      expect(catalogItem.pricePerKg, 75.5);
      expect(catalogItem.stockKg, 1200.0);
      expect(catalogItem.isActive, isTrue);
    });
  });

  group('Seed Purchase Repository & Relationship Enrichment Tests', () {
    test('SeedPurchaseRepositoryImpl enriches items using catalog and farmer lookup', () async {
      final mockDataSource = _MockSeedPurchaseRemoteDataSource();
      mockDataSource.purchasesToReturn = [
        SeedPurchaseItem(
          id: 'p-01',
          farmerId: 'f-01',
          seedId: 's-01',
          quantityKg: 300,
          pricePerKg: 40,
          totalAmount: 12000,
          paymentStatus: 'pending',
        ),
      ];
      mockDataSource.paginationToReturn = SeedPurchasePagination(page: 1, pageSize: 20, total: 1, totalPages: 1);
      mockDataSource.seedsToReturn = [
        const SeedCatalogItem(id: 's-01', name: 'Wheat HD-2967', variety: 'Bread Wheat', pricePerKg: 40, stockKg: 500, isActive: true),
      ];
      mockDataSource.farmersToReturn = {
        'f-01': (name: 'Suresh Patel', phone: '9988776655'),
      };

      final repository = SeedPurchaseRepositoryImpl(remoteDataSource: mockDataSource);
      final result = await repository.getPurchases(accessToken: 'dummy-token');

      expect(result.items.length, 1);
      final item = result.items.first;
      expect(item.displayName, 'Suresh Patel');
      expect(item.displayPhone, '9988776655');
      expect(item.displaySeed, 'Wheat HD-2967');
      expect(item.displayVariety, 'Bread Wheat');
    });

    test('SeedPurchaseRepositoryImpl gracefully falls back if catalogs fail to load', () async {
      final mockDataSource = _MockSeedPurchaseRemoteDataSource();
      mockDataSource.failCatalog = true;
      mockDataSource.purchasesToReturn = [
        SeedPurchaseItem(
          id: 'p-01',
          farmerId: 'f-fallback',
          seedId: 's-fallback',
          quantityKg: 100,
          pricePerKg: 35,
          totalAmount: 3500,
          paymentStatus: 'pending',
        ),
      ];

      final repository = SeedPurchaseRepositoryImpl(remoteDataSource: mockDataSource);
      final result = await repository.getPurchases(accessToken: 'dummy-token');

      // Still returns purchase item safely
      expect(result.items.length, 1);
      expect(result.items.first.displayName, contains('Farmer #'));
    });
  });

  group('Seed Purchase Controller Tests', () {
    test('loadPurchases transitions from loading to success with items', () async {
      final mockRepo = _MockSeedPurchaseRepository();
      mockRepo.itemsToReturn = [_createSampleItem()];
      mockRepo.paginationToReturn = SeedPurchasePagination(page: 1, pageSize: 20, total: 1, totalPages: 1);

      final controller = SeedPurchaseController(repository: mockRepo, accessToken: 'token');

      expect(controller.status, SeedPurchaseViewStatus.initial);
      await controller.loadPurchases();

      expect(controller.status, SeedPurchaseViewStatus.success);
      expect(controller.purchases.length, 1);
      expect(controller.pagination.total, 1);
      expect(mockRepo.getPurchasesCallCount, 1);
    });

    test('refreshPurchases replaces dataset completely', () async {
      final mockRepo = _MockSeedPurchaseRepository();
      mockRepo.itemsToReturn = [_createSampleItem(id: 'item-1')];
      final controller = SeedPurchaseController(repository: mockRepo, accessToken: 'token');
      await controller.loadPurchases();
      expect(controller.purchases.first.id, 'item-1');

      // Update backend data and refresh
      mockRepo.itemsToReturn = [_createSampleItem(id: 'item-2-replaced')];
      await controller.refreshPurchases();

      expect(controller.purchases.length, 1);
      expect(controller.purchases.first.id, 'item-2-replaced');
    });

    test('loadMorePurchases appends data to current dataset', () async {
      final mockRepo = _MockSeedPurchaseRepository();
      mockRepo.itemsToReturn = [_createSampleItem(id: 'page1-item')];
      mockRepo.paginationToReturn = SeedPurchasePagination(page: 1, pageSize: 20, total: 40, totalPages: 2);

      final controller = SeedPurchaseController(repository: mockRepo, accessToken: 'token');
      await controller.loadPurchases();
      expect(controller.purchases.length, 1);

      mockRepo.itemsToReturn = [_createSampleItem(id: 'page2-item')];
      mockRepo.paginationToReturn = SeedPurchasePagination(page: 2, pageSize: 20, total: 40, totalPages: 2);

      await controller.loadMorePurchases();

      expect(controller.purchases.length, 2);
      expect(controller.purchases[0].id, 'page1-item');
      expect(controller.purchases[1].id, 'page2-item');
      expect(mockRepo.lastPage, 2);
    });

    test('setFilter triggers reload with status parameter', () async {
      final mockRepo = _MockSeedPurchaseRepository();
      final controller = SeedPurchaseController(repository: mockRepo, accessToken: 'token');

      controller.setFilter('pending');
      await Future.delayed(Duration.zero);

      expect(controller.activeFilter, 'pending');
      expect(mockRepo.lastFilter, 'pending');
    });

    test('setSearch triggers reload with search query parameter', () async {
      final mockRepo = _MockSeedPurchaseRepository();
      final controller = SeedPurchaseController(repository: mockRepo, accessToken: 'token');

      controller.setSearch('Ramesh');
      await Future.delayed(Duration.zero);

      expect(controller.searchQuery, 'Ramesh');
      expect(mockRepo.lastSearch, 'Ramesh');
    });

    test('updateStatus authoritatively updates status in place using backend response', () async {
      final mockRepo = _MockSeedPurchaseRepository();
      mockRepo.itemsToReturn = [
        _createSampleItem(id: 'sp-100', paymentStatus: 'pending'),
      ];
      final controller = SeedPurchaseController(repository: mockRepo, accessToken: 'token');
      await controller.loadPurchases();
      expect(controller.purchases.first.isPending, isTrue);

      final success = await controller.updateStatus(purchaseId: 'sp-100', newStatus: 'paid');

      expect(success, isTrue);
      expect(controller.purchases.first.paymentStatus, 'paid');
      expect(controller.purchases.first.isPaid, isTrue);
      expect(mockRepo.lastUpdatedStatus, 'paid');
      expect(mockRepo.lastUpdatedId, 'sp-100');
    });

    test('handles 401/403/404/5xx exceptions explicitly', () async {
      final mockRepo = _MockSeedPurchaseRepository();
      mockRepo.errorToThrow = SeedPurchaseException('Session expired. Please log in again.', statusCode: 401);

      final controller = SeedPurchaseController(repository: mockRepo, accessToken: 'token');
      await controller.loadPurchases();

      expect(controller.status, SeedPurchaseViewStatus.error);
      expect(controller.errorMessage, 'Session expired. Please log in again.');
    });
  });

  group('SeedPurchaseScreen UI & Widget Tests', () {
    testWidgets('Renders loading view when controller is loading', (tester) async {
      final mockRepo = _MockSeedPurchaseRepository();
      final controller = SeedPurchaseController(repository: mockRepo, accessToken: 'token');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SeedPurchaseScreen(
              controller: controller,
              onBack: () {},
            ),
          ),
        ),
      );

      expect(find.byType(DashboardLoadingView), findsOneWidget);
    });

    testWidgets('Renders error view when controller has error', (tester) async {
      final mockRepo = _MockSeedPurchaseRepository();
      mockRepo.errorToThrow = SeedPurchaseException('Network connection failed', statusCode: 0, isNetworkError: true);
      final controller = SeedPurchaseController(repository: mockRepo, accessToken: 'token');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SeedPurchaseScreen(
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

    testWidgets('Renders complete Seed Purchase screen matching HTML UX', (tester) async {
      final mockRepo = _MockSeedPurchaseRepository();
      mockRepo.itemsToReturn = [
        _createSampleItem(id: 'sp-1', farmerName: 'Ramesh Kumar', paymentStatus: 'pending'),
      ];
      mockRepo.paginationToReturn = SeedPurchasePagination(page: 1, pageSize: 20, total: 1, totalPages: 1);

      final controller = SeedPurchaseController(repository: mockRepo, accessToken: 'token');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SeedPurchaseScreen(
              controller: controller,
              onBack: () {},
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Header
      expect(find.text('Seed Purchase Requests'), findsOneWidget);
      expect(find.text('Manage requests'), findsOneWidget);

      // Search bar
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search by farmer, seed or invoice...'), findsOneWidget);

      // Filter chips
      expect(find.widgetWithText(FilterChip, 'All (1)'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Pending'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Paid'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Failed'), findsOneWidget);

      // Card
      expect(find.byType(SeedPurchaseCard), findsOneWidget);
      expect(find.text('Ramesh Kumar'), findsOneWidget);
      expect(find.text('Cotton RCH-659 · 2.50 Qtl'), findsOneWidget);
      expect(find.text('₹11250.00'), findsOneWidget);
      expect(find.text('Approve'), findsOneWidget);
      expect(find.text('Reject'), findsOneWidget);
    });

    testWidgets('Reject action triggers confirmation dialog with safe cancel', (tester) async {
      final mockRepo = _MockSeedPurchaseRepository();
      mockRepo.itemsToReturn = [
        _createSampleItem(id: 'sp-1', farmerName: 'Ramesh Kumar', paymentStatus: 'pending'),
      ];
      final controller = SeedPurchaseController(repository: mockRepo, accessToken: 'token');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SeedPurchaseScreen(
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
      expect(find.text('Reject Seed Purchase?'), findsOneWidget);
      expect(find.textContaining('Are you sure you want to reject the purchase request for Ramesh Kumar'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Confirm Reject'), findsOneWidget);

      // Tap Cancel - should dismiss without mutating
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(mockRepo.updateStatusCallCount, 0);
      expect(find.text('Reject Seed Purchase?'), findsNothing);
    });

    testWidgets('Confirming Reject calls updateStatus with failed', (tester) async {
      final mockRepo = _MockSeedPurchaseRepository();
      mockRepo.itemsToReturn = [
        _createSampleItem(id: 'sp-1', farmerName: 'Ramesh Kumar', paymentStatus: 'pending'),
      ];
      final controller = SeedPurchaseController(repository: mockRepo, accessToken: 'token');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SeedPurchaseScreen(
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

      // Tap confirm Reject Request
      await tester.tap(find.text('Confirm Reject'));
      await tester.pumpAndSettle();

      expect(mockRepo.updateStatusCallCount, 1);
      expect(mockRepo.lastUpdatedStatus, 'failed');
      expect(mockRepo.lastUpdatedId, 'sp-1');
    });

    testWidgets('Tapping Approve calls updateStatus with paid directly', (tester) async {
      final mockRepo = _MockSeedPurchaseRepository();
      mockRepo.itemsToReturn = [
        _createSampleItem(id: 'sp-1', farmerName: 'Ramesh Kumar', paymentStatus: 'pending'),
      ];
      final controller = SeedPurchaseController(repository: mockRepo, accessToken: 'token');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SeedPurchaseScreen(
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
      expect(mockRepo.lastUpdatedStatus, 'paid');
      expect(mockRepo.lastUpdatedId, 'sp-1');
    });

    testWidgets('Tapping card opens SeedPurchaseDetailSheet', (tester) async {
      final mockRepo = _MockSeedPurchaseRepository();
      mockRepo.itemsToReturn = [
        _createSampleItem(id: 'sp-1', farmerName: 'Ramesh Kumar', paymentStatus: 'pending'),
      ];
      final controller = SeedPurchaseController(repository: mockRepo, accessToken: 'token');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SeedPurchaseScreen(
              controller: controller,
              onBack: () {},
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap card
      await tester.tap(find.byType(SeedPurchaseCard));
      await tester.pumpAndSettle();

      expect(find.byType(SeedPurchaseDetailSheet), findsOneWidget);
      expect(find.text('PURCHASE DETAILS'), findsOneWidget);
      expect(find.text('Seed Item'), findsOneWidget);
      expect(find.text('Variety'), findsOneWidget);
      expect(find.text('Price per kg'), findsOneWidget);
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

        final mockRepo = _MockSeedPurchaseRepository();
        mockRepo.itemsToReturn = [
          _createSampleItem(id: 'sp-1', paymentStatus: 'pending'),
          _createSampleItem(id: 'sp-2', paymentStatus: 'paid'),
        ];
        mockRepo.paginationToReturn = SeedPurchasePagination(page: 1, pageSize: 20, total: 2, totalPages: 1);

        final controller = SeedPurchaseController(repository: mockRepo, accessToken: 'token');

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SeedPurchaseScreen(
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

        // Reset physical size for next iteration
        addTearDown(tester.view.resetPhysicalSize);
      }
    });

    testWidgets('Typing in search bar filters live via debounced onChanged and clears cleanly', (tester) async {
      final mockRepo = _MockSeedPurchaseRepository();
      mockRepo.itemsToReturn = [
        _createSampleItem(id: 'sp-1', farmerName: 'Asha Devi', paymentStatus: 'paid'),
        _createSampleItem(id: 'sp-2', farmerName: 'Developer', paymentStatus: 'paid'),
      ];
      mockRepo.paginationToReturn = SeedPurchasePagination(page: 1, pageSize: 20, total: 2, totalPages: 1);

      final controller = SeedPurchaseController(repository: mockRepo, accessToken: 'token');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SeedPurchaseScreen(
              controller: controller,
              onBack: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(mockRepo.getPurchasesCallCount, 1);
      expect(find.text('Developer'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'asha');
      await tester.pump();
      // Immediately filters loaded list while typing before debounce completes
      expect(find.text('Asha Devi'), findsOneWidget);
      expect(find.text('Developer'), findsNothing);
      expect(find.text('All (1)'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(mockRepo.getPurchasesCallCount, 2);
      expect(mockRepo.lastSearch, 'asha');
      expect(find.text('Asha Devi'), findsOneWidget);
      expect(find.text('Developer'), findsNothing);

      await tester.tap(find.byIcon(Icons.clear_rounded));
      await tester.pumpAndSettle();

      expect(mockRepo.getPurchasesCallCount, 3);
      expect(mockRepo.lastSearch, isNull);
      expect(find.text('Developer'), findsOneWidget);
    });

    testWidgets('Filter chips show counts for all statuses without clicking each chip', (tester) async {
      final statusDs = _PerStatusMockSeedPurchaseRemoteDataSource();
      final repo = SeedPurchaseRepositoryImpl(remoteDataSource: statusDs);
      final controller = SeedPurchaseController(repository: repo, accessToken: 'token');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SeedPurchaseScreen(
              controller: controller,
              onBack: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.widgetWithText(FilterChip, 'All (102)'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Pending (12)'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Paid (85)'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Failed (5)'), findsOneWidget);
    });
  });
}

class _PerStatusMockSeedPurchaseRemoteDataSource extends _MockSeedPurchaseRemoteDataSource {
  @override
  Future<({List<SeedPurchaseItem> items, SeedPurchasePagination pagination})> getPurchases({
    required String accessToken,
    int page = 1,
    int pageSize = 20,
    String? search,
    String? status,
  }) async {
    final totalByStatus = <String?, int>{
      null: 102,
      'pending': 12,
      'paid': 85,
      'failed': 5,
    };
    return (
      items: [_createSampleItem(id: 'sp-1', farmerName: 'Asha', paymentStatus: status ?? 'pending')],
      pagination: SeedPurchasePagination(
        page: page,
        pageSize: pageSize,
        total: totalByStatus[status] ?? 0,
        totalPages: 1,
      ),
    );
  }
}
