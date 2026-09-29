import 'package:flutter/foundation.dart';
import 'package:agriflow_admin/features/seed_purchase/domain/entities/seed_purchase_exception.dart';
import 'package:agriflow_admin/features/seed_purchase/domain/entities/seed_purchase_item.dart';
import 'package:agriflow_admin/features/seed_purchase/domain/entities/seed_purchase_pagination.dart';
import 'package:agriflow_admin/features/seed_purchase/domain/repositories/seed_purchase_repository.dart';
import 'package:agriflow_admin/core/network/error_sanitizer.dart';

enum SeedPurchaseViewStatus {
  initial,
  loading,
  success,
  error,
}

class SeedPurchaseController extends ChangeNotifier {
  final SeedPurchaseRepository repository;
  final String accessToken;

  SeedPurchaseController({
    required this.repository,
    required this.accessToken,
  });

  SeedPurchaseViewStatus _status = SeedPurchaseViewStatus.initial;
  SeedPurchaseViewStatus get status => _status;

  bool get isLoading => _status == SeedPurchaseViewStatus.loading;
  bool get isSuccess => _status == SeedPurchaseViewStatus.success;
  bool get isError => _status == SeedPurchaseViewStatus.error;

  List<SeedPurchaseItem> _purchases = [];
  List<SeedPurchaseItem> get purchases => List.unmodifiable(_purchases);

  SeedPurchasePagination _pagination = SeedPurchasePagination.empty();
  SeedPurchasePagination get pagination => _pagination;

  bool _isRefreshing = false;
  bool get isRefreshing => _isRefreshing;

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Active Filter: 'all', 'pending', 'paid', 'failed'
  String _activeFilter = 'all';
  String get activeFilter => _activeFilter;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  // ID of purchase currently undergoing status mutation
  String? _actionInFlightId;
  String? get actionInFlightId => _actionInFlightId;

  /// Loads the first page of purchases.
  Future<void> loadPurchases() async {
    _status = SeedPurchaseViewStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await repository.getPurchases(
        accessToken: accessToken,
        page: 1,
        pageSize: 20,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        status: _activeFilter == 'all' ? null : _activeFilter,
      );

      _purchases = result.items;
      _pagination = result.pagination;
      _status = SeedPurchaseViewStatus.success;
    } on SeedPurchaseException catch (e) {
      _status = SeedPurchaseViewStatus.error;
      _errorMessage = e.message;
    } catch (e) {
      _status = SeedPurchaseViewStatus.error;
      _errorMessage = ErrorSanitizer.sanitize(e, defaultAction: 'Loading seed purchases');
    } finally {
      notifyListeners();
    }
  }

  /// Refreshes the dataset, replacing existing items.
  Future<void> refreshPurchases() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await repository.getPurchases(
        accessToken: accessToken,
        page: 1,
        pageSize: 20,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        status: _activeFilter == 'all' ? null : _activeFilter,
      );

      _purchases = result.items;
      _pagination = result.pagination;
      _status = SeedPurchaseViewStatus.success;
    } on SeedPurchaseException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = ErrorSanitizer.sanitize(e, defaultAction: 'Refreshing seed purchases');
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  /// Appends next page of purchases if more exist.
  Future<void> loadMorePurchases() async {
    if (_isLoadingMore || !_pagination.hasMore || isLoading) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _pagination.page + 1;
      final result = await repository.getPurchases(
        accessToken: accessToken,
        page: nextPage,
        pageSize: 20,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        status: _activeFilter == 'all' ? null : _activeFilter,
      );

      _purchases.addAll(result.items);
      _pagination = result.pagination;
    } catch (_) {
      // Retain existing items on failure
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Updates status filter and reloads.
  void setFilter(String filter) {
    if (_activeFilter == filter) return;
    _activeFilter = filter.toLowerCase();
    loadPurchases();
  }

  /// Updates search query and reloads.
  void setSearch(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    loadPurchases();
  }

  /// Authoritatively updates payment status on the backend.
  Future<bool> updateStatus({
    required String purchaseId,
    required String newStatus,
  }) async {
    _actionInFlightId = purchaseId;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedItem = await repository.updatePurchaseStatus(
        accessToken: accessToken,
        purchaseId: purchaseId,
        newStatus: newStatus,
      );

      // Authoritative replacement from backend response
      final index = _purchases.indexWhere((p) => p.id == purchaseId);
      if (index != -1) {
        _purchases[index] = updatedItem;
      }
      return true;
    } on SeedPurchaseException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = ErrorSanitizer.sanitize(e, defaultAction: 'Updating status');
      return false;
    } finally {
      _actionInFlightId = null;
      notifyListeners();
    }
  }
}
