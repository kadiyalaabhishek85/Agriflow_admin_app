import 'dart:async';
import 'package:flutter/material.dart';
import '../../domain/entities/bank_change_request_item.dart';
import '../../domain/entities/farmer_exception.dart';
import '../../domain/entities/farmer_item.dart';
import '../../domain/entities/farmer_pagination.dart';
import '../../domain/repositories/farmer_repository.dart';
import '../../../../core/network/error_sanitizer.dart';

/// State management controller for All Farmers feature.
class FarmerController extends ChangeNotifier {
  final FarmerRepository repository;
  final String accessToken;

  FarmerController({
    required this.repository,
    required this.accessToken,
  });

  List<FarmerItem> _farmers = [];
  FarmerPagination _pagination = FarmerPagination.empty();
  bool _isLoading = false;
  bool _isRefreshing = false;
  bool _isLoadingMore = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  String _searchQuery = '';
  String _currentFilter = 'all'; // 'all', 'active', 'pending', 'rejected', 'suspended'

  FarmerItem? _selectedFarmer;
  bool _isLoadingDetail = false;

  // Bank change requests state (Admin)
  List<BankChangeRequestItem> _bankRequests = [];
  FarmerPagination _bankRequestsPagination = FarmerPagination.empty();
  bool _isLoadingBankRequests = false;
  String? _bankRequestsError;

  // Getters
  List<FarmerItem> get farmers => List.unmodifiable(_farmers);
  FarmerPagination get pagination => _pagination;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  bool get isLoadingMore => _isLoadingMore;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get currentFilter => _currentFilter;

  FarmerItem? get selectedFarmer => _selectedFarmer;
  bool get isLoadingDetail => _isLoadingDetail;

  List<BankChangeRequestItem> get bankRequests => List.unmodifiable(_bankRequests);
  FarmerPagination get bankRequestsPagination => _bankRequestsPagination;
  bool get isLoadingBankRequests => _isLoadingBankRequests;
  String? get bankRequestsError => _bankRequestsError;
  bool get bankRequestsHasMore => _bankRequestsPagination.hasNext;

  bool _isLoadingMoreBankRequests = false;
  bool get isLoadingMoreBankRequests => _isLoadingMoreBankRequests;

  int get activeCount => _farmers.where((f) => f.isActive).length;
  int get pendingCount => _farmers.where((f) => f.isPending).length;
  int get totalRecords => _pagination.totalRecords;
  int get pendingBankRequestsCount => _bankRequests.where((r) => r.isPending).length;

  /// Loads initial page of farmers with active filters
  Future<void> loadFarmers({bool refresh = false}) async {
    if (_isLoading) return;

    if (refresh) {
      _isRefreshing = true;
    } else {
      _isLoading = true;
    }
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await repository.getFarmers(
        accessToken: accessToken,
        page: 1,
        pageSize: _pagination.pageSize,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        status: _currentFilter != 'all' ? _currentFilter : null,
      );

      _farmers = List.from(result.items);
      _pagination = result.pagination;
      _errorMessage = null;
    } on FarmerException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = ErrorSanitizer.sanitize(e, defaultAction: 'Loading farmers');
    } finally {
      _isLoading = false;
      _isRefreshing = false;
      notifyListeners();
    }
  }

  /// Pull-to-refresh: replaces current dataset cleanly
  Future<void> refreshFarmers() async {
    await loadFarmers(refresh: true);
  }

  /// Loads next page of farmers and appends to existing list
  Future<void> loadMoreFarmers() async {
    if (_isLoadingMore || !_pagination.hasNext || _isLoading || _isRefreshing) {
      return;
    }

    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _pagination.page + 1;
      final result = await repository.getFarmers(
        accessToken: accessToken,
        page: nextPage,
        pageSize: _pagination.pageSize,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        status: _currentFilter != 'all' ? _currentFilter : null,
      );

      _farmers.addAll(result.items);
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
    loadFarmers();
  }

  /// Sets status filter and reloads dataset
  void setFilter(String filter) {
    if (_currentFilter == filter) return;
    _currentFilter = filter;
    loadFarmers();
  }

  /// Fetches detailed farmer record from `/api/v1/farmers/{farmerId}`
  Future<FarmerItem?> loadFarmerDetail(String farmerId) async {
    _isLoadingDetail = true;
    notifyListeners();

    try {
      final detail = await repository.getFarmerDetail(
        accessToken: accessToken,
        farmerId: farmerId,
      );
      _selectedFarmer = detail;

      // Update in cached list if exists
      final index = _farmers.indexWhere((f) => f.id == farmerId);
      if (index != -1) {
        _farmers[index] = detail;
      }
      return detail;
    } on FarmerException catch (e) {
      _errorMessage = e.message;
      return null;
    } catch (e) {
      _errorMessage = ErrorSanitizer.sanitize(e, defaultAction: 'Loading farmer details');
      return null;
    } finally {
      _isLoadingDetail = false;
      notifyListeners();
    }
  }

  void selectFarmer(FarmerItem farmer) {
    _selectedFarmer = farmer;
    notifyListeners();
  }

  void clearSelectedFarmer() {
    _selectedFarmer = null;
    notifyListeners();
  }

  /// Approves farmer status to 'active'
  Future<bool> approveFarmer(String farmerId) async {
    return _updateApprovalStatus(farmerId, 'active');
  }

  /// Rejects farmer status to 'rejected'
  Future<bool> rejectFarmer(String farmerId) async {
    return _updateApprovalStatus(farmerId, 'rejected');
  }

  /// Suspends farmer status to 'suspended' (Admin only)
  Future<bool> suspendFarmer(String farmerId) async {
    return _updateApprovalStatus(farmerId, 'suspended');
  }

  Future<bool> _updateApprovalStatus(String farmerId, String status) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await repository.setFarmerApproval(
        accessToken: accessToken,
        farmerId: farmerId,
        status: status,
      );

      final index = _farmers.indexWhere((f) => f.id == farmerId);
      if (index != -1) {
        _farmers[index] = updated;
      }

      if (_selectedFarmer?.id == farmerId) {
        _selectedFarmer = updated;
      }

      return true;
    } on FarmerException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = ErrorSanitizer.sanitize(e, defaultAction: 'Updating status');
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Registers a new farmer via POST /api/v1/farmers
  Future<FarmerItem?> createFarmer({
    required String name,
    required String phone,
    required String password,
    String? email,
    String? address,
    double? acresOfLand,
    String? cropAddress,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final created = await repository.createFarmer(
        accessToken: accessToken,
        name: name,
        phone: phone,
        password: password,
        email: email,
        address: address,
        acresOfLand: acresOfLand,
        cropAddress: cropAddress,
      );

      _farmers.insert(0, created);
      _pagination = _pagination.copyWith(
        totalRecords: _pagination.totalRecords + 1,
      );
      return created;
    } on FarmerException catch (e) {
      _errorMessage = e.message;
      return null;
    } catch (e) {
      _errorMessage = ErrorSanitizer.sanitize(e, defaultAction: 'Farmer registration');
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Loads bank change requests for Admin oversight
  Future<void> loadBankChangeRequests({bool refresh = false}) async {
    if (_isLoadingBankRequests) return;
    _isLoadingBankRequests = true;
    _bankRequestsError = null;
    notifyListeners();

    try {
      final result = await repository.getBankChangeRequests(
        accessToken: accessToken,
        page: 1,
        pageSize: 50,
      );
      _bankRequests = List.from(result.items);
      _bankRequestsPagination = result.pagination;
    } on FarmerException catch (e) {
      _bankRequestsError = e.message;
    } catch (e) {
      _bankRequestsError = ErrorSanitizer.sanitize(e, defaultAction: 'Loading bank change requests');
    } finally {
      _isLoadingBankRequests = false;
      notifyListeners();
    }
  }

  /// Loads the next page of bank change requests and appends (rec 9).
  Future<void> loadMoreBankRequests() async {
    if (_isLoadingMoreBankRequests ||
        !_bankRequestsPagination.hasNext ||
        _isLoadingBankRequests) {
      return;
    }

    _isLoadingMoreBankRequests = true;
    notifyListeners();

    try {
      final result = await repository.getBankChangeRequests(
        accessToken: accessToken,
        page: _bankRequestsPagination.page + 1,
        pageSize: _bankRequestsPagination.pageSize,
      );
      _bankRequests = [..._bankRequests, ...result.items];
      _bankRequestsPagination = result.pagination;
    } on FarmerException catch (e) {
      _bankRequestsError = e.message;
    } catch (e) {
      _bankRequestsError = ErrorSanitizer.sanitize(e, defaultAction: 'Loading more bank requests');
    } finally {
      _isLoadingMoreBankRequests = false;
      notifyListeners();
    }
  }

  /// Reviews (approve/reject) a bank change request
  Future<bool> reviewBankChangeRequest({
    required String requestId,
    required bool approve,
    String? adminNotes,
  }) async {
    _isSubmitting = true;
    notifyListeners();

    try {
      await repository.reviewBankChangeRequest(
        accessToken: accessToken,
        requestId: requestId,
        approve: approve,
        adminNotes: adminNotes,
      );

      // Invalidate/refresh requests
      await loadBankChangeRequests();
      return true;
    } on FarmerException catch (e) {
      _bankRequestsError = e.message;
      return false;
    } catch (e) {
      _bankRequestsError = ErrorSanitizer.sanitize(e, defaultAction: 'Reviewing bank change request');
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Partial farmer profile update via PATCH /farmers/{farmer_id} (FEAT-04)
  Future<bool> updateFarmerProfile({
    required String farmerId,
    String? name,
    String? phone,
    String? email,
    String? address,
    double? acresOfLand,
    String? soilType,
    String? irrigationType,
    String? primaryCrop,
    String? secondaryCrop,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await repository.updateFarmerProfile(
        accessToken: accessToken,
        farmerId: farmerId,
        name: name,
        phone: phone,
        email: email,
        address: address,
        acresOfLand: acresOfLand,
        soilType: soilType,
        irrigationType: irrigationType,
        primaryCrop: primaryCrop,
        secondaryCrop: secondaryCrop,
      );

      final index = _farmers.indexWhere((f) => f.id == farmerId);
      if (index != -1) {
        _farmers[index] = updated;
      }
      if (_selectedFarmer?.id == farmerId) {
        _selectedFarmer = updated;
      }
      return true;
    } on FarmerException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = ErrorSanitizer.sanitize(e, defaultAction: 'Updating farmer profile');
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
