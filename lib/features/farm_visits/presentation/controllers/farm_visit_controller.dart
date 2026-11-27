import 'package:flutter/foundation.dart';
import '../../domain/entities/farm_visit_exception.dart';
import '../../domain/entities/farm_visit_item.dart';
import '../../domain/entities/farm_visit_pagination.dart';
import '../../domain/repositories/farm_visit_repository.dart';
import '../../../../core/network/error_sanitizer.dart';

enum FarmVisitViewStatus {
  initial,
  loading,
  success,
  error,
}

class FarmVisitController extends ChangeNotifier {
  final FarmVisitRepository repository;
  final String accessToken;

  FarmVisitController({
    required this.repository,
    required this.accessToken,
  });

  FarmVisitViewStatus _status = FarmVisitViewStatus.initial;
  FarmVisitViewStatus get status => _status;

  bool get isLoading => _status == FarmVisitViewStatus.loading;
  bool get isSuccess => _status == FarmVisitViewStatus.success;
  bool get isError => _status == FarmVisitViewStatus.error;

  List<FarmVisitItem> _visits = [];
  List<FarmVisitItem> get visits {
    final activeQuery = _liveQuery.isNotEmpty ? _liveQuery : _searchQuery;
    if (activeQuery.isEmpty) {
      return List.unmodifiable(_visits);
    }
    return List.unmodifiable(
      _visits.where((item) => _matchesQuery(item, activeQuery)),
    );
  }

  FarmVisitPagination _pagination = const FarmVisitPagination(
    page: 1,
    pageSize: 20,
    total: 0,
    totalPages: 1,
  );
  FarmVisitPagination get pagination => _pagination;

  bool _isRefreshing = false;
  bool get isRefreshing => _isRefreshing;

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Active filter chip: 'all', 'scheduled', 'pending_review', 'completed', 'cancelled'
  String _activeFilter = 'all';
  String get activeFilter => _activeFilter;

  String _searchQuery = '';
  String _liveQuery = '';
  int _loadEpoch = 0;
  String get searchQuery => _searchQuery;

  // ID of visit currently undergoing mutation
  String? _actionInFlightId;
  String? get actionInFlightId => _actionInFlightId;

  bool _matchesQuery(FarmVisitItem item, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return item.displayFarmerName.toLowerCase().contains(q) ||
        (item.enrichedFarmerPhone ?? '').toLowerCase().contains(q) ||
        item.displayVillage.toLowerCase().contains(q) ||
        item.displayCropName.toLowerCase().contains(q) ||
        item.displayStaffName.toLowerCase().contains(q) ||
        (item.scheduledDate ?? '').toLowerCase().contains(q) ||
        item.status.toLowerCase().contains(q) ||
        item.id.toLowerCase().contains(q);
  }

  /// Filters already-loaded farm visits immediately while typing.
  void previewSearch(String query) {
    final normalized = query.trim();
    if (_liveQuery == normalized) return;
    _liveQuery = normalized;
    notifyListeners();
  }

  /// Loads the first page of farm visits.
  Future<void> loadVisits() async {
    final epoch = ++_loadEpoch;
    _status = FarmVisitViewStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await repository.getVisits(
        accessToken: accessToken,
        page: 1,
        pageSize: 20,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        status: _activeFilter == 'all' ? null : _activeFilter,
      );
      if (epoch != _loadEpoch) return;

      final allItems = List<FarmVisitItem>.from(result.items);
      var latestPagination = result.pagination;

      if (_searchQuery.isNotEmpty &&
          allItems.any((item) => !_matchesQuery(item, _searchQuery))) {
        final maxPages = latestPagination.totalPages.clamp(1, 10);
        for (int p = 2; p <= maxPages; p++) {
          final nextRes = await repository.getVisits(
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
      _visits = allItems;
      _pagination = latestPagination;
      _status = FarmVisitViewStatus.success;
    } on FarmVisitException catch (e) {
      if (epoch != _loadEpoch) return;
      _status = FarmVisitViewStatus.error;
      _errorMessage = e.message;
    } catch (e) {
      if (epoch != _loadEpoch) return;
      _status = FarmVisitViewStatus.error;
      _errorMessage = ErrorSanitizer.sanitize(e, defaultAction: 'Loading farm visits');
    } finally {
      if (epoch == _loadEpoch) {
        notifyListeners();
      }
    }
  }

  /// Refreshes the dataset, replacing existing items.
  Future<void> refreshVisits() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await repository.getVisits(
        accessToken: accessToken,
        page: 1,
        pageSize: 20,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        status: _activeFilter == 'all' ? null : _activeFilter,
      );

      _visits = result.items;
      _pagination = result.pagination;
      _status = FarmVisitViewStatus.success;
    } on FarmVisitException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = ErrorSanitizer.sanitize(e, defaultAction: 'Refreshing farm visits');
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  /// Appends next page of visits if more exist.
  Future<void> loadMoreVisits() async {
    if (_isLoadingMore || !_pagination.hasMore || isLoading) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _pagination.page + 1;
      final result = await repository.getVisits(
        accessToken: accessToken,
        page: nextPage,
        pageSize: 20,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        status: _activeFilter == 'all' ? null : _activeFilter,
      );

      _visits.addAll(result.items);
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
    _activeFilter = filter;
    loadVisits();
  }

  /// Updates search query and reloads.
  void setSearchQuery(String query) {
    final normalized = query.trim();
    _liveQuery = normalized;
    if (_searchQuery == normalized) {
      notifyListeners();
      return;
    }
    _searchQuery = normalized;
    loadVisits();
  }

  /// Authoritatively schedules / reschedules a visit date or assigns staff.
  Future<bool> scheduleVisit({
    required String visitId,
    String? scheduledDate,
    String? staffId,
  }) async {
    if (_actionInFlightId != null) return false;
    _actionInFlightId = visitId;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await repository.scheduleVisit(
        accessToken: accessToken,
        visitId: visitId,
        scheduledDate: scheduledDate,
        staffId: staffId,
      );

      final index = _visits.indexWhere((v) => v.id == visitId);
      if (index != -1) {
        _visits[index] = updated;
      }
      return true;
    } on FarmVisitException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = ErrorSanitizer.sanitize(e, defaultAction: 'Scheduling visit');
      return false;
    } finally {
      _actionInFlightId = null;
      notifyListeners();
    }
  }

  /// Authoritatively completes a farm visit.
  Future<bool> completeVisit({
    required String visitId,
    required String verifiedAcres,
    required String report,
    String? diagnosis,
    String? recommendation,
  }) async {
    if (_actionInFlightId != null) return false;
    _actionInFlightId = visitId;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await repository.completeVisit(
        accessToken: accessToken,
        visitId: visitId,
        verifiedAcres: verifiedAcres,
        report: report,
        diagnosis: diagnosis,
        recommendation: recommendation,
      );

      final index = _visits.indexWhere((v) => v.id == visitId);
      if (index != -1) {
        _visits[index] = updated;
      }
      return true;
    } on FarmVisitException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = ErrorSanitizer.sanitize(e, defaultAction: 'Completing visit');
      return false;
    } finally {
      _actionInFlightId = null;
      notifyListeners();
    }
  }

  /// Authoritatively creates a new farm visit without tearing down the
  /// already-loaded visits list behind the modal sheet on validation errors.
  Future<bool> createVisit({
    required String cropId,
    required int visitMonth,
    required String scheduledDate,
    String? staffId,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await repository.createVisit(
        accessToken: accessToken,
        cropId: cropId,
        visitMonth: visitMonth,
        scheduledDate: scheduledDate,
        staffId: staffId,
      );
      await loadVisits();
      return true;
    } on FarmVisitException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = ErrorSanitizer.sanitize(e, defaultAction: 'Creating visit');
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Sends visit reminders. Returns the backend message on success,
  /// null on failure (see [errorMessage]).
  Future<String?> sendVisitReminders({int daysAhead = 2}) async {
    _errorMessage = null;
    try {
      return await repository.sendVisitReminders(
        accessToken: accessToken,
        daysAhead: daysAhead,
      );
    } on FarmVisitException catch (e) {
      _errorMessage = e.message;
      return null;
    } catch (e) {
      _errorMessage = ErrorSanitizer.sanitize(e, defaultAction: 'Sending visit reminders');
      return null;
    }
  }

  /// Crop options for the schedule-visit form.
  Future<Map<String, ({String cropType, String acres})>> getCropOptions() {
    return repository.getCropOptions(accessToken: accessToken);
  }

  /// Staff options for optional visit assignment.
  Future<Map<String, ({String name, String phone})>> getStaffOptions() {
    return repository.getStaffOptions(accessToken: accessToken);
  }

  /// Upload field photo captured via camera or file picker for a visit.
  Future<String?> uploadVisitPhoto({
    required List<int> fileBytes,
    required String fileName,
    String contentType = 'image/jpeg',
  }) async {
    _errorMessage = null;
    try {
      return await repository.uploadVisitPhoto(
        accessToken: accessToken,
        fileBytes: fileBytes,
        fileName: fileName,
        contentType: contentType,
      );
    } on FarmVisitException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      rethrow;
    } catch (e) {
      _errorMessage = ErrorSanitizer.sanitize(e, defaultAction: 'Uploading visit photo');
      notifyListeners();
      rethrow;
    }
  }
}
