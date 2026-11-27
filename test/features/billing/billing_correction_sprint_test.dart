import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agriflow_admin/features/billing/data/datasources/billing_remote_data_source.dart';
import 'package:agriflow_admin/features/billing/data/repositories/billing_repository_impl.dart';
import 'package:agriflow_admin/features/billing/data/services/android_receipt_downloader.dart';
import 'package:agriflow_admin/features/billing/domain/entities/billing_exception.dart';
import 'package:agriflow_admin/features/billing/domain/entities/billing_pagination.dart';
import 'package:agriflow_admin/features/billing/domain/entities/billing_transaction_item.dart';
import 'package:agriflow_admin/features/billing/domain/receipt/billing_receipt_data.dart';
import 'package:agriflow_admin/features/billing/domain/receipt/receipt_pdf_builder.dart';
import 'package:agriflow_admin/features/billing/domain/services/receipt_downloader.dart';
import 'package:agriflow_admin/features/billing/presentation/controllers/billing_controller.dart';
import 'package:agriflow_admin/features/billing/presentation/screens/billing_screen.dart';
import 'package:agriflow_admin/features/billing/presentation/widgets/billing_receipt_sheet.dart';

// -------------------------------------------------------------
// Test data source — records every status/page requested and can
// gate individual calls so concurrency races are deterministic.
// -------------------------------------------------------------

class _TestBillingDataSource implements BillingRemoteDataSource {
  List<BillingTransactionItem> allTransactions = [];
  final List<String?> statusesRequested = [];
  final List<int> pagesRequested = [];
  int getTransactionsCallCount = 0;
  Exception? errorToThrow;
  int pageSize = 20;
  Future<void> Function(int callIndex)? gate;
  Map<String, ({String name, String phone, String? village})> farmersToReturn = {};

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
    pagesRequested.add(page);

    final gateFn = gate;
    if (gateFn != null) await gateFn(getTransactionsCallCount);

    final err = errorToThrow;
    if (err != null) throw err;

    var filtered = allTransactions;
    if (status != null && status.isNotEmpty && status != 'all') {
      filtered = filtered.where((t) => t.status == status).toList();
    }

    final start = (page - 1) * pageSize;
    final slice = start >= filtered.length
        ? <BillingTransactionItem>[]
        : filtered.sublist(
            start,
            start + pageSize > filtered.length ? filtered.length : start + pageSize,
          );
    final totalPages =
        filtered.isEmpty ? 1 : (filtered.length + pageSize - 1) ~/ pageSize;

    return (
      items: slice,
      pagination: BillingPagination(
        page: page,
        pageSize: pageSize,
        total: filtered.length,
        totalPages: totalPages,
      ),
    );
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
    throw UnimplementedError('not used in filter sprint tests');
  }

  @override
  Future<BillingTransactionItem> payTransaction({
    required String accessToken,
    required String transactionId,
    String? description,
  }) async {
    throw UnimplementedError('not used in filter sprint tests');
  }

  @override
  Future<Map<String, ({String name, String phone, String? village})>> getFarmers({
    required String accessToken,
  }) async {
    return farmersToReturn;
  }
}

/// Per-call gates: gate(index).future parks request `index` until opened.
class _Gates {
  final Map<int, Completer<void>> _pending = {};

  Future<void> wait(int index) =>
      _pending.putIfAbsent(index, () => Completer<void>()).future;

  void open(int index) {
    final completer = _pending.putIfAbsent(index, () => Completer<void>());
    if (!completer.isCompleted) completer.complete();
  }
}

BillingTransactionItem _tx({
  required String id,
  required String status,
  String invoice = '',
  double amount = 85,
  String direction = 'credit',
  String? description,
  String? referenceId,
  String farmerId = 'farmer-101',
  String referenceType = 'seed_purchase',
}) {
  return BillingTransactionItem(
    id: id,
    referenceType: referenceType,
    referenceId: referenceId,
    farmerId: farmerId,
    amount: amount,
    direction: direction,
    status: status,
    description: description,
    invoiceNumber: invoice.isEmpty ? null : invoice,
    createdAt: DateTime(2026, 9, 28, 12, 30),
  );
}

/// Waits until the controller has no in-flight load/refresh/load-more.
Future<void> _settle(BillingController controller) async {
  for (var i = 0; i < 200; i++) {
    if (!controller.isLoading && !controller.isRefreshing && !controller.isLoadingMore) {
      break;
    }
    await Future<void>.delayed(Duration.zero);
  }
  await Future<void>.delayed(Duration.zero);
}

BillingController _controllerFor(_TestBillingDataSource ds) {
  return BillingController(
    repository: BillingRepositoryImpl(remoteDataSource: ds),
    accessToken: 'test_token',
  );
}

Future<Uint8List> _loadReceiptFont() async {
  final data = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
  return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
}

// -------------------------------------------------------------
// ISSUE 1 — Status filter mapping & state tests (1–13)
// -------------------------------------------------------------

void main() {
  group('Correction Sprint — Filter mapping tests (1-4)', () {
    late _TestBillingDataSource ds;
    late BillingController controller;

    setUp(() {
      ds = _TestBillingDataSource();
      ds.allTransactions = [
        _tx(id: 'c1', status: 'completed', invoice: 'SP-C-1'),
        _tx(id: 'p1', status: 'pending', invoice: 'SP-P-1'),
        _tx(id: 'f1', status: 'failed', invoice: 'SP-F-1'),
      ];
      controller = _controllerFor(ds);
    });

    test('1. All -> no status parameter', () async {
      controller.setStatusFilter('pending');
      await _settle(controller);
      expect(ds.statusesRequested.last, 'pending');

      controller.setStatusFilter('all');
      await _settle(controller);
      expect(ds.statusesRequested.last, isNull,
          reason: 'All must reload with no status query parameter');
    });

    test('2. Completed -> "completed"', () async {
      controller.setStatusFilter('completed');
      await _settle(controller);
      expect(ds.statusesRequested.last, 'completed');
      expect(controller.transactions.every((t) => t.status == 'completed'), isTrue);
    });

    test('3. Pending -> "pending"', () async {
      controller.setStatusFilter('pending');
      await _settle(controller);
      expect(ds.statusesRequested.last, 'pending');
      expect(controller.transactions.every((t) => t.status == 'pending'), isTrue);
    });

    test('4. Failed -> "failed"', () async {
      controller.setStatusFilter('failed');
      await _settle(controller);
      expect(ds.statusesRequested.last, 'failed');
      expect(controller.transactions.every((t) => t.status == 'failed'), isTrue);
    });
  });

  group('Correction Sprint — Filter state tests (5-13)', () {
    late _TestBillingDataSource ds;
    late BillingController controller;

    setUp(() {
      ds = _TestBillingDataSource();
      ds.allTransactions = [
        _tx(id: 'c1', status: 'completed', invoice: 'SP-C-1'),
        _tx(id: 'c2', status: 'completed', invoice: 'SP-C-2'),
        _tx(id: 'p1', status: 'pending', invoice: 'SP-P-1'),
        _tx(id: 'f1', status: 'failed', invoice: 'SP-F-1'),
      ];
      controller = _controllerFor(ds);
    });

    test('5. Selecting Pending triggers reload', () async {
      await controller.loadTransactions();
      final before = ds.getTransactionsCallCount;
      controller.setStatusFilter('pending');
      await _settle(controller);
      expect(ds.getTransactionsCallCount, before + 1);
      expect(ds.statusesRequested.last, 'pending');
    });

    test('6. Selecting Completed triggers reload', () async {
      await controller.loadTransactions();
      final before = ds.getTransactionsCallCount;
      controller.setStatusFilter('completed');
      await _settle(controller);
      expect(ds.getTransactionsCallCount, before + 1);
      expect(ds.statusesRequested.last, 'completed');
    });

    test('7. Selecting Failed triggers reload', () async {
      await controller.loadTransactions();
      final before = ds.getTransactionsCallCount;
      controller.setStatusFilter('failed');
      await _settle(controller);
      expect(ds.getTransactionsCallCount, before + 1);
      expect(ds.statusesRequested.last, 'failed');
    });

    test('8. Selecting All triggers reload', () async {
      controller.setStatusFilter('completed');
      await _settle(controller);
      final before = ds.getTransactionsCallCount;
      controller.setStatusFilter('all');
      await _settle(controller);
      expect(ds.getTransactionsCallCount, before + 1);
      expect(ds.statusesRequested.last, isNull);
      expect(controller.transactions.length, 4);
    });

    test('9. Filter change resets page to 1', () async {
      controller.setStatusFilter('pending');
      await _settle(controller);
      expect(controller.pagination.page, 1);
      expect(ds.pagesRequested.last, 1);
    });

    test('10. Filter change replaces old transaction list', () async {
      await controller.loadTransactions();
      expect(controller.transactions.length, 4);
      controller.setStatusFilter('pending');
      await _settle(controller);
      expect(controller.transactions.length, 1);
      expect(controller.transactions.single.status, 'pending');
    });

    test('11. Old filtered transactions are not retained', () async {
      controller.setStatusFilter('completed');
      await _settle(controller);
      expect(controller.transactions.length, 2);
      controller.setStatusFilter('failed');
      await _settle(controller);
      expect(controller.transactions.length, 1);
      expect(controller.transactions.single.status, 'failed');
      expect(controller.transactions.any((t) => t.status == 'completed'), isFalse);
    });

    testWidgets('12. Empty Pending response displays correct empty state', (tester) async {
      ds.allTransactions = [_tx(id: 'c1', status: 'completed', invoice: 'SP-C-1')];
      await tester.pumpWidget(MaterialApp(
        home: BillingScreen(controller: controller, onBack: () {}),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('billing-filter-pending')));
      await tester.pumpAndSettle();

      expect(find.text('No Transactions Found'), findsOneWidget);
      expect(controller.transactions, isEmpty);
      expect(controller.errorMessage, isNull);
    });

    testWidgets('13. Empty Failed response displays correct empty state', (tester) async {
      ds.allTransactions = [_tx(id: 'c1', status: 'completed', invoice: 'SP-C-1')];
      await tester.pumpWidget(MaterialApp(
        home: BillingScreen(controller: controller, onBack: () {}),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('billing-filter-failed')));
      await tester.pumpAndSettle();

      expect(find.text('No Transactions Found'), findsOneWidget);
      expect(controller.transactions, isEmpty);
      expect(controller.errorMessage, isNull);
    });
  });

  group('Correction Sprint — Sequential filter tests (14-18)', () {
    late _TestBillingDataSource ds;
    late BillingController controller;

    setUp(() {
      ds = _TestBillingDataSource();
      ds.allTransactions = [
        _tx(id: 'c1', status: 'completed', invoice: 'SP-C-1'),
        _tx(id: 'p1', status: 'pending', invoice: 'SP-P-1'),
        _tx(id: 'f1', status: 'failed', invoice: 'SP-F-1'),
      ];
      controller = _controllerFor(ds);
    });

    test('14. All -> Pending', () async {
      await controller.loadTransactions();
      controller.setStatusFilter('pending');
      await _settle(controller);
      expect(controller.statusFilter, 'pending');
      expect(controller.transactions.single.status, 'pending');
      expect(ds.statusesRequested, containsAllInOrder([null, 'pending']));
    });

    test('15. Pending -> Completed', () async {
      await controller.loadTransactions();
      controller.setStatusFilter('pending');
      await _settle(controller);
      controller.setStatusFilter('completed');
      await _settle(controller);
      expect(controller.statusFilter, 'completed');
      expect(controller.transactions.single.status, 'completed');
    });

    test('16. Completed -> Failed', () async {
      controller.setStatusFilter('completed');
      await _settle(controller);
      controller.setStatusFilter('failed');
      await _settle(controller);
      expect(controller.statusFilter, 'failed');
      expect(controller.transactions.single.status, 'failed');
    });

    test('17. Failed -> All', () async {
      controller.setStatusFilter('failed');
      await _settle(controller);
      controller.setStatusFilter('all');
      await _settle(controller);
      expect(controller.statusFilter, 'all');
      expect(controller.transactions.length, 3);
    });

    test('18. Rapid Completed -> Pending -> Failed keeps final filter', () async {
      final gates = _Gates();
      ds.gate = gates.wait;

      controller.loadTransactions();
      gates.open(1);
      await _settle(controller);
      expect(controller.transactions.length, 3);

      // Rapid taps with no waiting — every tap must issue a request.
      controller.setStatusFilter('completed');
      controller.setStatusFilter('pending');
      controller.setStatusFilter('failed');
      expect(ds.statusesRequested, [null, 'completed', 'pending', 'failed']);

      // Newest request finishes first; older ones land afterwards.
      gates.open(4);
      await _settle(controller);
      gates.open(3);
      gates.open(2);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(controller.statusFilter, 'failed');
      expect(controller.transactions.single.status, 'failed');
      expect(controller.transactions.single.invoiceNumber, 'SP-F-1');
    });
  });

  group('Correction Sprint — Pagination tests (19-22)', () {
    late _TestBillingDataSource ds;
    late BillingController controller;

    setUp(() {
      ds = _TestBillingDataSource();
      // 40 completed + 3 failed + 25 pending → pagination exists on All.
      ds.allTransactions = [
        for (var i = 0; i < 40; i++)
          _tx(id: 'c$i', status: 'completed', invoice: 'SP-C-$i'),
        for (var i = 0; i < 3; i++) _tx(id: 'f$i', status: 'failed', invoice: 'SP-F-$i'),
        for (var i = 0; i < 25; i++) _tx(id: 'p$i', status: 'pending', invoice: 'SP-P-$i'),
      ];
      controller = _controllerFor(ds);
    });

    test('19. Filter change resets pagination', () async {
      await controller.loadTransactions();
      expect(controller.pagination.page, 1);
      expect(controller.pagination.hasMore, isTrue);
      await controller.loadMoreTransactions();
      expect(controller.pagination.page, 2);
      expect(controller.transactions.length, 40);

      controller.setStatusFilter('failed');
      await _settle(controller);

      expect(ds.pagesRequested.last, 1);
      expect(controller.pagination.page, 1);
      expect(controller.transactions.length, 3);
      expect(controller.transactions.every((t) => t.status == 'failed'), isTrue);
    });

    test('20. Loading more uses the selected status', () async {
      controller.setStatusFilter('pending');
      await _settle(controller);
      expect(controller.pagination.page, 1);

      await controller.loadMoreTransactions();

      expect(ds.pagesRequested.last, 2);
      expect(ds.statusesRequested.last, 'pending');
      expect(controller.pagination.page, 2);
      expect(controller.transactions.length, 25);
      expect(controller.transactions.every((t) => t.status == 'pending'), isTrue);
    });

    test('21. No duplicate page requests', () async {
      await controller.loadTransactions();
      expect(ds.getTransactionsCallCount, 1);

      final gates = _Gates();
      ds.gate = gates.wait;

      final first = controller.loadMoreTransactions();
      final second = controller.loadMoreTransactions(); // ignored while in flight
      await Future<void>.delayed(Duration.zero);

      expect(ds.getTransactionsCallCount, 2, reason: 'second loadMore must not fire a request');
      expect(ds.pagesRequested, [1, 2]);

      gates.open(2);
      await first;
      await second;
      await _settle(controller);

      expect(controller.transactions.length, 40);
      expect(ds.pagesRequested, [1, 2], reason: 'page 2 requested exactly once');
    });

    test('22. No stale response overwrites newer filter state', () async {
      final gates = _Gates();
      ds.gate = gates.wait;

      controller.loadTransactions();
      gates.open(1);
      await _settle(controller);
      expect(controller.transactions.length, 20, reason: 'first page of All');

      // Refresh (older request) still in flight when filter changes.
      controller.refreshTransactions(); // call 2 — stale "all" response
      controller.setStatusFilter('pending'); // call 3 — newer filtered request

      gates.open(3); // newer finishes first
      await _settle(controller);
      expect(controller.transactions.every((t) => t.status == 'pending'), isTrue);
      expect(controller.transactions.length, 20, reason: 'first page of Pending');

      gates.open(2); // stale refresh lands afterwards — must be discarded
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(controller.statusFilter, 'pending');
      expect(controller.transactions.length, 20,
          reason: 'stale unfiltered refresh must not overwrite filtered list');
      expect(controller.transactions.every((t) => t.status == 'pending'), isTrue);
    });
  });

  group('Correction Sprint — Error tests (23-27)', () {
    late _TestBillingDataSource ds;
    late BillingController controller;

    setUp(() {
      ds = _TestBillingDataSource();
      ds.allTransactions = [_tx(id: 'c1', status: 'completed', invoice: 'SP-C-1')];
      controller = _controllerFor(ds);
    });

    test('23. 401 handling', () async {
      ds.errorToThrow = const BillingUnauthorizedException();
      await controller.loadTransactions();
      expect(controller.errorMessage, 'Session expired. Please log in again.');
      expect(controller.isLoading, isFalse);
      expect(controller.transactions, isEmpty);
    });

    test('24. 403 handling', () async {
      ds.errorToThrow = const BillingForbiddenException();
      await controller.loadTransactions();
      expect(controller.errorMessage, 'You do not have permission to perform this action.');
      expect(controller.isLoading, isFalse);
    });

    test('25. 422 handling', () async {
      ds.errorToThrow = const BillingValidationException(message: 'Invalid status filter');
      await controller.loadTransactions();
      expect(controller.errorMessage, 'Invalid status filter');
      expect(controller.isLoading, isFalse);
    });

    test('26. 500 handling', () async {
      ds.errorToThrow = const BillingServerException();
      await controller.loadTransactions();
      expect(controller.errorMessage, 'Backend server error. Please try again later.');
      expect(controller.isLoading, isFalse);
    });

    test('27. network failure', () async {
      ds.errorToThrow = const BillingException(
        message: 'Network connection unavailable. Please check your internet connection.',
        isNetworkError: true,
      );
      await controller.loadTransactions();
      expect(controller.errorMessage,
          'Network connection unavailable. Please check your internet connection.');
      expect(controller.isLoading, isFalse);
    });
  });

  group('Correction Sprint — UI chip wiring (reported symptom)', () {
    late _TestBillingDataSource ds;
    late BillingController controller;

    setUp(() {
      ds = _TestBillingDataSource();
      ds.allTransactions = [
        _tx(id: 'c1', status: 'completed', invoice: 'SP-20260928-94584D0D', amount: 85),
        _tx(id: 'p1', status: 'pending', invoice: 'SP-20260928-31C4D9F4', amount: 85),
        _tx(id: 'f1', status: 'failed', invoice: 'SP-20260928-0000000F', amount: 40),
      ];
      controller = _controllerFor(ds);
    });

    testWidgets('Tapping Completed (Paid) filters the visible list', (tester) async {
      // Tall viewport so all three cards are built and visible without scrolling.
      tester.view.physicalSize = const Size(412, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(MaterialApp(
        home: BillingScreen(controller: controller, onBack: () {}),
      ));
      await tester.pumpAndSettle();
      expect(find.text('SP-20260928-94584D0D'), findsOneWidget);
      expect(find.text('SP-20260928-31C4D9F4'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('billing-filter-completed')));
      await tester.pumpAndSettle();

      expect(ds.statusesRequested.last, 'completed');
      expect(find.text('SP-20260928-94584D0D'), findsOneWidget);
      expect(find.text('SP-20260928-31C4D9F4'), findsNothing,
          reason: 'pending card must disappear when Completed is selected');
      expect(controller.statusFilter, 'completed');
    });

    testWidgets('Tapping Pending then Failed keeps list in sync with chip', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: BillingScreen(controller: controller, onBack: () {}),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('billing-filter-pending')));
      await tester.pumpAndSettle();
      expect(controller.statusFilter, 'pending');
      expect(find.text('SP-20260928-31C4D9F4'), findsOneWidget);
      expect(find.text('SP-20260928-94584D0D'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('billing-filter-failed')));
      await tester.pumpAndSettle();
      expect(controller.statusFilter, 'failed');
      expect(find.text('SP-20260928-0000000F'), findsOneWidget);
      expect(find.text('SP-20260928-31C4D9F4'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('billing-filter-all')));
      await tester.pumpAndSettle();
      expect(controller.transactions.length, 3);
      expect(ds.statusesRequested, containsAllInOrder([null, 'pending', 'failed', null]));
    });

    testWidgets('Rapid chip taps settle on the final selection', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: BillingScreen(controller: controller, onBack: () {}),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('billing-filter-completed')));
      await tester.tap(find.byKey(const ValueKey('billing-filter-pending')));
      await tester.tap(find.byKey(const ValueKey('billing-filter-failed')));
      await tester.pumpAndSettle();

      expect(controller.statusFilter, 'failed');
      expect(controller.transactions.length, 1);
      expect(controller.transactions.single.status, 'failed');
      expect(ds.statusesRequested.last, 'failed');
    });
  });

  // -------------------------------------------------------------
  // ISSUE 2 — Download receipt tests (28-44)
  // -------------------------------------------------------------

  group('Correction Sprint — Receipt data tests (28-34)', () {
    final item = _tx(
      id: 'tx-receipt-1',
      status: 'completed',
      invoice: 'SP-20260928-94584D0D',
      amount: 85,
      direction: 'credit',
      description: 'Seed sale settlement',
      referenceId: 'REF-94584D0D',
      referenceType: 'seed_purchase',
    );

    test('28. Receipt data is built from actual transaction', () {
      final data = BillingReceiptData.from(item);
      expect(data.transactionId, item.id);
      expect(data.category, item.displayReferenceType);
      expect(data.direction, 'Credit (Inflow)');
      expect(data.dateTime, item.formattedDate);
    });

    test('29. Invoice number appears in generated receipt data', () {
      final data = BillingReceiptData.from(item);
      expect(data.invoiceNumber, 'SP-20260928-94584D0D');
      expect(data.toCopyText(), contains('SP-20260928-94584D0D'));
      expect(data.fileName, contains('SP-20260928-94584D0D'));
    });

    test('30. Amount appears correctly', () {
      final data = BillingReceiptData.from(item);
      expect(data.amount, '₹85');
      expect(data.toCopyText(), contains('Amount: ₹85'));
    });

    test('31. Status appears correctly', () {
      final data = BillingReceiptData.from(item);
      expect(data.status, 'COMPLETED');
      expect(data.toCopyText(), contains('Status: COMPLETED'));
    });

    test('32. Farmer information is preserved', () {
      final enriched = item.copyWithEnrichment(
        farmerName: 'Ramesh Patel',
        farmerPhone: '+91 98765 43210',
      );
      final data = BillingReceiptData.from(enriched);
      expect(data.farmerName, 'Ramesh Patel');
      expect(data.phone, '+91 98765 43210');
      expect(data.toCopyText(), contains('Farmer: Ramesh Patel'));
      expect(data.toCopyText(), contains('Phone: +91 98765 43210'));
    });

    test('33. Reference ID is preserved', () {
      final data = BillingReceiptData.from(item);
      expect(data.referenceId, 'REF-94584D0D');
      expect(data.toCopyText(), contains('Reference ID: REF-94584D0D'));
    });

    test('34. Description is preserved', () {
      final data = BillingReceiptData.from(item);
      expect(data.description, 'Seed sale settlement');
      expect(data.toCopyText(), contains('Description: Seed sale settlement'));
    });
  });

  group('Correction Sprint — Filename & resilience tests (35-38)', () {
    test('35. Filename is generated correctly', () {
      final item = _tx(
        id: 'tx-1',
        status: 'completed',
        invoice: 'SP-20260928-94584D0D',
      );
      expect(BillingReceiptData.from(item).fileName,
          'AgriFlow_Receipt_SP-20260928-94584D0D.pdf');
    });

    test('36. Unsafe filename characters are sanitized', () {
      String nameFor(String invoice) {
        return BillingReceiptData.from(
          _tx(id: 'tx-1', status: 'completed', invoice: invoice),
        ).fileName;
      }

      final hostile = nameFor(r'../../etc/pass wd:rx*?"<>|');
      expect(RegExp(r'[<>:"/\\|?*]').hasMatch(hostile), isFalse);
      expect(hostile.contains('..'), isFalse);
      expect(hostile, startsWith('AgriFlow_Receipt_'));
      expect(hostile, endsWith('.pdf'));

      // Missing/blank invoice falls back to displayInvoiceNumber (INV-<id>).
      expect(nameFor('   '), 'AgriFlow_Receipt_INV-TX-1.pdf');
      expect(nameFor(''), 'AgriFlow_Receipt_INV-TX-1.pdf');
      // An invoice that sanitizes away entirely lands on the RECEIPT fallback.
      expect(nameFor('***'), 'AgriFlow_Receipt_RECEIPT.pdf');
    });

    test('37. Missing optional description does not crash', () async {
      final data = BillingReceiptData.from(
        _tx(id: 'tx-2', status: 'completed', invoice: 'INV-NO-DESC'),
      );
      expect(data.description, isNull);
      expect(data.toCopyText(), isNot(contains('Description:')));

      final font = await _loadReceiptFont();
      final bytes = await buildReceiptPdf(data, fontBytes: font, compress: false);
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    });

    test('38. Missing optional farmer data does not crash', () async {
      final data = BillingReceiptData.from(
        _tx(id: 'tx-3', status: 'pending', invoice: 'INV-NO-FARMER', farmerId: ''),
      );
      expect(data.farmerName, 'AgriFlow System');
      expect(data.phone, isNull);
      expect(data.toCopyText(), contains('Farmer: AgriFlow System'));
      expect(data.toCopyText(), isNot(contains('Phone:')));

      final font = await _loadReceiptFont();
      final bytes = await buildReceiptPdf(data, fontBytes: font, compress: false);
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    });
  });

  group('Correction Sprint — Download failure handling (39-42)', () {
    final item = _tx(
      id: 'tx-dl-1',
      status: 'completed',
      invoice: 'SP-20260928-94584D0D',
      amount: 85,
      description: 'Seed sale settlement',
      referenceId: 'REF-94584D0D',
    );
    final data = BillingReceiptData.from(item);

    test('39. PDF generation failure is handled', () async {
      final downloader = AndroidReceiptDownloader(
        loadFont: () async => Uint8List.fromList([1, 2, 3]),
        buildPdf: (d, font) async => throw Exception('boom: font corrupt'),
        saveFile: (bytes, name) async =>
            throw StateError('save must not be reached'),
      );
      final result = await downloader.download(data: data);
      expect(result.success, isFalse);
      expect(result.message, ReceiptMessages.pdfFailure);
      expect(result.message.contains('Exception'), isFalse);
      expect(result.message.contains('boom'), isFalse);
    });

    test('40. File save failure is handled', () async {
      final font = await _loadReceiptFont();
      final downloader = AndroidReceiptDownloader(
        loadFont: () async => font,
        saveFile: (bytes, name) async => throw Exception('disk full'),
      );
      final result = await downloader.download(data: data);
      expect(result.success, isFalse);
      expect(result.message, ReceiptMessages.saveFailure);
      expect(result.message.contains('disk full'), isFalse);
    });

    test('40b. Permission/storage failure maps to sanitized message', () async {
      final font = await _loadReceiptFont();
      final downloader = AndroidReceiptDownloader(
        loadFont: () async => font,
        saveFile: (bytes, name) async =>
            throw PlatformException(code: 'permission_denied'),
      );
      final result = await downloader.download(data: data);
      expect(result.success, isFalse);
      expect(result.message, ReceiptMessages.permissionDenied);
    });

    testWidgets('41. Duplicate download taps are prevented', (tester) async {
      final completer = Completer<ReceiptDownloadResult>();
      final fake = _CountingSlowDownloader(completer);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: BillingReceiptSheet(item: item, downloader: fake),
        ),
      ));

      await tester.tap(find.text('Download Receipt'));
      await tester.pump();
      expect(find.text('Saving...'), findsOneWidget);

      await tester.tap(find.text('Saving...'));
      await tester.pump();
      expect(fake.calls, 1, reason: 'second tap while busy must be ignored');

      completer.complete(const ReceiptDownloadResult(
        success: true,
        message: ReceiptMessages.downloadSuccess,
        location: '/storage/emulated/0/Download/AgriFlow_Receipt_SP-20260928-94584D0D.pdf',
      ));
      await tester.pumpAndSettle();

      expect(find.text('Receipt downloaded successfully.'), findsOneWidget);
      expect(find.text('Download Receipt'), findsOneWidget, reason: 'button re-enabled');
    });

    testWidgets('42. Download success produces the expected file', (tester) async {
      Uint8List? savedBytes;
      String? savedName;
      final font = await _loadReceiptFont();
      final downloader = AndroidReceiptDownloader(
        loadFont: () async => font,
        saveFile: (bytes, name) async {
          savedBytes = bytes;
          savedName = name;
          return '/storage/emulated/0/Download/$name';
        },
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: BillingReceiptSheet(item: item, downloader: downloader),
        ),
      ));

      await tester.tap(find.text('Download Receipt'));
      await tester.pumpAndSettle();

      expect(savedBytes, isNotNull);
      expect(String.fromCharCodes(savedBytes!.take(4)), '%PDF');
      expect(savedName, 'AgriFlow_Receipt_SP-20260928-94584D0D.pdf');
      expect(find.text('Receipt downloaded successfully.'), findsOneWidget);
      expect(
        find.text('/storage/emulated/0/Download/AgriFlow_Receipt_SP-20260928-94584D0D.pdf'),
        findsOneWidget,
      );
    });
  });

  group('Correction Sprint — Copy & consistency tests (43-44)', () {
    final item = _tx(
      id: 'tx-copy-1',
      status: 'completed',
      invoice: 'SP-20260928-31C4D9F4',
      amount: 85,
      description: 'Grain payout',
      referenceId: 'REF-COPY-1',
    ).copyWithEnrichment(farmerName: 'Suresh Kumar', farmerPhone: '+91 90000 00001');

    testWidgets('43. Copy Receipt still works independently', (tester) async {
      final clipboard = _FakeClipboard()..install(tester);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: BillingReceiptSheet(item: item)),
      ));

      await tester.tap(find.text('Copy Receipt'));
      await tester.pumpAndSettle();

      final clip = await Clipboard.getData(Clipboard.kTextPlain);
      expect(clip, isNotNull);
      expect(clip!.text, contains('SP-20260928-31C4D9F4'));
      expect(clip.text, contains('Amount: ₹85'));
      expect(clip.text, contains('Status: COMPLETED'));
      expect(clip.text, clipboard.written, reason: 'round trip matches the stored copy');
      expect(find.text('Receipt copied to clipboard'), findsOneWidget);
    });

    testWidgets('44. Download Receipt and Copy Receipt contain consistent data', (tester) async {
      _FakeClipboard().install(tester);
      final capturing = _CapturingDownloader();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: BillingReceiptSheet(item: item, downloader: capturing),
        ),
      ));

      await tester.tap(find.text('Copy Receipt'));
      await tester.pumpAndSettle();
      final clip = (await Clipboard.getData(Clipboard.kTextPlain))!.text!;

      await tester.tap(find.text('Download Receipt'));
      await tester.pumpAndSettle();

      final data = capturing.received;
      expect(data, isNotNull);
      // Same verified values reach both the clipboard text and the PDF builder.
      expect(clip, contains(data!.invoiceNumber));
      expect(clip, contains(data.amount));
      expect(clip, contains(data.status));
      expect(clip, contains(data.farmerName));
      expect(clip, contains(data.referenceId!));
      expect(clip, contains(data.description!));
      expect(capturing.calls, 1);
    });
  });

  // -------------------------------------------------------------
  // Responsive verification (320x568 / 360x640 / 412x860 / 412x960)
  // -------------------------------------------------------------
  group('Correction Sprint — Responsive verification', () {
    const sizes = <Size>[
      Size(320, 568),
      Size(360, 640),
      Size(412, 860),
      Size(412, 960),
    ];

    for (final size in sizes) {
      testWidgets('BillingScreen ${size.width}x${size.height} — chips & cards, 0 overflows',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final ds = _TestBillingDataSource();
        ds.allTransactions = [
          _tx(id: 'c1', status: 'completed', invoice: 'SP-C-1'),
          _tx(id: 'p1', status: 'pending', invoice: 'SP-P-1'),
          _tx(id: 'f1', status: 'failed', invoice: 'SP-F-1'),
        ];
        final controller = _controllerFor(ds);

        await tester.pumpWidget(MaterialApp(
          home: BillingScreen(controller: controller, onBack: () {}),
        ));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'no RenderFlex overflow');
        expect(find.byKey(const ValueKey('billing-filter-all')), findsOneWidget);
        expect(find.byKey(const ValueKey('billing-filter-completed')), findsOneWidget);
        expect(find.byKey(const ValueKey('billing-filter-pending')), findsOneWidget);
        expect(find.byKey(const ValueKey('billing-filter-failed')), findsOneWidget);
        expect(controller.transactions.length, 3, reason: 'all three cards loaded');

        // Chips sit below the fold on small screens — scroll them into view.
        final completedChip = find.byKey(const ValueKey('billing-filter-completed'));
        await tester.scrollUntilVisible(completedChip, 200,
            scrollable: find.byType(Scrollable).first);
        await tester.pumpAndSettle();

        await tester.tap(completedChip);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(controller.transactions.length, 1);
        expect(controller.transactions.single.status, 'completed');
      });

      testWidgets('Receipt sheet ${size.width}x${size.height} — Download reachable, 0 overflows',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final fake = _CountingSlowDownloader(
          Completer<ReceiptDownloadResult>()..complete(const ReceiptDownloadResult(
            success: true,
            message: ReceiptMessages.downloadSuccess,
            location: '/download/x.pdf',
          )),
        );
        final item = _tx(
          id: 'tx-r',
          status: 'completed',
          invoice: 'SP-20260928-94584D0D',
          description: 'Receipt responsive check',
          referenceId: 'REF-R-1',
        );

        await tester.pumpWidget(MaterialApp(
          home: Scaffold(body: BillingReceiptSheet(item: item, downloader: fake)),
        ));
        await tester.pump();

        expect(tester.takeException(), isNull, reason: 'no RenderFlex overflow');

        // Buttons must be reachable (sheet scrolls if needed) and tappable.
        await tester.ensureVisible(find.text('Download Receipt'));
        await tester.pump();
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('Download Receipt'));
        await tester.pumpAndSettle();
        expect(fake.calls, 1, reason: 'Download Receipt must be tappable on small screens');
        expect(tester.takeException(), isNull);
      });
    }
  });
}

// -------------------------------------------------------------
// Test doubles for the download service
// -------------------------------------------------------------

class _CountingSlowDownloader implements ReceiptDownloader {
  final Completer<ReceiptDownloadResult> completer;
  int calls = 0;

  _CountingSlowDownloader(this.completer);

  @override
  Future<ReceiptDownloadResult> download({required BillingReceiptData data}) {
    calls++;
    return completer.future;
  }
}

class _CapturingDownloader implements ReceiptDownloader {
  int calls = 0;
  BillingReceiptData? received;

  @override
  Future<ReceiptDownloadResult> download({required BillingReceiptData data}) {
    calls++;
    received = data;
    return Future.value(const ReceiptDownloadResult(
      success: true,
      message: ReceiptMessages.downloadSuccess,
      location: '/download/capturing.pdf',
    ));
  }
}

/// In-memory Clipboard for widget tests. An unmocked flutter/platform channel
/// never answers in `flutter test`, so Clipboard calls deadlock without this.
class _FakeClipboard {
  String? written;

  void install(WidgetTester tester) {
    written = null;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          written = (call.arguments as Map)['text'] as String?;
          return null;
        }
        if (call.method == 'Clipboard.getData') {
          return <String, dynamic>{'text': written ?? ''};
        }
        return null;
      },
    );
  }
}
