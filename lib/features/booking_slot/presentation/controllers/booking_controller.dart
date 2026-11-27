import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:agriflow_admin/features/booking_slot/data/repositories/booking_repository_impl.dart';
import 'package:agriflow_admin/features/booking_slot/domain/entities/booking_exception.dart';
import 'package:agriflow_admin/features/booking_slot/domain/entities/booking_item.dart';
import 'package:agriflow_admin/features/booking_slot/domain/entities/booking_pagination.dart';
import 'package:agriflow_admin/features/booking_slot/domain/repositories/booking_repository.dart';
import 'package:agriflow_admin/core/network/error_sanitizer.dart';

enum BookingViewStatus {
  initial,
  loading,
  success,
  error,
}

class BookingController extends ChangeNotifier {
  final BookingRepository repository;
  final String accessToken;

  BookingController({
    required this.repository,
    required this.accessToken,
  });

  BookingViewStatus _status = BookingViewStatus.initial;
  BookingViewStatus get status => _status;

  bool get isLoading => _status == BookingViewStatus.loading;
  bool get isSuccess => _status == BookingViewStatus.success;
  bool get isError => _status == BookingViewStatus.error;

  static const List<String> _allStatuses = [
    'pending',
    'confirmed',
    'delivered',
    'inspected',
    'completed',
    'cancelled',
  ];

  List<BookingItem> _bookings = [];
  List<BookingItem> get bookings {
    Iterable<BookingItem> list = _bookings;
    final dateStr = _formattedSelectedDate;
    if (dateStr != null) {
      list = list.where((b) => b.bookingDate == dateStr);
    }
    final activeQuery = _liveQuery.isNotEmpty ? _liveQuery : _searchQuery;
    if (activeQuery.isNotEmpty) {
      list = list.where((b) => _matchesQuery(b, activeQuery));
    }
    return List.unmodifiable(list);
  }

  String? get _formattedSelectedDate {
    final date = _selectedDate;
    if (date == null) return null;
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  static bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  BookingPagination _pagination = BookingPagination.empty();
  BookingPagination get pagination => _pagination;

  final Map<String, int> _statusCounts = {};
  int _countsEpoch = 0;

  Map<String, int> _computeCountsFromList(List<BookingItem> items) {
    final counts = <String, int>{'all': items.length};
    for (final s in _allStatuses) {
      counts[s] = 0;
    }
    for (final item in items) {
      final status = item.status.toLowerCase();
      counts[status] = (counts[status] ?? 0) + 1;
    }
    return counts;
  }

  /// Returns cached total count for a booking status chip, or active total when loaded.
  int? countForFilter(String filter) {
    final key = filter.toLowerCase();
    final hasLiveDelta = _liveQuery != _searchQuery;
    if (_status == BookingViewStatus.success &&
        (hasLiveDelta || _clientFiltered || (_activeFilter == 'all' && !_pagination.hasMore))) {
      final visible = bookings;
      if (_activeFilter == 'all' && (!_pagination.hasMore || _clientFiltered)) {
        if (key == 'all') return visible.length;
        return visible.where((b) => b.status.toLowerCase() == key).length;
      }
      if (key == _activeFilter && (hasLiveDelta || _clientFiltered)) {
        return visible.length;
      }
    }
    if (key == _activeFilter && _status == BookingViewStatus.success) {
      return _pagination.total;
    }
    return _statusCounts[key];
  }

  Future<({List<BookingItem> items, BookingPagination pagination})> _fetchBookings({
    required int page,
    int pageSize = 20,
    String? search,
    String? status,
    String? bookingDate,
  }) {
    final repo = repository;
    if (repo is BookingRepositoryImpl) {
      return repo.getBookings(
        accessToken: accessToken,
        page: page,
        pageSize: pageSize,
        search: search,
        status: status,
        bookingDate: bookingDate,
      );
    }
    return repo.getBookings(
      accessToken: accessToken,
      page: page,
      pageSize: pageSize,
      search: search,
      status: status,
    );
  }

  void _applyCountsFromLoadedResult({
    required String searchSnapshot,
    required String? dateSnapshot,
    required BookingPagination latestPagination,
  }) {
    if (_clientFiltered || (_activeFilter == 'all' && !latestPagination.hasMore)) {
      if (_activeFilter == 'all') {
        _countsEpoch++;
        _statusCounts
          ..clear()
          ..addAll(_computeCountsFromList(bookings));
        return;
      }
      _statusCounts[_activeFilter] = bookings.length;
      if (!_clientFiltered) {
        unawaited(_refreshStatusCounts(
          searchSnapshot: searchSnapshot,
          bookingDateSnapshot: dateSnapshot,
          known: {_activeFilter: latestPagination.total},
        ));
      }
      return;
    }

    _statusCounts[_activeFilter] = latestPagination.total;
    unawaited(_refreshStatusCounts(
      searchSnapshot: searchSnapshot,
      bookingDateSnapshot: dateSnapshot,
      known: {_activeFilter: latestPagination.total},
    ));
  }

  Future<void> _refreshStatusCounts({
    required String searchSnapshot,
    required String? bookingDateSnapshot,
    required Map<String, int> known,
  }) async {
    final repo = repository;
    if (repo is! BookingRepositoryImpl) return;
    final epoch = ++_countsEpoch;
    final counts = await repo.getStatusCounts(
      accessToken: accessToken,
      search: searchSnapshot,
      bookingDate: bookingDateSnapshot,
      seedKnown: known,
    );
    if (epoch != _countsEpoch ||
        bookingDateSnapshot != _formattedSelectedDate ||
        searchSnapshot != _searchQuery) {
      return;
    }
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

  // Active status filter: 'all', 'pending', 'confirmed', 'delivered', 'inspected', 'completed', 'cancelled'
  String _activeFilter = 'all';
  String get activeFilter => _activeFilter;

  // Selected date from date selector strip
  DateTime? _selectedDate;
  DateTime? get selectedDate => _selectedDate;

  String _searchQuery = '';
  String _liveQuery = '';
  bool _clientFiltered = false;
  int _loadEpoch = 0;
  String get searchQuery => _searchQuery;

  // ID of booking currently undergoing mutation
  String? _actionInFlightId;
  String? get actionInFlightId => _actionInFlightId;

  bool _matchesQuery(BookingItem item, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return item.displayName.toLowerCase().contains(q) ||
        item.displayPhone.toLowerCase().contains(q) ||
        item.grainType.toLowerCase().contains(q) ||
        item.displayWarehouse.toLowerCase().contains(q) ||
        item.bookingDate.toLowerCase().contains(q) ||
        item.status.toLowerCase().contains(q) ||
        item.id.toLowerCase().contains(q);
  }

  /// Immediately filters loaded bookings while user types before debounced fetch.
  void previewSearch(String query) {
    final normalized = query.trim();
    if (_liveQuery == normalized) return;
    _liveQuery = normalized;
    notifyListeners();
  }

  /// Loads the first page of bookings.
  Future<void> loadBookings() async {
    final epoch = ++_loadEpoch;
    final dateSnapshot = _formattedSelectedDate;
    final searchSnapshot = _searchQuery;
    _status = BookingViewStatus.loading;
    _errorMessage = null;
    _clientFiltered = false;
    notifyListeners();

    try {
      final result = await _fetchBookings(
        page: 1,
        pageSize: 20,
        search: searchSnapshot.isEmpty ? null : searchSnapshot,
        status: _activeFilter == 'all' ? null : _activeFilter,
        bookingDate: dateSnapshot,
      );
      if (epoch != _loadEpoch) return;

      final allItems = List<BookingItem>.from(result.items);
      var latestPagination = result.pagination;

      final hasUnfilteredServerSearch = searchSnapshot.isNotEmpty &&
          allItems.any((item) => !_matchesQuery(item, searchSnapshot));
      final hasUnfilteredServerDate = dateSnapshot != null &&
          allItems.any((item) => item.bookingDate != dateSnapshot);

      if (hasUnfilteredServerSearch || hasUnfilteredServerDate) {
        _clientFiltered = true;
        final maxPages = latestPagination.totalPages.clamp(1, 10);
        for (int p = 2; p <= maxPages; p++) {
          final nextRes = await _fetchBookings(
            page: p,
            pageSize: 20,
            search: searchSnapshot.isEmpty ? null : searchSnapshot,
            status: _activeFilter == 'all' ? null : _activeFilter,
            bookingDate: dateSnapshot,
          );
          if (epoch != _loadEpoch) return;
          if (nextRes.items.isEmpty) break;
          allItems.addAll(nextRes.items);
          latestPagination = nextRes.pagination;
        }
      }

      if (epoch != _loadEpoch) return;
      _bookings = allItems;
      _pagination = latestPagination;
      _status = BookingViewStatus.success;

      _applyCountsFromLoadedResult(
        searchSnapshot: searchSnapshot,
        dateSnapshot: dateSnapshot,
        latestPagination: latestPagination,
      );
    } on BookingException catch (e) {
      if (epoch != _loadEpoch) return;
      _status = BookingViewStatus.error;
      _errorMessage = e.message;
    } catch (e) {
      if (epoch != _loadEpoch) return;
      _status = BookingViewStatus.error;
      _errorMessage = ErrorSanitizer.sanitize(e, defaultAction: 'Loading bookings');
    } finally {
      if (epoch == _loadEpoch) {
        notifyListeners();
      }
    }
  }

  /// Refreshes the dataset, replacing existing items.
  Future<void> refreshBookings() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    _errorMessage = null;
    notifyListeners();

    final dateSnapshot = _formattedSelectedDate;
    final searchSnapshot = _searchQuery;

    try {
      final result = await _fetchBookings(
        page: 1,
        pageSize: 20,
        search: searchSnapshot.isEmpty ? null : searchSnapshot,
        status: _activeFilter == 'all' ? null : _activeFilter,
        bookingDate: dateSnapshot,
      );

      _bookings = result.items;
      _pagination = result.pagination;
      _status = BookingViewStatus.success;
      _clientFiltered = (searchSnapshot.isNotEmpty &&
              result.items.any((item) => !_matchesQuery(item, searchSnapshot))) ||
          (dateSnapshot != null &&
              result.items.any((item) => item.bookingDate != dateSnapshot));
      _applyCountsFromLoadedResult(
        searchSnapshot: searchSnapshot,
        dateSnapshot: dateSnapshot,
        latestPagination: result.pagination,
      );
    } on BookingException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = ErrorSanitizer.sanitize(e, defaultAction: 'Refreshing bookings');
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  /// Appends next page of bookings if more exist.
  Future<void> loadMoreBookings() async {
    if (_isLoadingMore || !_pagination.hasMore || isLoading) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _pagination.page + 1;
      final result = await _fetchBookings(
        page: nextPage,
        pageSize: 20,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        status: _activeFilter == 'all' ? null : _activeFilter,
        bookingDate: _formattedSelectedDate,
      );

      _bookings.addAll(result.items);
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
    final normalized = filter.toLowerCase();
    if (_activeFilter == normalized) return;
    _activeFilter = normalized;
    loadBookings();
  }

  /// Updates selected date filter and reloads bookings & counts for that date.
  void setDateFilter(DateTime? date) {
    if (_isSameDay(_selectedDate, date)) return;
    _selectedDate = date;
    _countsEpoch++;
    _statusCounts.clear();
    unawaited(loadBookings());
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
    _countsEpoch++;
    _statusCounts.clear();
    loadBookings();
  }

  /// Authoritatively updates booking status on the backend.
  Future<bool> updateStatus({
    required String bookingId,
    required String newStatus,
    String? notes,
  }) async {
    _actionInFlightId = bookingId;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedItem = await repository.updateBookingStatus(
        accessToken: accessToken,
        bookingId: bookingId,
        newStatus: newStatus,
        notes: notes,
      );

      // Authoritative replacement from backend response
      final index = _bookings.indexWhere((b) => b.id == bookingId);
      final oldStatus = index != -1 ? _bookings[index].status.toLowerCase() : null;
      if (index != -1) {
        _bookings[index] = updatedItem;
      }
      final nextStatus = updatedItem.status.toLowerCase();
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
        bookingDateSnapshot: _formattedSelectedDate,
        known: const {},
      ));
      return true;
    } on BookingException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = ErrorSanitizer.sanitize(e, defaultAction: 'Updating booking status');
      return false;
    } finally {
      _actionInFlightId = null;
      notifyListeners();
    }
  }

  /// Records crop inspection via POST /bookings/{id}/inspect, then refreshes
  /// the list so the backend's resulting status change is reflected.
  Future<bool> inspectBooking({
    required String bookingId,
    required double goodQuantityKg,
    required double badQuantityKg,
    String? rejectionReason,
    String? notes,
  }) async {
    _actionInFlightId = bookingId;
    _errorMessage = null;
    notifyListeners();

    try {
      await repository.inspectBooking(
        accessToken: accessToken,
        bookingId: bookingId,
        goodQuantityKg: goodQuantityKg,
        badQuantityKg: badQuantityKg,
        rejectionReason: rejectionReason,
        notes: notes,
      );
      return true;
    } on BookingException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = ErrorSanitizer.sanitize(e, defaultAction: 'Recording inspection');
      return false;
    } finally {
      _actionInFlightId = null;
      notifyListeners();
    }
  }
}
