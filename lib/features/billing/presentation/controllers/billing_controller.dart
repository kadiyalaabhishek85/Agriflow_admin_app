import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/billing_exception.dart';
import '../../domain/entities/billing_metrics.dart';
import '../../domain/entities/billing_pagination.dart';
import '../../domain/entities/billing_transaction_item.dart';
import '../../domain/repositories/billing_repository.dart';
import '../../../../core/network/error_sanitizer.dart';

/// State management controller for Billing & Invoices (Transactions & Payments Desk).
class BillingController extends ChangeNotifier {
  final BillingRepository repository;
  final String accessToken;

  BillingController({
    required this.repository,
    required this.accessToken,
  });

  List<BillingTransactionItem> _transactions = [];
  BillingPagination _pagination = const BillingPagination(
    page: 1,
    pageSize: 20,
    total: 0,
    totalPages: 1,
  );
  BillingMetrics _metrics = const BillingMetrics();

  bool _isLoading = false;
  bool _isRefreshing = false;
  bool _isLoadingMore = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  /// Monotonic request generation. Every page-1 load increments it; a
  /// response is applied only if its generation is still current, so a
  /// newer filter selection can never be overwritten by a stale response,
  /// and filter changes are never dropped while another load is in flight.
  int _requestGeneration = 0;

  String _searchQuery = '';
  String _liveQuery = '';
  String _statusFilter = 'all'; // 'all', 'completed', 'pending', 'failed'
  String? _referenceTypeFilter; // 'seed_purchase', 'grain_sale', 'billing', 'other'
  String? _directionFilter; // 'credit', 'debit'
  DateTime? _fromDate;
  DateTime? _toDate;

  Map<String, ({String name, String phone, String? village})> _farmers = {};

  bool _matchesQuery(BillingTransactionItem item, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return item.displayFarmerName.toLowerCase().contains(q) ||
        (item.enrichedFarmerPhone ?? '').toLowerCase().contains(q) ||
        item.displayInvoiceNumber.toLowerCase().contains(q) ||
        (item.description ?? '').toLowerCase().contains(q) ||
        item.displayReferenceType.toLowerCase().contains(q) ||
        item.status.toLowerCase().contains(q) ||
        item.farmerId.toLowerCase().contains(q) ||
        item.id.toLowerCase().contains(q);
  }

  /// Filters already-loaded transactions immediately while typing.
  void previewSearch(String query) {
    final normalized = query.trim();
    if (_liveQuery == normalized) return;
    _liveQuery = normalized;
    notifyListeners();
  }

  List<BillingTransactionItem> get transactions {
    final activeQuery = _liveQuery.isNotEmpty ? _liveQuery : _searchQuery;
    if (activeQuery.isEmpty) {
      return List.unmodifiable(_transactions);
    }
    return List.unmodifiable(
      _transactions.where((item) => _matchesQuery(item, activeQuery)),
    );
  }
  BillingPagination get pagination => _pagination;
  BillingMetrics get metrics => _metrics;

  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  bool get isLoadingMore => _isLoadingMore;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  String get searchQuery => _searchQuery;
  String get statusFilter => _statusFilter;
  String? get referenceTypeFilter => _referenceTypeFilter;
  String? get directionFilter => _directionFilter;
  DateTime? get fromDate => _fromDate;
  DateTime? get toDate => _toDate;
  Map<String, ({String name, String phone, String? village})> get farmers => _farmers;

  /// Loads initial page of transactions with active filters.
  ///
  /// Always supersedes any in-flight page-1 load: the previous request's
  /// response is discarded instead of silently dropping this new request,
  /// so a filter tap always fetches (and replaces with) fresh data.
  Future<void> loadTransactions({bool refresh = false}) async {
    final generation = ++_requestGeneration;

    if (refresh) {
      _isRefreshing = true;
    } else {
      _isLoading = true;
    }
    _errorMessage = null;
    notifyListeners();

    try {
      final fromStr = _fromDate != null ? DateFormat('yyyy-MM-dd').format(_fromDate!) : null;
      final toStr = _toDate != null ? DateFormat('yyyy-MM-dd').format(_toDate!) : null;

      final result = await repository.getTransactions(
        accessToken: accessToken,
        page: 1,
        pageSize: _pagination.pageSize,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        referenceType: _referenceTypeFilter != 'all' ? _referenceTypeFilter : null,
        direction: _directionFilter != 'all' ? _directionFilter : null,
        status: _statusFilter != 'all' ? _statusFilter : null,
        fromDate: fromStr,
        toDate: toStr,
      );

      // Stale response: a newer load superseded this one — discard it.
      if (generation != _requestGeneration) return;

      final allItems = List<BillingTransactionItem>.from(_enrichList(result.items));
      var latestPagination = result.pagination;

      if (_searchQuery.isNotEmpty &&
          allItems.any((item) => !_matchesQuery(item, _searchQuery))) {
        final maxPages = latestPagination.totalPages.clamp(1, 10);
        for (int p = 2; p <= maxPages; p++) {
          final nextRes = await repository.getTransactions(
            accessToken: accessToken,
            page: p,
            pageSize: _pagination.pageSize,
            search: _searchQuery,
            referenceType: _referenceTypeFilter != 'all' ? _referenceTypeFilter : null,
            direction: _directionFilter != 'all' ? _directionFilter : null,
            status: _statusFilter != 'all' ? _statusFilter : null,
            fromDate: fromStr,
            toDate: toStr,
          );
          if (generation != _requestGeneration) return;
          if (nextRes.items.isEmpty) break;
          allItems.addAll(_enrichList(nextRes.items));
          latestPagination = nextRes.pagination;
        }
      }

      if (generation != _requestGeneration) return;
      _transactions = allItems;
      _pagination = latestPagination;
      _metrics = result.metrics;
      _errorMessage = null;
    } on BillingException catch (e) {
      if (generation != _requestGeneration) return;
      _errorMessage = e.message;
    } catch (e) {
      if (generation != _requestGeneration) return;
      _errorMessage = ErrorSanitizer.sanitize(e, defaultAction: 'Loading transactions');
    } finally {
      // Only the still-current request owns the loading flags.
      if (generation == _requestGeneration) {
        _isLoading = false;
        _isRefreshing = false;
        notifyListeners();
      }
    }
  }

  /// Pull-to-refresh
  Future<void> refreshTransactions() async {
    await loadTransactions(refresh: true);
  }

  /// Pagination: load next page
  Future<void> loadMoreTransactions() async {
    if (_isLoadingMore || !_pagination.hasMore || _isLoading || _isRefreshing) {
      return;
    }

    _isLoadingMore = true;
    notifyListeners();

    final generation = _requestGeneration;
    try {
      final nextPage = _pagination.page + 1;
      final fromStr = _fromDate != null ? DateFormat('yyyy-MM-dd').format(_fromDate!) : null;
      final toStr = _toDate != null ? DateFormat('yyyy-MM-dd').format(_toDate!) : null;

      final result = await repository.getTransactions(
        accessToken: accessToken,
        page: nextPage,
        pageSize: _pagination.pageSize,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        referenceType: _referenceTypeFilter != 'all' ? _referenceTypeFilter : null,
        direction: _directionFilter != 'all' ? _directionFilter : null,
        status: _statusFilter != 'all' ? _statusFilter : null,
        fromDate: fromStr,
        toDate: toStr,
      );

      // Filter changed while this page was in flight — the old filter's
      // page must not be appended to the new filter's list.
      if (generation != _requestGeneration) return;

      _transactions.addAll(_enrichList(result.items));
      _pagination = result.pagination;
      // Re-compute combined metrics
      _metrics = BillingMetrics.fromTransactions(_transactions, totalCount: _pagination.total);
    } catch (_) {
      // Retain existing items on pagination failure
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Search query setter with debounce / reset
  void setSearchQuery(String query) {
    final normalized = query.trim();
    _liveQuery = normalized;
    if (_searchQuery == normalized) {
      notifyListeners();
      return;
    }
    _searchQuery = normalized;
    loadTransactions();
  }

  /// Status filter chip/tab setter
  void setStatusFilter(String status) {
    if (_statusFilter == status) return;
    _statusFilter = status;
    loadTransactions();
  }

  /// Reference type filter setter ('seed_purchase', 'grain_sale', 'billing', 'other')
  void setReferenceTypeFilter(String? type) {
    if (_referenceTypeFilter == type) return;
    _referenceTypeFilter = type;
    loadTransactions();
  }

  /// Direction filter setter ('credit', 'debit')
  void setDirectionFilter(String? direction) {
    if (_directionFilter == direction) return;
    _directionFilter = direction;
    loadTransactions();
  }

  /// Date range filter setter
  void setDateRange(DateTime? from, DateTime? to) {
    _fromDate = from;
    _toDate = to;
    loadTransactions();
  }

  /// Reset all filters to default
  void clearFilters() {
    _searchQuery = '';
    _statusFilter = 'all';
    _referenceTypeFilter = null;
    _directionFilter = null;
    _fromDate = null;
    _toDate = null;
    loadTransactions();
  }

  /// Loads farmers lookup catalog for enrichment
  Future<void> loadFarmers() async {
    if (_farmers.isNotEmpty) return;
    try {
      _farmers = await repository.getFarmerLookup(accessToken: accessToken);
      _transactions = _enrichList(_transactions);
      notifyListeners();
    } catch (_) {
      // Keep empty if lookup fails
    }
  }

  /// Creates a manual transaction / bill via POST /api/v1/transactions
  Future<bool> createTransaction({
    required String farmerId,
    required double amount,
    required String direction,
    required String referenceType,
    String? description,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final created = await repository.createTransaction(
        accessToken: accessToken,
        farmerId: farmerId,
        amount: amount,
        direction: direction,
        referenceType: referenceType,
        description: description,
      );

      final enriched = _enrichItem(created);
      final matchesStatus =
          _statusFilter == 'all' || enriched.status.toLowerCase() == _statusFilter.toLowerCase();
      final matchesType = _referenceTypeFilter == null ||
          _referenceTypeFilter == 'all' ||
          enriched.referenceType.toLowerCase() == _referenceTypeFilter!.toLowerCase();
      final matchesDirection = _directionFilter == null ||
          _directionFilter == 'all' ||
          enriched.direction.toLowerCase() == _directionFilter!.toLowerCase();
      final activeQuery = _liveQuery.isNotEmpty ? _liveQuery : _searchQuery;
      final matchesSearch =
          activeQuery.isEmpty || _matchesQuery(enriched, activeQuery);

      if (matchesStatus && matchesType && matchesDirection && matchesSearch) {
        _transactions.insert(0, enriched);
        _pagination = _pagination.copyWith(total: _pagination.total + 1);
        _metrics = BillingMetrics.fromTransactions(
          _transactions,
          totalCount: _pagination.total,
        );
      }

      _errorMessage = null;
      notifyListeners();
      return true;
    } on BillingException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = ErrorSanitizer.sanitize(e, defaultAction: 'Recording transaction');
      notifyListeners();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Authoritatively settles a transaction via PATCH /api/v1/transactions/{id}/pay
  Future<bool> payTransaction(String transactionId, {String? description}) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await repository.payTransaction(
        accessToken: accessToken,
        transactionId: transactionId,
        description: description,
      );

      final index = _transactions.indexWhere((t) => t.id == transactionId);
      if (index != -1) {
        _transactions[index] = _enrichItem(updated);
        _metrics = BillingMetrics.fromTransactions(_transactions, totalCount: _pagination.total);
      }
      _errorMessage = null;
      notifyListeners();
      return true;
    } on BillingException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = ErrorSanitizer.sanitize(e, defaultAction: 'Processing payment');
      notifyListeners();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  List<BillingTransactionItem> _enrichList(List<BillingTransactionItem> items) {
    if (_farmers.isEmpty) return items;
    return items.map(_enrichItem).toList();
  }

  BillingTransactionItem _enrichItem(BillingTransactionItem item) {
    if (_farmers.containsKey(item.farmerId)) {
      final farmer = _farmers[item.farmerId]!;
      return item.copyWithEnrichment(
        farmerName: farmer.name,
        farmerPhone: farmer.phone,
        farmerVillage: farmer.village,
      );
    }
    return item;
  }
}
