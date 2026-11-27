import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:agriflow_admin/core/models/user_role.dart';
import 'package:agriflow_admin/features/auth/domain/entities/auth_session.dart';
import 'package:agriflow_admin/features/auth/domain/entities/auth_user.dart';
import 'package:agriflow_admin/features/admin/presentation/admin_shell.dart';
import 'package:agriflow_admin/features/manager/presentation/manager_shell.dart';

import 'package:agriflow_admin/features/billing/data/datasources/billing_remote_data_source.dart';
import 'package:agriflow_admin/features/billing/data/datasources/fast_api_billing_remote_data_source.dart';
import 'package:agriflow_admin/features/billing/data/repositories/billing_repository_impl.dart';
import 'package:agriflow_admin/features/billing/domain/entities/billing_exception.dart';
import 'package:agriflow_admin/features/billing/domain/entities/billing_metrics.dart';
import 'package:agriflow_admin/features/billing/domain/entities/billing_pagination.dart';
import 'package:agriflow_admin/features/billing/domain/entities/billing_transaction_item.dart';
import 'package:agriflow_admin/features/billing/domain/repositories/billing_repository.dart';
import 'package:agriflow_admin/features/billing/presentation/controllers/billing_controller.dart';
import 'package:agriflow_admin/features/billing/presentation/screens/billing_screen.dart';
import 'package:agriflow_admin/features/billing/presentation/widgets/billing_card.dart';
import 'package:agriflow_admin/features/billing/presentation/widgets/billing_metrics_grid.dart';
import 'package:agriflow_admin/features/billing/presentation/widgets/billing_receipt_sheet.dart';
import 'package:agriflow_admin/features/billing/presentation/widgets/log_transaction_sheet.dart';

// -------------------------------------------------------------
// Mock Data Source for Unit & Widget Tests
// -------------------------------------------------------------

class _MockBillingRemoteDataSource implements BillingRemoteDataSource {
  List<BillingTransactionItem> transactionsToReturn = [];
  BillingPagination paginationToReturn = const BillingPagination(
    page: 1,
    pageSize: 20,
    total: 0,
    totalPages: 1,
  );
  Map<String, ({String name, String phone, String? village})> farmersToReturn = {};
  Exception? errorToThrow;

  int getTransactionsCallCount = 0;
  int createTransactionCallCount = 0;
  int payTransactionCallCount = 0;
  int getFarmersCallCount = 0;
  String? lastPaidId;
  String? lastPaidDescription;
  final List<String?> statusesRequested = [];

  @override
  Future<({List<BillingTransactionItem> items, BillingPagination pagination})> getTransactions({
    required String accessToken,
    int page = 1,
    int pageSize = 20,
    String? search,
    String? referenceType,
    String? direction,
    String? status,
    String? fromDate,
    String? toDate,
    String? sort,
    String? order,
  }) async {
    getTransactionsCallCount++;
    statusesRequested.add(status);
    if (errorToThrow != null) throw errorToThrow!;

    var filtered = List<BillingTransactionItem>.from(transactionsToReturn);
    if (status != null && status != 'all') {
      filtered = filtered.where((t) => t.status.toLowerCase() == status.toLowerCase()).toList();
    }
    if (referenceType != null && referenceType != 'all') {
      filtered = filtered.where((t) => t.referenceType.toLowerCase() == referenceType.toLowerCase()).toList();
    }
    if (direction != null && direction != 'all') {
      filtered = filtered.where((t) => t.direction.toLowerCase() == direction.toLowerCase()).toList();
    }
    if (search != null && search.isNotEmpty) {
      final q = search.toLowerCase();
      filtered = filtered.where((t) =>
          t.displayInvoiceNumber.toLowerCase().contains(q) ||
          t.displayFarmerName.toLowerCase().contains(q) ||
          (t.description?.toLowerCase().contains(q) ?? false)).toList();
    }

    return (items: filtered, pagination: paginationToReturn.copyWith(total: filtered.length));
  }

  @override
  Future<BillingTransactionItem> createTransaction({
    required String accessToken,
    required String farmerId,
    required double amount,
    required String direction,
    required String referenceType,
    String? description,
  }) async {
    createTransactionCallCount++;
    if (errorToThrow != null) throw errorToThrow!;

    final created = BillingTransactionItem(
      id: 'tx-created-$createTransactionCallCount',
      referenceType: referenceType,
      farmerId: farmerId,
      amount: amount,
      direction: direction,
      status: 'pending',
      description: description,
      invoiceNumber: 'INV-2026-NEW',
      createdAt: DateTime.now(),
    );
    transactionsToReturn.insert(0, created);
    return created;
  }

  @override
  Future<BillingTransactionItem> payTransaction({
    required String accessToken,
    required String transactionId,
    String? description,
  }) async {
    payTransactionCallCount++;
    lastPaidId = transactionId;
    lastPaidDescription = description;
    if (errorToThrow != null) throw errorToThrow!;

    final index = transactionsToReturn.indexWhere((t) => t.id == transactionId);
    if (index != -1) {
      final updated = transactionsToReturn[index].copyWith(
        status: 'completed',
        description: description ?? transactionsToReturn[index].description,
      );
      transactionsToReturn[index] = updated;
      return updated;
    }

    return BillingTransactionItem(
      id: transactionId,
      referenceType: 'billing',
      farmerId: 'farmer-1',
      amount: 1500,
      direction: 'credit',
      status: 'completed',
      description: description,
      invoiceNumber: 'INV-1001',
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<Map<String, ({String name, String phone, String? village})>> getFarmers({
    required String accessToken,
  }) async {
    getFarmersCallCount++;
    if (errorToThrow != null) throw errorToThrow!;
    return farmersToReturn;
  }
}

// -------------------------------------------------------------
// Sample Test Data
// -------------------------------------------------------------

final sampleTransactionCredit = BillingTransactionItem(
  id: 'tx-101',
  referenceType: 'seed_purchase',
  referenceId: 'ref-sp-01',
  farmerId: 'farmer-101',
  amount: 4500.0,
  direction: 'credit',
  status: 'completed',
  description: 'Purchased 150kg Wheat Hybrid seeds',
  invoiceNumber: 'INV-2026-001',
  createdAt: DateTime(2026, 9, 25, 14, 30),
  enrichedFarmerName: 'Ramesh Patel',
  enrichedFarmerPhone: '+91 98765 43210',
  enrichedFarmerVillage: 'Nashik Sector 4',
);

final sampleTransactionDebit = BillingTransactionItem(
  id: 'tx-102',
  referenceType: 'grain_sale',
  referenceId: 'ref-gs-02',
  farmerId: 'farmer-102',
  amount: 18500.0,
  direction: 'debit',
  status: 'pending',
  description: 'Procured 50 quintals Grade A Soybeans',
  invoiceNumber: 'INV-2026-002',
  createdAt: DateTime(2026, 9, 26, 11, 00),
  enrichedFarmerName: 'Suresh Kumar',
  enrichedFarmerPhone: '+91 98222 11111',
  enrichedFarmerVillage: 'Pune Rural',
);

final sampleTransactionService = BillingTransactionItem(
  id: 'tx-103',
  referenceType: 'billing',
  farmerId: 'farmer-103',
  amount: 1200.0,
  direction: 'credit',
  status: 'failed',
  description: 'Custom harvest machinery rental',
  invoiceNumber: 'INV-2026-003',
  createdAt: DateTime(2026, 9, 27, 9, 15),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Milestone 5 Step 8 — Domain Entity Unit Tests', () {
    test('BillingTransactionItem parses complete JSON payload cleanly', () {
      final json = {
        'id': 'tx-abc-1',
        'reference_type': 'seed_purchase',
        'reference_id': 'sp-99',
        'farmer_id': 'f-88',
        'amount': 2500.50,
        'direction': 'credit',
        'status': 'completed',
        'description': 'Test invoice item',
        'invoice_number': 'INV-9999',
        'created_at': '2026-09-25T10:00:00.000Z',
      };

      final item = BillingTransactionItem.fromJson(json);

      expect(item.id, 'tx-abc-1');
      expect(item.referenceType, 'seed_purchase');
      expect(item.referenceId, 'sp-99');
      expect(item.farmerId, 'f-88');
      expect(item.amount, 2500.50);
      expect(item.direction, 'credit');
      expect(item.status, 'completed');
      expect(item.description, 'Test invoice item');
      expect(item.invoiceNumber, 'INV-9999');
      expect(item.displayInvoiceNumber, 'INV-9999');
      expect(item.isCredit, isTrue);
      expect(item.isDebit, isFalse);
      expect(item.isCompleted, isTrue);
      expect(item.isPending, isFalse);
      expect(item.displayReferenceType, 'Seed Purchase');
    });

    test('BillingTransactionItem handles string amounts and null fields gracefully', () {
      final json = {
        'id': 'tx-abc-2',
        'farmer_id': 'f-123456789',
        'amount': '3200',
        'direction': 'debit',
        'status': 'pending',
      };

      final item = BillingTransactionItem.fromJson(json);

      expect(item.id, 'tx-abc-2');
      expect(item.amount, 3200.0);
      expect(item.referenceType, 'other');
      expect(item.referenceId, isNull);
      expect(item.description, isNull);
      expect(item.invoiceNumber, isNull);
      expect(item.displayInvoiceNumber, 'INV-TX-ABC-2');
      expect(item.displayFarmerName, 'Farmer #f-123456');
      expect(item.farmerInitials, 'TX');
      expect(item.isDebit, isTrue);
      expect(item.isPending, isTrue);
    });

    test('BillingMetrics computes aggregates from transaction items safely', () {
      final items = [
        sampleTransactionCredit, // 4500 credit, completed
        sampleTransactionDebit, // 18500 debit, pending
        sampleTransactionService, // 1200 credit, failed
      ];

      final metrics = BillingMetrics.fromTransactions(items, totalCount: 3);

      expect(metrics.totalInvoices, 3);
      expect(metrics.totalCollected, 4500.0 + 1200.0);
      expect(metrics.totalPayouts, 18500.0);
      expect(metrics.pendingAmount, 18500.0);
      expect(metrics.pendingCount, 1);
      expect(metrics.displayTotalInvoices, '3');
      expect(metrics.displayPendingCount, '1');
    });

    test('BillingPagination parses json and evaluates hasMore correctly', () {
      final json = {
        'page': 1,
        'page_size': 20,
        'total': 45,
        'total_pages': 3,
      };

      final pagination = BillingPagination.fromJson(json);

      expect(pagination.page, 1);
      expect(pagination.pageSize, 20);
      expect(pagination.total, 45);
      expect(pagination.totalPages, 3);
      expect(pagination.hasMore, isTrue);

      final lastPage = pagination.copyWith(page: 3);
      expect(lastPage.hasMore, isFalse);
    });

    test('BillingException hierarchy maps status codes correctly', () {
      expect(const BillingUnauthorizedException().statusCode, 401);
      expect(const BillingForbiddenException().statusCode, 403);
      expect(const BillingNotFoundException().statusCode, 404);
      expect(const BillingConflictException().statusCode, 409);
      expect(const BillingValidationException(message: 'Invalid').statusCode, 422);
      expect(const BillingServerException().statusCode, 500);
      expect(const BillingException(message: 'Network issue', isNetworkError: true).isNetworkError, isTrue);
    });
  });

  group('Milestone 5 Step 8 — FastAPI Remote Data Source Tests', () {
    test('getTransactions performs GET /transactions with query parameters', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/v1/transactions');
        expect(request.url.queryParameters['page'], '2');
        expect(request.url.queryParameters['page_size'], '15');
        expect(request.url.queryParameters['status'], 'pending');
        expect(request.url.queryParameters['direction'], 'credit');
        expect(request.headers['Authorization'], 'Bearer test_token');

        final responseBody = {
          'data': [
            {
              'id': 'tx-101',
              'reference_type': 'seed_purchase',
              'farmer_id': 'f-1',
              'amount': 5000,
              'direction': 'credit',
              'status': 'pending',
              'invoice_number': 'INV-101',
              'created_at': '2026-09-25T12:00:00Z',
            }
          ],
          'pagination': {
            'page': 2,
            'page_size': 15,
            'total': 25,
            'total_pages': 2,
          }
        };

        return http.Response(jsonEncode(responseBody), 200, headers: {'content-type': 'application/json'});
      });

      final dataSource = FastApiBillingRemoteDataSource(client: mockClient);
      final result = await dataSource.getTransactions(
        accessToken: 'test_token',
        page: 2,
        pageSize: 15,
        status: 'pending',
        direction: 'credit',
      );

      expect(result.items.length, 1);
      expect(result.items.first.id, 'tx-101');
      expect(result.pagination.total, 25);
    });

    test('createTransaction sends POST /transactions with payload and returns item', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/v1/transactions');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['farmer_id'], 'farmer-101');
        expect(body['amount'], '5000.00');
        expect(body['direction'], 'credit');
        expect(body['reference_type'], 'seed_purchase');
        expect(body['description'], 'seed sale for 5000');

        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'id': 'tx-new-1',
              'reference_type': 'seed_purchase',
              'farmer_id': 'farmer-101',
              'amount': '5000.00',
              'direction': 'credit',
              'status': 'pending',
              'description': 'seed sale for 5000',
              'invoice_number': 'INV-20261127-ABCD1234',
              'created_at': '2026-11-27T12:00:00Z',
            },
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      });

      final dataSource = FastApiBillingRemoteDataSource(client: mockClient);
      final created = await dataSource.createTransaction(
        accessToken: 'test_token',
        farmerId: 'farmer-101',
        amount: 5000,
        direction: 'credit',
        referenceType: 'seed_purchase',
        description: 'seed sale for 5000',
      );

      expect(created.id, 'tx-new-1');
      expect(created.amount, 5000.0);
      expect(created.invoiceNumber, 'INV-20261127-ABCD1234');
      expect(created.status, 'pending');
    });

    test('payTransaction sends PATCH /transactions/{id}/pay with description', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'PATCH');
        expect(request.url.path, '/api/v1/transactions/tx-101/pay');
        final body = jsonDecode(request.body);
        expect(body['description'], 'NEFT #12345');

        final responseBody = {
          'data': {
            'id': 'tx-101',
            'reference_type': 'seed_purchase',
            'farmer_id': 'f-1',
            'amount': 5000,
            'direction': 'credit',
            'status': 'completed',
            'description': 'NEFT #12345',
            'invoice_number': 'INV-101',
            'created_at': '2026-09-25T12:00:00Z',
          }
        };

        return http.Response(jsonEncode(responseBody), 200);
      });

      final dataSource = FastApiBillingRemoteDataSource(client: mockClient);
      final updated = await dataSource.payTransaction(
        accessToken: 'test_token',
        transactionId: 'tx-101',
        description: 'NEFT #12345',
      );

      expect(updated.status, 'completed');
      expect(updated.description, 'NEFT #12345');
    });

    test('getTransactions throws BillingUnauthorizedException on 401 response', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'detail': 'Token expired'}), 401);
      });

      final dataSource = FastApiBillingRemoteDataSource(client: mockClient);

      expect(
        () => dataSource.getTransactions(accessToken: 'bad_token'),
        throwsA(isA<BillingUnauthorizedException>()),
      );
    });

    test('getTransactions throws BillingForbiddenException on 403 response', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'detail': 'Permission denied'}), 403);
      });

      final dataSource = FastApiBillingRemoteDataSource(client: mockClient);

      expect(
        () => dataSource.getTransactions(accessToken: 'low_priv_token'),
        throwsA(isA<BillingForbiddenException>()),
      );
    });
  });

  group('Milestone 5 Step 8 — Repository Implementation Tests', () {
    test('BillingRepositoryImpl gets transactions and calculates BillingMetrics', () async {
      final mockDs = _MockBillingRemoteDataSource();
      mockDs.transactionsToReturn = [sampleTransactionCredit, sampleTransactionDebit];
      mockDs.paginationToReturn = const BillingPagination(page: 1, pageSize: 20, total: 2, totalPages: 1);

      final repository = BillingRepositoryImpl(remoteDataSource: mockDs);
      final result = await repository.getTransactions(accessToken: 'token');

      expect(result.items.length, 2);
      expect(result.metrics.totalInvoices, 2);
      expect(result.metrics.totalCollected, 4500.0);
      expect(result.metrics.totalPayouts, 18500.0);
    });
  });

  group('Milestone 5 Step 8 — Controller Unit & Flow Tests', () {
    late _MockBillingRemoteDataSource mockDs;
    late BillingRepository repository;
    late BillingController controller;

    setUp(() {
      mockDs = _MockBillingRemoteDataSource();
      mockDs.transactionsToReturn = [
        sampleTransactionCredit,
        sampleTransactionDebit,
        sampleTransactionService,
      ];
      mockDs.paginationToReturn = const BillingPagination(page: 1, pageSize: 20, total: 3, totalPages: 1);
      mockDs.farmersToReturn = {
        'farmer-101': (name: 'Ramesh Patel', phone: '+91 98765 43210', village: 'Nashik'),
        'farmer-102': (name: 'Suresh Kumar', phone: '+91 98222 11111', village: 'Pune'),
      };

      repository = BillingRepositoryImpl(remoteDataSource: mockDs);
      controller = BillingController(repository: repository, accessToken: 'test_token');
    });

    test('loadTransactions loads dataset and updates metrics', () async {
      await controller.loadTransactions();

      expect(controller.isLoading, isFalse);
      expect(controller.transactions.length, 3);
      expect(controller.metrics.totalInvoices, 3);
      expect(controller.errorMessage, isNull);
    });

    test('setFilter and setSearchQuery triggers filtered reload', () async {
      await controller.loadTransactions();
      expect(controller.transactions.length, 3);

      controller.setStatusFilter('pending');
      await Future<void>.delayed(Duration.zero);
      expect(controller.transactions.length, 1);
      expect(controller.transactions.first.status, 'pending');

      controller.clearFilters();
      await Future<void>.delayed(Duration.zero);
      expect(controller.transactions.length, 3);
    });

    test('payTransaction successfully settles and updates transaction in place', () async {
      await controller.loadTransactions();

      final success = await controller.payTransaction('tx-102', description: 'Settled NEFT #1234');

      expect(success, isTrue);
      final item = controller.transactions.firstWhere((t) => t.id == 'tx-102');
      expect(item.status, 'completed');
      expect(item.description, 'Settled NEFT #1234');
    });

    test('payTransaction failure stores sanitized error and returns false', () async {
      await controller.loadTransactions();
      mockDs.errorToThrow = const BillingValidationException(message: 'Invalid payment settlement');

      final success = await controller.payTransaction('tx-102');

      expect(success, isFalse);
      expect(controller.errorMessage, 'Invalid payment settlement');
    });
  });

  group('Milestone 5 Step 8 — UI & Widget Tests', () {
    late _MockBillingRemoteDataSource mockDs;
    late BillingRepository repository;
    late BillingController controller;

    setUp(() {
      mockDs = _MockBillingRemoteDataSource();
      mockDs.transactionsToReturn = [sampleTransactionCredit, sampleTransactionDebit];
      mockDs.paginationToReturn = const BillingPagination(page: 1, pageSize: 20, total: 2, totalPages: 1);
      mockDs.farmersToReturn = {
        'farmer-101': (name: 'Ramesh Patel', phone: '+91 98765 43210', village: 'Nashik'),
      };

      repository = BillingRepositoryImpl(remoteDataSource: mockDs);
      controller = BillingController(repository: repository, accessToken: 'test_token');
    });

    testWidgets('BillingMetricsGrid renders all four summary cards', (tester) async {
      final metrics = BillingMetrics.fromTransactions([sampleTransactionCredit, sampleTransactionDebit], totalCount: 2);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: BillingMetricsGrid(metrics: metrics),
            ),
          ),
        ),
      );

      expect(find.text('Total Invoices'), findsOneWidget);
      expect(find.text('Collected'), findsOneWidget);
      expect(find.text('Payouts'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('BillingCard renders transaction details and responds to tap', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BillingCard(
              item: sampleTransactionCredit,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('INV-2026-001'), findsOneWidget);
      expect(find.text('Seed Purchase'), findsOneWidget);
      expect(find.text('Ramesh Patel'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);

      await tester.tap(find.byType(BillingCard));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets('BillingReceiptSheet displays verified details and copy button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BillingReceiptSheet(item: sampleTransactionCredit),
          ),
        ),
      );

      expect(find.text('Invoice Receipt'), findsOneWidget);
      expect(find.text('AgriFlow Financial Desk'), findsOneWidget);
      expect(find.text('CREDIT / RECEIVED'), findsOneWidget);
      expect(find.text('INV-2026-001'), findsOneWidget);
      expect(find.text('Copy Receipt'), findsOneWidget);
    });

    testWidgets('LogTransactionSheet validates inputs and submits with inline error support', (tester) async {
      String? capturedFarmerId;
      double? capturedAmount;
      String? capturedDirection;
      String? capturedType;
      String? capturedDesc;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LogTransactionSheet(
              farmers: const {
                'farmer-1': (name: 'QA Farmer', phone: '9144795385', village: null),
              },
              onSubmit: ({
                required farmerId,
                required amount,
                required direction,
                required referenceType,
                description,
              }) async {
                capturedFarmerId = farmerId;
                capturedAmount = amount;
                capturedDirection = direction;
                capturedType = referenceType;
                capturedDesc = description;
                return 'Server validation error';
              },
            ),
          ),
        ),
      );

      expect(find.text('Record Transaction'), findsOneWidget);
      expect(find.text('Backend API required — to be supplied by Syed.'), findsNothing);

      final submitBtn = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(submitBtn.onPressed, isNotNull);

      // Tapping submit without farmer shows validation error
      await tester.tap(find.text('Submit Record'));
      await tester.pump();
      expect(find.text('Please select a farmer account.'), findsOneWidget);

      // Select farmer, enter invalid amount
      await tester.ensureVisible(find.text('Choose farmer account...'));
      await tester.tap(find.text('Choose farmer account...'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('QA Farmer (9144795385)').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Submit Record'));
      await tester.pump();
      expect(find.text('Please enter a valid amount greater than ₹0.'), findsOneWidget);

      // Enter valid amount & description -> calls onSubmit and shows returned error inline
      await tester.enterText(find.byType(TextField).at(0), '5000');
      await tester.enterText(find.byType(TextField).at(1), 'seed sale for 5000');
      await tester.tap(find.text('Submit Record'));
      await tester.pumpAndSettle();

      expect(capturedFarmerId, 'farmer-1');
      expect(capturedAmount, 5000.0);
      expect(capturedDirection, 'credit');
      expect(capturedType, 'billing');
      expect(capturedDesc, 'seed sale for 5000');
      expect(find.text('Server validation error'), findsOneWidget);
    });

    testWidgets('BillingScreen renders Payments Desk header, search, and list', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BillingScreen(
            controller: controller,
            onBack: () {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Payments Desk'), findsOneWidget);
      expect(find.text('Add Bill'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(BillingCard), findsAtLeastNWidgets(1));
    });

    testWidgets('Tapping Add Bill submits new record and shows it in BillingScreen', (tester) async {
      mockDs.farmersToReturn = {
        'farmer-101': (name: 'Ramesh Patel', phone: '9876543210', village: 'Nashik'),
      };
      controller = BillingController(repository: repository, accessToken: 'test_token');

      await tester.pumpWidget(
        MaterialApp(
          home: BillingScreen(
            controller: controller,
            onBack: () {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Add Bill'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Choose farmer account...'));
      await tester.tap(find.text('Choose farmer account...'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ramesh Patel (9876543210)').last);
      await tester.pumpAndSettle();

      final sheetFields = find.descendant(
        of: find.byType(LogTransactionSheet),
        matching: find.byType(TextField),
      );
      await tester.enterText(sheetFields.at(0), '5000');
      await tester.enterText(sheetFields.at(1), 'seed sale for 5000');
      await tester.tap(find.text('Submit Record'));
      await tester.pumpAndSettle();

      expect(mockDs.createTransactionCallCount, 1);
      expect(find.byType(LogTransactionSheet), findsNothing);
      expect(find.text('Transaction recorded successfully'), findsOneWidget);
      expect(find.text('INV-2026-NEW'), findsOneWidget);
    });

    testWidgets('Tapping Settle on pending card opens confirmation dialog and marks paid', (tester) async {
      mockDs.transactionsToReturn = [sampleTransactionDebit];
      controller = BillingController(repository: repository, accessToken: 'test_token');

      await tester.pumpWidget(
        MaterialApp(
          home: BillingScreen(
            controller: controller,
            onBack: () {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap "Mark Paid / Settle" button on the pending card
      final settleBtn = find.text('Mark Paid / Settle');
      expect(settleBtn, findsOneWidget);

      await tester.ensureVisible(settleBtn);
      await tester.pumpAndSettle();

      await tester.tap(settleBtn);
      await tester.pumpAndSettle();

      expect(find.text('Settle Payment'), findsOneWidget);
      expect(find.text('Confirm Settle'), findsOneWidget);

      await tester.tap(find.text('Confirm Settle'));
      await tester.pumpAndSettle();

      expect(mockDs.payTransactionCallCount, 1);
      expect(find.text('Transaction marked as paid successfully'), findsOneWidget);
    });

    testWidgets('BillingScreen renders empty state when no transactions exist', (tester) async {
      mockDs.transactionsToReturn = [];
      await controller.loadTransactions();

      await tester.pumpWidget(
        MaterialApp(
          home: BillingScreen(
            controller: controller,
            onBack: () {},
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('No Transactions Found'), findsOneWidget);
    });

    testWidgets('BillingScreen renders error state on failure', (tester) async {
      mockDs.errorToThrow = const BillingServerException(message: 'Database connection failed');

      await tester.pumpWidget(
        MaterialApp(
          home: BillingScreen(
            controller: controller,
            onBack: () {},
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Unable to load content'), findsOneWidget);
      expect(find.text('Database connection failed'), findsOneWidget);
    });
  });

  group('Milestone 5 Step 8 — Responsive Layout Verification', () {
    final screenSizes = [
      const Size(320, 568), // iPhone SE 1st gen / Small Mobile
      const Size(360, 640), // Standard Android
      const Size(412, 860), // Large Android
      const Size(412, 960), // Extra Tall Android
    ];

    for (final size in screenSizes) {
      testWidgets('BillingScreen renders without overflow on ${size.width}x${size.height}', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final mockDs = _MockBillingRemoteDataSource();
        mockDs.transactionsToReturn = [sampleTransactionCredit, sampleTransactionDebit];
        final repo = BillingRepositoryImpl(remoteDataSource: mockDs);
        final ctrl = BillingController(repository: repo, accessToken: 'token');

        await tester.pumpWidget(
          MaterialApp(
            home: BillingScreen(
              controller: ctrl,
              onBack: () {},
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(BillingScreen), findsOneWidget);
      });
    }
  });

  group('Milestone 5 Step 8 — Shell Navigation Integration Tests', () {
    final mockSessionAdmin = AuthSession(
      accessToken: 'token_admin',
      refreshToken: 'refresh_admin',
      user: const AuthUser(
        id: 'admin-1',
        name: 'Super Admin',
        phone: '+91 99999 00000',
        role: UserRole.admin,
      ),
    );

    final mockSessionManager = AuthSession(
      accessToken: 'token_manager',
      refreshToken: 'refresh_manager',
      user: const AuthUser(
        id: 'manager-1',
        name: 'Branch Manager',
        phone: '+91 88888 00000',
        role: UserRole.manager,
      ),
    );

    testWidgets('AdminShell routes to BillingScreen when NavDestination.billing is selected', (tester) async {
      final mockDs = _MockBillingRemoteDataSource();
      mockDs.transactionsToReturn = [sampleTransactionCredit];
      final repo = BillingRepositoryImpl(remoteDataSource: mockDs);
      final billingCtrl = BillingController(repository: repo, accessToken: 'token_admin');

      await tester.pumpWidget(
        MaterialApp(
          home: AdminShell(
            session: mockSessionAdmin,
            onLogout: () {},
            billingController: billingCtrl,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open drawer
      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold).first);
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      // Tap "Billing & Invoices" in drawer
      final billingDrawerItem = find.text('Billing & Invoices');
      expect(billingDrawerItem, findsOneWidget);

      await tester.tap(billingDrawerItem);
      await tester.pumpAndSettle();

      expect(find.byType(BillingScreen), findsOneWidget);
    });

    testWidgets('ManagerShell routes to BillingScreen when NavDestination.billing is selected', (tester) async {
      final mockDs = _MockBillingRemoteDataSource();
      mockDs.transactionsToReturn = [sampleTransactionCredit];
      final repo = BillingRepositoryImpl(remoteDataSource: mockDs);
      final billingCtrl = BillingController(repository: repo, accessToken: 'token_manager');

      await tester.pumpWidget(
        MaterialApp(
          home: ManagerShell(
            session: mockSessionManager,
            onLogout: () {},
            billingController: billingCtrl,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open drawer
      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold).first);
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      // Tap "Billing & Invoices" in drawer
      final billingDrawerItem = find.text('Billing & Invoices');
      expect(billingDrawerItem, findsOneWidget);

      await tester.tap(billingDrawerItem);
      await tester.pumpAndSettle();

      expect(find.byType(BillingScreen), findsOneWidget);
    });

    testWidgets('BillingReceiptSheet Settle / Pay action settles pending transaction', (tester) async {
      final mockDs = _MockBillingRemoteDataSource();
      mockDs.transactionsToReturn = [sampleTransactionDebit];
      final repo = BillingRepositoryImpl(remoteDataSource: mockDs);
      final billingCtrl = BillingController(repository: repo, accessToken: 'test_token');

      await tester.pumpWidget(
        MaterialApp(
          home: BillingScreen(
            controller: billingCtrl,
            onBack: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(BillingCard).first);
      await tester.pumpAndSettle();
      expect(find.byType(BillingReceiptSheet), findsOneWidget);

      await tester.tap(find.text('Settle / Pay'));
      await tester.pumpAndSettle();

      expect(find.text('Settle Payment'), findsOneWidget);
      await tester.tap(find.text('Confirm Settle'));
      await tester.pumpAndSettle();

      expect(mockDs.payTransactionCallCount, 1);
      expect(billingCtrl.transactions.first.status, 'completed');
    });

    testWidgets('BillingScreen renders all filters and metrics cleanly on narrow viewports', (tester) async {
      for (final size in const [Size(320, 640), Size(360, 740), Size(412, 860)]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final mockDs = _MockBillingRemoteDataSource();
        mockDs.transactionsToReturn = [sampleTransactionCredit, sampleTransactionDebit];
        final repo = BillingRepositoryImpl(remoteDataSource: mockDs);
        final billingCtrl = BillingController(repository: repo, accessToken: 'test_token');

        await tester.pumpWidget(
          MaterialApp(
            home: BillingScreen(
              controller: billingCtrl,
              onBack: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('All'), findsOneWidget);
        expect(find.text('Completed (Paid)'), findsOneWidget);
        expect(find.text('Pending'), findsAtLeastNWidgets(1));
        expect(find.text('Failed'), findsOneWidget);
        expect(find.text('Dates'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });
  });
}
