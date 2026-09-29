import 'package:flutter/foundation.dart';

import '../../../../core/network/error_sanitizer.dart';
import '../../domain/entities/audit_log_item.dart';
import '../../domain/entities/audit_log_pagination.dart';
import '../../domain/entities/event_logs_exception.dart';
import '../../domain/repositories/event_log_repository.dart';

/// State management controller for the Event Logs module (M7-3).
class EventLogController extends ChangeNotifier {
  final EventLogRepository repository;
  final String accessToken;

  EventLogController({
    required this.repository,
    required this.accessToken,
  });

  final List<AuditLogItem> _logs = [];
  AuditLogPagination _pagination = AuditLogPagination.empty();
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  String _searchQuery = '';

  List<AuditLogItem> get logs => List.unmodifiable(_logs);
  AuditLogPagination get pagination => _pagination;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  int get totalRecords => _pagination.totalRecords;
  bool get hasNext => _pagination.hasNext;

  /// Loads page 1 with the current search query.
  Future<void> loadLogs({bool refresh = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await repository.getAuditLogs(
        accessToken: accessToken,
        page: 1,
        search: _searchQuery.isEmpty ? null : _searchQuery,
      );
      _logs
        ..clear()
        ..addAll(result.items);
      _pagination = result.pagination;
    } on EventLogsException catch (e) {
      _errorMessage = e.message;
      if (refresh) {
        _logs.clear();
      }
    } catch (e) {
      _errorMessage =
          ErrorSanitizer.sanitize(e, defaultAction: 'Loading event logs');
      if (refresh) {
        _logs.clear();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Appends the next page (server-side search preserved).
  Future<void> loadMoreLogs() async {
    if (_isLoading || _isLoadingMore || !_pagination.hasNext) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final result = await repository.getAuditLogs(
        accessToken: accessToken,
        page: _pagination.page + 1,
        search: _searchQuery.isEmpty ? null : _searchQuery,
      );
      _logs.addAll(result.items);
      _pagination = result.pagination;
    } on EventLogsException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage =
          ErrorSanitizer.sanitize(e, defaultAction: 'Loading more events');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Server-side search (the contract exposes a `search` query param).
  Future<void> setSearchQuery(String query) async {
    if (_searchQuery == query) return;
    _searchQuery = query;
    await loadLogs();
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }
}
