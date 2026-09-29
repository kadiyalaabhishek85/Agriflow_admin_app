import 'package:flutter/foundation.dart';

import '../../../../core/network/error_sanitizer.dart';
import '../../domain/entities/manager_item.dart';
import '../../domain/entities/manager_pagination.dart';
import '../../domain/entities/managers_exception.dart';
import '../../domain/repositories/manager_repository.dart';

/// State management controller for the Managers admin module (M7-1).
///
/// RBAC: the Managers route is `adminOnly` (Super Admin & Admin only —
/// AGENTS §3); the manager shell never reaches this controller.
class ManagerController extends ChangeNotifier {
  final ManagerRepository repository;
  final String accessToken;

  ManagerController({
    required this.repository,
    required this.accessToken,
  });

  final List<ManagerItem> _managers = [];
  ManagerPagination _pagination = ManagerPagination.empty();
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  String _searchQuery = '';
  String _statusFilter = 'all';

  List<ManagerItem> get managers => List.unmodifiable(_managers);
  ManagerPagination get pagination => _pagination;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get statusFilter => _statusFilter;
  int get totalRecords => _pagination.totalRecords;
  bool get hasNext => _pagination.hasNext;

  /// Active / Suspended counts for the header stat cards.
  int get activeCount =>
      _managers.where((m) => m.status == 'active').length;
  int get suspendedCount =>
      _managers.where((m) => m.status == 'suspended').length;

  /// Loads page 1 with the current search/status filters.
  Future<void> loadManagers({bool refresh = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await repository.getManagers(
        accessToken: accessToken,
        page: 1,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        status: _statusFilter == 'all' ? null : _statusFilter,
      );
      _managers
        ..clear()
        ..addAll(result.items);
      _pagination = result.pagination;
    } on ManagersException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage =
          ErrorSanitizer.sanitize(e, defaultAction: 'Loading managers');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Appends the next page (server-side search/status preserved).
  Future<void> loadMoreManagers() async {
    if (_isLoading || _isLoadingMore || !_pagination.hasNext) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final result = await repository.getManagers(
        accessToken: accessToken,
        page: _pagination.page + 1,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        status: _statusFilter == 'all' ? null : _statusFilter,
      );
      _managers.addAll(result.items);
      _pagination = result.pagination;
    } on ManagersException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage =
          ErrorSanitizer.sanitize(e, defaultAction: 'Loading more managers');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Server-side search (the contract exposes a `search` query param).
  Future<void> setSearchQuery(String query) async {
    if (_searchQuery == query) return;
    _searchQuery = query;
    await loadManagers();
  }

  /// Status chip filter: 'all' | 'active' | 'suspended'.
  Future<void> setStatusFilter(String status) async {
    if (_statusFilter == status) return;
    _statusFilter = status;
    await loadManagers();
  }

  /// Creates a manager via `POST /managers` and prepends the result.
  /// Returns true only on success.
  Future<bool> createManager({
    required String name,
    required String phone,
    required String password,
    String? email,
    String? assignedRegion,
    String? department,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final created = await repository.createManager(
        accessToken: accessToken,
        name: name.trim(),
        phone: phone.trim(),
        password: password,
        email: (email == null || email.trim().isEmpty) ? null : email.trim(),
        assignedRegion: (assignedRegion == null ||
                assignedRegion.trim().isEmpty)
            ? null
            : assignedRegion.trim(),
        department:
            (department == null || department.trim().isEmpty) ? null : department.trim(),
      );
      _managers.insert(0, created);
      _pagination = _pagination.copyWith(
        totalRecords: _pagination.totalRecords + 1,
      );
      return true;
    } on ManagersException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage =
          ErrorSanitizer.sanitize(e, defaultAction: 'Creating manager');
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Activates or suspends a manager via `PATCH /managers/{id}/status`.
  /// Returns true only on success; on failure the list keeps the old state.
  Future<bool> setManagerStatus({
    required String managerId,
    required String status,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await repository.updateManagerStatus(
        accessToken: accessToken,
        managerId: managerId,
        status: status,
      );
      final index = _managers.indexWhere((m) => m.id == managerId);
      if (index != -1) {
        _managers[index] = updated;
      }
      return true;
    } on ManagersException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage =
          ErrorSanitizer.sanitize(e, defaultAction: 'Updating manager status');
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Resets a manager password via `POST /managers/{id}/reset-password`.
  /// Returns the backend message on success, null on failure (with
  /// `errorMessage` populated for inline display).
  Future<String?> resetManagerPassword({
    required String managerId,
    required String newPassword,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final message = await repository.resetManagerPassword(
        accessToken: accessToken,
        managerId: managerId,
        newPassword: newPassword,
      );
      return message;
    } on ManagersException catch (e) {
      _errorMessage = e.message;
      return null;
    } catch (e) {
      _errorMessage =
          ErrorSanitizer.sanitize(e, defaultAction: 'Resetting password');
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }
}
