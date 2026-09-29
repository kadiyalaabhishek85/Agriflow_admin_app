import 'package:flutter/foundation.dart';
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

  List<BookingItem> _bookings = [];
  List<BookingItem> get bookings {
    if (_selectedDate == null) return List.unmodifiable(_bookings);
    // Filter bookings by selected date (YYYY-MM-DD)
    final dateStr = '${_selectedDate!.year.toString().padLeft(4, '0')}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';
    return List.unmodifiable(_bookings.where((b) => b.bookingDate == dateStr));
  }

  BookingPagination _pagination = BookingPagination.empty();
  BookingPagination get pagination => _pagination;

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
  String get searchQuery => _searchQuery;

  // ID of booking currently undergoing mutation
  String? _actionInFlightId;
  String? get actionInFlightId => _actionInFlightId;

  /// Loads the first page of bookings.
  Future<void> loadBookings() async {
    _status = BookingViewStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await repository.getBookings(
        accessToken: accessToken,
        page: 1,
        pageSize: 20,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        status: _activeFilter == 'all' ? null : _activeFilter,
      );

      _bookings = result.items;
      _pagination = result.pagination;
      _status = BookingViewStatus.success;
    } on BookingException catch (e) {
      _status = BookingViewStatus.error;
      _errorMessage = e.message;
    } catch (e) {
      _status = BookingViewStatus.error;
      _errorMessage = ErrorSanitizer.sanitize(e, defaultAction: 'Loading bookings');
    } finally {
      notifyListeners();
    }
  }

  /// Refreshes the dataset, replacing existing items.
  Future<void> refreshBookings() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await repository.getBookings(
        accessToken: accessToken,
        page: 1,
        pageSize: 20,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        status: _activeFilter == 'all' ? null : _activeFilter,
      );

      _bookings = result.items;
      _pagination = result.pagination;
      _status = BookingViewStatus.success;
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
      final result = await repository.getBookings(
        accessToken: accessToken,
        page: nextPage,
        pageSize: 20,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        status: _activeFilter == 'all' ? null : _activeFilter,
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
    if (_activeFilter == filter) return;
    _activeFilter = filter.toLowerCase();
    loadBookings();
  }

  /// Updates selected date filter without triggering network call if already loaded
  void setDateFilter(DateTime? date) {
    _selectedDate = date;
    notifyListeners();
  }

  /// Updates search query and reloads.
  void setSearch(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
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
      if (index != -1) {
        _bookings[index] = updatedItem;
      }
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
