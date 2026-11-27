import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/repositories/grain_sale_repository_impl.dart';
import '../../domain/entities/grain_sale_exception.dart';
import '../../domain/entities/grain_sale_item.dart';
import '../../domain/entities/grain_sale_pagination.dart';
import '../../domain/repositories/grain_sale_repository.dart';
import '../../../../core/network/error_sanitizer.dart';

/// State management controller for Grain Sales feature.
class GrainSaleController extends ChangeNotifier {
  final GrainSaleRepository repository;
  final String accessToken;

  GrainSaleController({
    required this.repository,
    required this.accessToken,
  });

  List<GrainSaleItem> _sales = [];
  GrainSalePagination _pagination = const GrainSalePagination(
    page: 1,
    pageSize: 20,
    total: 0,
    totalPages: 1,
  );
  bool _isLoading = false;
  bool _isRefreshing = false;
  bool _isLoadingMore = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  String _searchQuery = '';
  String _liveQuery = '';
  bool _clientFiltered = false;
  int _loadEpoch = 0;
  String _currentFilter = 'all'; // 'all', 'pending', 'received', 'approved', 'rejected', 'paid'
  Map<String, ({String name, String phone, String? village})> _farmers = {};

  final Map<String, int> _statusCounts = {};
  int _countsEpoch = 0;

  List<GrainSaleItem> get sales {
    final activeQuery = _liveQuery.isNotEmpty ? _liveQuery : _searchQuery;
    if (activeQuery.isEmpty) {
      return List.unmodifiable(_sales);
    }
    return List.unmodifiable(
      _sales.where((item) => _matchesQuery(item, activeQuery)),
    );
  }

  GrainSalePagination get pagination => _pagination;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  bool get isLoadingMore => _isLoadingMore;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get currentFilter => _currentFilter;
  Map<String, ({String name, String phone, String? village})> get farmers => _farmers;

  /// Returns cached total count for a status filter chip (`all`, `pending`,
  /// `received`, `approved`, `rejected`, `paid`), or active total if loaded.
  int? countForFilter(String filter) {
    final key = filter.toLowerCase();
    if (key == _currentFilter && !_isLoading && _errorMessage == null) {
      final activeQuery = _liveQuery.isNotEmpty ? _liveQuery : _searchQuery;
      if (activeQuery.isNotEmpty && (_clientFiltered || _liveQuery != _searchQuery)) {
        return sales.length;
      }
      return _pagination.total;
    }
    return _statusCounts[key];
  }

  bool _matchesQuery(GrainSaleItem item, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return item.displayFarmerName.toLowerCase().contains(q) ||
        (item.enrichedFarmerPhone ?? '').toLowerCase().contains(q) ||
        item.displayVillage.toLowerCase().contains(q) ||
        item.grainType.toLowerCase().contains(q) ||
        item.grade.toLowerCase().contains(q) ||
        item.status.toLowerCase().contains(q) ||
        item.id.toLowerCase().contains(q);
  }

  /// Filters already-loaded grain sales immediately while user types.
  void previewSearch(String query) {
    final normalized = query.trim();
    if (_liveQuery == normalized) return;
    _liveQuery = normalized;
    notifyListeners();
  }

  Future<void> _refreshStatusCounts({
    required String searchSnapshot,
    required Map<String, int> known,
  }) async {
    final repo = repository;
    if (repo is! GrainSaleRepositoryImpl) return;
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

  /// Loads initial page of grain sales (supersedes any older in-flight search/filter load).
  Future<void> loadSales({bool refresh = false}) async {
    final epoch = ++_loadEpoch;
    _clientFiltered = false;

    if (refresh) {
      _isRefreshing = true;
    } else {
      _isLoading = true;
    }
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await repository.getGrainSales(
        accessToken: accessToken,
        page: 1,
        pageSize: _pagination.pageSize,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        status: _currentFilter != 'all' ? _currentFilter : null,
      );

      if (epoch != _loadEpoch) return;

      final allItems = List<GrainSaleItem>.from(result.items);
      var latestPagination = result.pagination;

      // Client-side completeness fallback when backend returns rows outside query.
      if (_searchQuery.isNotEmpty &&
          allItems.any((item) => !_matchesQuery(item, _searchQuery))) {
        _clientFiltered = true;
        final maxPages = latestPagination.totalPages.clamp(1, 10);
        for (int p = 2; p <= maxPages; p++) {
          final nextRes = await repository.getGrainSales(
            accessToken: accessToken,
            page: p,
            pageSize: _pagination.pageSize,
            search: _searchQuery,
            status: _currentFilter != 'all' ? _currentFilter : null,
          );
          if (epoch != _loadEpoch) return;
          if (nextRes.items.isEmpty) break;
          allItems.addAll(nextRes.items);
          latestPagination = nextRes.pagination;
        }
      }

      _sales = allItems;
      _pagination = latestPagination;
      _errorMessage = null;

      if (_clientFiltered) {
        final matched = sales;
        _statusCounts[_currentFilter] = matched.length;
        if (_currentFilter == 'all') {
          for (final st in const ['pending', 'received', 'approved', 'rejected', 'paid']) {
            _statusCounts[st] = matched.where((s) => s.status.toLowerCase() == st).length;
          }
        }
      } else {
        _statusCounts[_currentFilter] = latestPagination.total;
        unawaited(_refreshStatusCounts(
          searchSnapshot: _searchQuery,
          known: {_currentFilter: latestPagination.total},
        ));
      }
    } on GrainSaleException catch (e) {
      if (epoch != _loadEpoch) return;
      _errorMessage = e.message;
    } catch (e) {
      if (epoch != _loadEpoch) return;
      _errorMessage = ErrorSanitizer.sanitize(e, defaultAction: 'Loading grain sales');
    } finally {
      if (epoch == _loadEpoch) {
        _isLoading = false;
        _isRefreshing = false;
        notifyListeners();
      }
    }
  }

  /// Pull-to-refresh: replaces current dataset cleanly
  Future<void> refreshSales() async {
    await loadSales(refresh: true);
  }

  /// Loads next page of sales and appends to existing list
  Future<void> loadMoreSales() async {
    if (_isLoadingMore || !_pagination.hasMore || _isLoading || _isRefreshing) {
      return;
    }

    _isLoadingMore = true;
    notifyListeners();

    final epoch = _loadEpoch;
    try {
      final nextPage = _pagination.page + 1;
      final result = await repository.getGrainSales(
        accessToken: accessToken,
        page: nextPage,
        pageSize: _pagination.pageSize,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        status: _currentFilter != 'all' ? _currentFilter : null,
      );

      if (epoch != _loadEpoch) return;
      _sales.addAll(result.items);
      _pagination = result.pagination;
    } catch (_) {
      // Keep existing list on pagination failure
    } finally {
      if (epoch == _loadEpoch) {
        _isLoadingMore = false;
        notifyListeners();
      }
    }
  }

  /// Sets live search query and reloads dataset
  void setSearchQuery(String query) {
    final normalized = query.trim();
    _liveQuery = normalized;
    if (_searchQuery == normalized) {
      notifyListeners();
      return;
    }
    _searchQuery = normalized;
    loadSales();
  }

  /// Sets status filter chip and reloads dataset
  void setFilter(String filter) {
    if (_currentFilter == filter) return;
    _currentFilter = filter;
    loadSales();
  }

  /// Loads farmers catalog for the "Log Received Crop" intake form
  Future<void> loadFarmers() async {
    if (_farmers.isNotEmpty) return;
    try {
      _farmers = await repository.getFarmerLookup(accessToken: accessToken);
      notifyListeners();
    } catch (_) {
      // Fallback empty
    }
  }

  /// Authoritatively logs received crop intake calling POST /procure
  Future<bool> procureCrop({
    required String farmerId,
    required String grainType,
    required String grade,
    required double rawMaterialKg,
    required double goodMaterialKg,
    required double wastageKg,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newItem = await repository.procureCrop(
        accessToken: accessToken,
        farmerId: farmerId,
        grainType: grainType,
        grade: grade,
        rawMaterialKg: rawMaterialKg,
        goodMaterialKg: goodMaterialKg,
        wastageKg: wastageKg,
      );

      _sales.insert(0, newItem);
      _pagination = _pagination.copyWith(total: _pagination.total + 1);
      _statusCounts['all'] = (_statusCounts['all'] ?? 0) + 1;
      final st = newItem.status.toLowerCase();
      _statusCounts[st] = (_statusCounts[st] ?? 0) + 1;
      unawaited(_refreshStatusCounts(searchSnapshot: _searchQuery, known: const {}));
      _errorMessage = null;
      notifyListeners();
      return true;
    } on GrainSaleException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = ErrorSanitizer.sanitize(e, defaultAction: 'Logging crop');
      notifyListeners();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Reviews crop inspection yields and moves grain sale to approved (or rejected) via PATCH /{id}/review
  Future<bool> reviewGrainSale({
    required String saleId,
    double? goodQuantityKg,
    double? badQuantityKg,
    bool approve = true,
    String? rejectionReason,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final existingIndex = _sales.indexWhere((s) => s.id == saleId);
      final existingItem = existingIndex != -1 ? _sales[existingIndex] : null;

      final goodQty = goodQuantityKg ?? (double.tryParse(existingItem?.goodMaterialKg ?? '0') ?? 0.0);
      final badQty = badQuantityKg ?? (double.tryParse(existingItem?.wastageKg ?? '0') ?? 0.0);

      final updated = await repository.reviewGrainSale(
        accessToken: accessToken,
        saleId: saleId,
        goodQuantityKg: goodQty,
        badQuantityKg: badQty,
        approve: approve,
        rejectionReason: rejectionReason,
      );

      final oldStatus = existingItem?.status.toLowerCase();
      if (existingIndex != -1) {
        _sales[existingIndex] = updated;
      }
      final nextStatus = updated.status.toLowerCase();
      if (oldStatus != null && oldStatus != nextStatus) {
        if ((_statusCounts[oldStatus] ?? 0) > 0) {
          _statusCounts[oldStatus] = _statusCounts[oldStatus]! - 1;
        }
        if (_statusCounts.containsKey(nextStatus)) {
          _statusCounts[nextStatus] = _statusCounts[nextStatus]! + 1;
        }
      }
      unawaited(_refreshStatusCounts(searchSnapshot: _searchQuery, known: const {}));
      _errorMessage = null;
      notifyListeners();
      return true;
    } on GrainSaleException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = ErrorSanitizer.sanitize(e, defaultAction: 'Reviewing grain sale');
      notifyListeners();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Authoritatively settles payment calling PATCH /{id}/pay
  Future<bool> payGrainSale(String saleId, {String? paymentReference}) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await repository.payGrainSale(
        accessToken: accessToken,
        saleId: saleId,
        paymentReference: paymentReference,
      );

      final index = _sales.indexWhere((s) => s.id == saleId);
      final oldStatus = index != -1 ? _sales[index].status.toLowerCase() : null;
      if (index != -1) {
        _sales[index] = updated;
      }
      final nextStatus = updated.status.toLowerCase();
      if (oldStatus != null && oldStatus != nextStatus) {
        if ((_statusCounts[oldStatus] ?? 0) > 0) {
          _statusCounts[oldStatus] = _statusCounts[oldStatus]! - 1;
        }
        if (_statusCounts.containsKey(nextStatus)) {
          _statusCounts[nextStatus] = _statusCounts[nextStatus]! + 1;
        }
      }
      unawaited(_refreshStatusCounts(searchSnapshot: _searchQuery, known: const {}));
      _errorMessage = null;
      notifyListeners();
      return true;
    } on GrainSaleException catch (e) {
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

  /// Corrects yield quantities via PATCH /{id}/yield.
  Future<bool> updateGrainYield({
    required String saleId,
    required double goodMaterialKg,
    required double wastageKg,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await repository.updateGrainYield(
        accessToken: accessToken,
        saleId: saleId,
        goodMaterialKg: goodMaterialKg,
        wastageKg: wastageKg,
      );

      final index = _sales.indexWhere((s) => s.id == saleId);
      final oldStatus = index != -1 ? _sales[index].status.toLowerCase() : null;
      if (index != -1) {
        _sales[index] = updated;
      }
      final nextStatus = updated.status.toLowerCase();
      if (oldStatus != null && oldStatus != nextStatus) {
        if ((_statusCounts[oldStatus] ?? 0) > 0) {
          _statusCounts[oldStatus] = _statusCounts[oldStatus]! - 1;
        }
        if (_statusCounts.containsKey(nextStatus)) {
          _statusCounts[nextStatus] = _statusCounts[nextStatus]! + 1;
        }
      }
      unawaited(_refreshStatusCounts(searchSnapshot: _searchQuery, known: const {}));
      _errorMessage = null;
      notifyListeners();
      return true;
    } on GrainSaleException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = ErrorSanitizer.sanitize(e, defaultAction: 'Updating yield');
      notifyListeners();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
