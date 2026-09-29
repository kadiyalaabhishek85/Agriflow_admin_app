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
  List<FarmVisitItem> get visits => List.unmodifiable(_visits);

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

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Active filter chip: 'all', 'scheduled', 'pending_review', 'completed', 'cancelled'
  String _activeFilter = 'all';
  String get activeFilter => _activeFilter;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  // ID of visit currently undergoing mutation
  String? _actionInFlightId;
  String? get actionInFlightId => _actionInFlightId;

  /// Loads the first page of farm visits.
  Future<void> loadVisits() async {
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

      _visits = result.items;
      _pagination = result.pagination;
      _status = FarmVisitViewStatus.success;
    } on FarmVisitException catch (e) {
      _status = FarmVisitViewStatus.error;
      _errorMessage = e.message;
    } catch (e) {
      _status = FarmVisitViewStatus.error;
      _errorMessage = ErrorSanitizer.sanitize(e, defaultAction: 'Loading farm visits');
    } finally {
      notifyListeners();
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
    if (_searchQuery == query) return;
    _searchQuery = query;
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

  /// Authoritatively creates a new farm visit.
  Future<bool> createVisit({
    required String cropId,
    required int visitMonth,
    required String scheduledDate,
    String? staffId,
  }) async {
    _status = FarmVisitViewStatus.loading;
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
      _status = FarmVisitViewStatus.error;
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _status = FarmVisitViewStatus.error;
      _errorMessage = ErrorSanitizer.sanitize(e, defaultAction: 'Creating visit');
      return false;
    } finally {
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
