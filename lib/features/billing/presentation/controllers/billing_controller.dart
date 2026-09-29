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
  String _statusFilter = 'all'; // 'all', 'completed', 'pending', 'failed'
  String? _referenceTypeFilter; // 'seed_purchase', 'grain_sale', 'billing', 'other'
  String? _directionFilter; // 'credit', 'debit'
  DateTime? _fromDate;
  DateTime? _toDate;

  Map<String, ({String name, String phone, String? village})> _farmers = {};

  List<BillingTransactionItem> get transactions => List.unmodifiable(_transactions);
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

      _transactions = _enrichList(result.items);
      _pagination = result.pagination;
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
    if (_searchQuery == query) return;
    _searchQuery = query;
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
