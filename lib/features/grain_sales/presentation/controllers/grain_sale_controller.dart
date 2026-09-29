import 'package:flutter/material.dart';
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
  String _currentFilter = 'all'; // 'all', 'pending', 'received', 'approved', 'rejected', 'paid'
  Map<String, ({String name, String phone, String? village})> _farmers = {};

  List<GrainSaleItem> get sales => List.unmodifiable(_sales);
  GrainSalePagination get pagination => _pagination;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  bool get isLoadingMore => _isLoadingMore;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get currentFilter => _currentFilter;
  Map<String, ({String name, String phone, String? village})> get farmers => _farmers;

  /// Loads initial page of grain sales
  Future<void> loadSales({bool refresh = false}) async {
    if (_isLoading) return;

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

      _sales = List.from(result.items);
      _pagination = result.pagination;
      _errorMessage = null;
    } on GrainSaleException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = ErrorSanitizer.sanitize(e, defaultAction: 'Loading grain sales');
    } finally {
      _isLoading = false;
      _isRefreshing = false;
      notifyListeners();
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

    try {
      final nextPage = _pagination.page + 1;
      final result = await repository.getGrainSales(
        accessToken: accessToken,
        page: nextPage,
        pageSize: _pagination.pageSize,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        status: _currentFilter != 'all' ? _currentFilter : null,
      );

      _sales.addAll(result.items);
      _pagination = result.pagination;
    } catch (_) {
      // Keep existing list on pagination failure
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Sets live search query and reloads dataset
  void setSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
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

      if (existingIndex != -1) {
        _sales[existingIndex] = updated;
      }
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
      if (index != -1) {
        _sales[index] = updated;
      }
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
      if (index != -1) {
        _sales[index] = updated;
      }
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
