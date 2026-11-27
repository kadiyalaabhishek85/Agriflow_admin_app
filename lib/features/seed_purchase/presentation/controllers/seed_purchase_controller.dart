import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:agriflow_admin/features/seed_purchase/data/repositories/seed_purchase_repository_impl.dart';
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
  List<SeedPurchaseItem> get purchases {
    final activeQuery = _liveQuery.isNotEmpty ? _liveQuery : _searchQuery;
    if (activeQuery.isEmpty) {
      return List.unmodifiable(_purchases);
    }
    return List.unmodifiable(
      _purchases.where((item) => _matchesQuery(item, activeQuery)),
    );
  }

  SeedPurchasePagination _pagination = SeedPurchasePagination.empty();
  SeedPurchasePagination get pagination => _pagination;

  int get displayTotal {
    final activeQuery = _liveQuery.isNotEmpty ? _liveQuery : _searchQuery;
    if (activeQuery.isNotEmpty && (_clientFiltered || _liveQuery != _searchQuery)) {
      return purchases.length;
    }
    return _pagination.total;
  }

  final Map<String, int> _statusCounts = {};
  int _countsEpoch = 0;

  /// Returns the cached item count for a status filter chip (`all`, `pending`,
  /// `paid`, `failed`), or the current active filter's count if already loaded.
  int? countForFilter(String filter) {
    final key = filter.toLowerCase();
    if (key == _activeFilter && _status == SeedPurchaseViewStatus.success) {
      return displayTotal;
    }
    return _statusCounts[key];
  }

  Future<void> _refreshStatusCounts({
    required String searchSnapshot,
    required Map<String, int> known,
  }) async {
    final repo = repository;
    if (repo is! SeedPurchaseRepositoryImpl) return;
    final epoch = ++_countsEpoch;
    final counts = await repo.getStatusCounts(
      accessToken: accessToken,
      search: searchSnapshot,
      seedKnown: known,
    );
    if (epoch != _countsEpoch) return;
    _statusCounts
      ..clear()
      ..addAll(counts);
    notifyListeners();
  }

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

  String _liveQuery = '';
  bool _clientFiltered = false;
  int _loadEpoch = 0;

  // ID of purchase currently undergoing status mutation
  String? _actionInFlightId;
  String? get actionInFlightId => _actionInFlightId;

  bool _matchesQuery(SeedPurchaseItem item, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return item.displayName.toLowerCase().contains(q) ||
        item.displayPhone.toLowerCase().contains(q) ||
        item.displaySeed.toLowerCase().contains(q) ||
        item.displayVariety.toLowerCase().contains(q) ||
        (item.invoiceNumber ?? '').toLowerCase().contains(q) ||
        item.paymentStatus.toLowerCase().contains(q) ||
        item.id.toLowerCase().contains(q);
  }

  /// Immediately filters loaded items while typing before debounced fetch runs.
  void previewSearch(String query) {
    final normalized = query.trim();
    if (_liveQuery == normalized) return;
    _liveQuery = normalized;
    notifyListeners();
  }

  /// Loads the first page of purchases (and gathers remaining pages if server ignores search).
  Future<void> loadPurchases() async {
    final epoch = ++_loadEpoch;
    _status = SeedPurchaseViewStatus.loading;
    _errorMessage = null;
    _clientFiltered = false;
    notifyListeners();

    try {
      final result = await repository.getPurchases(
        accessToken: accessToken,
        page: 1,
        pageSize: 20,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        status: _activeFilter == 'all' ? null : _activeFilter,
      );
      if (epoch != _loadEpoch) return;

      final allItems = List<SeedPurchaseItem>.from(result.items);
      var latestPagination = result.pagination;

      if (_searchQuery.isNotEmpty &&
          allItems.any((item) => !_matchesQuery(item, _searchQuery))) {
        _clientFiltered = true;
        final maxPages = latestPagination.totalPages.clamp(1, 10);
        for (int p = 2; p <= maxPages; p++) {
          final nextRes = await repository.getPurchases(
            accessToken: accessToken,
            page: p,
            pageSize: 20,
            search: _searchQuery,
            status: _activeFilter == 'all' ? null : _activeFilter,
          );
          if (epoch != _loadEpoch) return;
          if (nextRes.items.isEmpty) break;
          allItems.addAll(nextRes.items);
          latestPagination = nextRes.pagination;
        }
      }

      if (epoch != _loadEpoch) return;
      _purchases = allItems;
      _pagination = latestPagination;
      _status = SeedPurchaseViewStatus.success;

      if (_clientFiltered) {
        final matched = purchases;
        _statusCounts[_activeFilter] = matched.length;
        if (_activeFilter == 'all') {
          _statusCounts['pending'] = matched.where((p) => p.paymentStatus == 'pending').length;
          _statusCounts['paid'] = matched.where((p) => p.paymentStatus == 'paid').length;
          _statusCounts['failed'] = matched.where((p) => p.paymentStatus == 'failed').length;
        }
      } else {
        _statusCounts[_activeFilter] = latestPagination.total;
        unawaited(_refreshStatusCounts(
          searchSnapshot: _searchQuery,
          known: {_activeFilter: latestPagination.total},
        ));
      }
    } on SeedPurchaseException catch (e) {
      if (epoch != _loadEpoch) return;
      _status = SeedPurchaseViewStatus.error;
      _errorMessage = e.message;
    } catch (e) {
      if (epoch != _loadEpoch) return;
      _status = SeedPurchaseViewStatus.error;
      _errorMessage = ErrorSanitizer.sanitize(e, defaultAction: 'Loading seed purchases');
    } finally {
      if (epoch == _loadEpoch) {
        notifyListeners();
      }
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
      _statusCounts[_activeFilter] = result.pagination.total;
      unawaited(_refreshStatusCounts(
        searchSnapshot: _searchQuery,
        known: {_activeFilter: result.pagination.total},
      ));
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
    final normalized = query.trim();
    _liveQuery = normalized;
    if (_searchQuery == normalized) {
      notifyListeners();
      return;
    }
    _searchQuery = normalized;
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
      final oldStatus = index != -1 ? _purchases[index].paymentStatus.toLowerCase() : null;
      if (index != -1) {
        _purchases[index] = updatedItem;
      }
      final nextStatus = updatedItem.paymentStatus.toLowerCase();
      if (oldStatus != null && oldStatus != nextStatus) {
        if (_statusCounts.containsKey(oldStatus) && _statusCounts[oldStatus]! > 0) {
          _statusCounts[oldStatus] = _statusCounts[oldStatus]! - 1;
        }
        if (_statusCounts.containsKey(nextStatus)) {
          _statusCounts[nextStatus] = _statusCounts[nextStatus]! + 1;
        }
      }
      unawaited(_refreshStatusCounts(
        searchSnapshot: _searchQuery,
        known: const {},
      ));
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
