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
  String _liveQuery = '';
  String _roleFilter = 'all';
  int _loadEpoch = 0;

  bool _matchesQuery(AuditLogItem item, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return item.action.toLowerCase().contains(q) ||
        (item.actorName ?? '').toLowerCase().contains(q) ||
        (item.actorRole ?? '').toLowerCase().contains(q) ||
        (item.entityType ?? '').toLowerCase().contains(q) ||
        (item.entityId ?? '').toLowerCase().contains(q) ||
        (item.details ?? '').toLowerCase().contains(q) ||
        (item.userId ?? '').toLowerCase().contains(q) ||
        item.id.toLowerCase().contains(q);
  }

  /// Filters already-loaded audit logs immediately while typing.
  void previewSearch(String query) {
    final normalized = query.trim();
    if (_liveQuery == normalized) return;
    _liveQuery = normalized;
    notifyListeners();
  }

  String get roleFilter => _roleFilter;

  List<AuditLogItem> get logs {
    Iterable<AuditLogItem> items = _logs;
    if (_roleFilter != 'all') {
      items = items.where(
        (item) => (item.actorRole ?? '').toLowerCase() == _roleFilter,
      );
    }
    final activeQuery = _liveQuery.isNotEmpty ? _liveQuery : _searchQuery;
    if (activeQuery.isNotEmpty) {
      items = items.where((item) => _matchesQuery(item, activeQuery));
    }
    return List.unmodifiable(items);
  }
  AuditLogPagination get pagination => _pagination;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  int get totalRecords => _pagination.totalRecords;
  bool get hasNext => _pagination.hasNext;

  /// Loads page 1 with the current search query.
  Future<void> loadLogs({bool refresh = false}) async {
    final epoch = ++_loadEpoch;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await repository.getAuditLogs(
        accessToken: accessToken,
        page: 1,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        role: _roleFilter == 'all' ? null : _roleFilter,
      );
      if (epoch != _loadEpoch) return;

      final allItems = List<AuditLogItem>.from(result.items);
      var latestPagination = result.pagination;

      if (_searchQuery.isNotEmpty &&
          allItems.any((item) => !_matchesQuery(item, _searchQuery))) {
        final maxPages = latestPagination.totalPages.clamp(1, 10);
        for (int p = 2; p <= maxPages; p++) {
          final nextRes = await repository.getAuditLogs(
            accessToken: accessToken,
            page: p,
            search: _searchQuery,
            role: _roleFilter == 'all' ? null : _roleFilter,
          );
          if (epoch != _loadEpoch) return;
          if (nextRes.items.isEmpty) break;
          allItems.addAll(nextRes.items);
          latestPagination = nextRes.pagination;
        }
      }

      if (epoch != _loadEpoch) return;
      _logs
        ..clear()
        ..addAll(allItems);
      _pagination = latestPagination;
    } on EventLogsException catch (e) {
      if (epoch != _loadEpoch) return;
      _errorMessage = e.message;
      if (refresh) {
        _logs.clear();
      }
    } catch (e) {
      if (epoch != _loadEpoch) return;
      _errorMessage =
          ErrorSanitizer.sanitize(e, defaultAction: 'Loading event logs');
      if (refresh) {
        _logs.clear();
      }
    } finally {
      if (epoch == _loadEpoch) {
        _isLoading = false;
        notifyListeners();
      }
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
        role: _roleFilter == 'all' ? null : _roleFilter,
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

  /// Filters audit logs by actor role (`all`, `super_admin`, `manager`, `farmer`).
  Future<void> setRoleFilter(String role) async {
    if (_roleFilter == role) return;
    _roleFilter = role;
    await loadLogs();
  }

  /// Server-side search (the contract exposes a `search` query param).
  Future<void> setSearchQuery(String query) async {
    final normalized = query.trim();
    _liveQuery = normalized;
    if (_searchQuery == normalized) {
      notifyListeners();
      return;
    }
    _searchQuery = normalized;
    await loadLogs();
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }
}
