import 'package:agriflow_admin/features/booking_slot/data/datasources/booking_remote_data_source.dart';
import 'package:agriflow_admin/features/booking_slot/domain/entities/booking_item.dart';
import 'package:agriflow_admin/features/booking_slot/domain/entities/booking_pagination.dart';
import 'package:agriflow_admin/features/booking_slot/domain/entities/warehouse_item.dart';
import 'package:agriflow_admin/features/booking_slot/domain/repositories/booking_repository.dart';

class BookingRepositoryImpl implements BookingRepository {
  final BookingRemoteDataSource remoteDataSource;

  // In-memory cache for relationship enrichment
  final Map<String, WarehouseItem> _warehousesCache = {};
  final Map<String, ({String name, String phone})> _farmersCache = {};
  bool _catalogsLoaded = false;

  BookingRepositoryImpl({required this.remoteDataSource});

  Future<void> _ensureCatalogsLoaded(String accessToken) async {
    if (_catalogsLoaded) return;
    try {
      final warehousesFuture = remoteDataSource.getWarehouses(accessToken: accessToken);
      final farmersFuture = remoteDataSource.getFarmerLookup(accessToken: accessToken);

      final results = await Future.wait([warehousesFuture, farmersFuture]);
      final warehousesList = results[0] as List<WarehouseItem>;
      final farmersMap = results[1] as Map<String, ({String name, String phone})>;

      for (final wh in warehousesList) {
        _warehousesCache[wh.id] = wh;
      }
      _farmersCache.addAll(farmersMap);
      _catalogsLoaded = true;
    } catch (_) {
      // Enrichment failure should not block booking display
    }
  }

  BookingItem _enrichItem(BookingItem item) {
    final wh = _warehousesCache[item.warehouseId];
    final farmer = _farmersCache[item.farmerId];

    return item.copyWithEnrichment(
      farmerName: farmer?.name,
      farmerPhone: farmer?.phone,
      warehouseName: wh?.name,
      warehouseAddress: wh?.address,
    );
  }

  Future<({List<BookingItem> items, BookingPagination pagination})> _fetchRawBookings({
    required String accessToken,
    required int page,
    required int pageSize,
    String? search,
    String? status,
    String? bookingDate,
  }) {
    final ds = remoteDataSource;
    if (ds is BookingRemoteDataSourceImpl) {
      return ds.getBookings(
        accessToken: accessToken,
        page: page,
        pageSize: pageSize,
        search: search,
        status: status,
        bookingDate: bookingDate,
      );
    }
    return ds.getBookings(
      accessToken: accessToken,
      page: page,
      pageSize: pageSize,
      search: search,
      status: status,
    );
  }

  @override
  Future<({List<BookingItem> items, BookingPagination pagination})> getBookings({
    required String accessToken,
    int page = 1,
    int pageSize = 20,
    String? search,
    String? status,
    String? bookingDate,
  }) async {
    // 1. Fetch raw bookings from backend
    final result = await _fetchRawBookings(
      accessToken: accessToken,
      page: page,
      pageSize: pageSize,
      search: search,
      status: status,
      bookingDate: bookingDate,
    );

    // 2. Ensure relationship lookup catalogs are warm
    await _ensureCatalogsLoaded(accessToken);

    // 3. Enrich items with farmer & warehouse metadata
    final enrichedItems = result.items.map(_enrichItem).toList();

    return (items: enrichedItems, pagination: result.pagination);
  }

  @override
  Future<BookingItem> updateBookingStatus({
    required String accessToken,
    required String bookingId,
    required String newStatus,
    String? notes,
  }) async {
    final updated = await remoteDataSource.updateBookingStatus(
      accessToken: accessToken,
      bookingId: bookingId,
      newStatus: newStatus,
      notes: notes,
    );
    return _enrichItem(updated);
  }

  @override
  Future<void> inspectBooking({
    required String accessToken,
    required String bookingId,
    required double goodQuantityKg,
    required double badQuantityKg,
    String? rejectionReason,
    String? notes,
  }) {
    return remoteDataSource.inspectBooking(
      accessToken: accessToken,
      bookingId: bookingId,
      goodQuantityKg: goodQuantityKg,
      badQuantityKg: badQuantityKg,
      rejectionReason: rejectionReason,
      notes: notes,
    );
  }

  @override
  Future<List<WarehouseItem>> getWarehouses({required String accessToken}) async {
    await _ensureCatalogsLoaded(accessToken);
    return _warehousesCache.values.toList();
  }

  @override
  Future<Map<String, ({String name, String phone})>> getFarmerLookup({
    required String accessToken,
  }) async {
    await _ensureCatalogsLoaded(accessToken);
    return _farmersCache;
  }

  /// Fetches lightweight (`pageSize: 1`) total counts for each booking status chip.
  Future<Map<String, int>> getStatusCounts({
    required String accessToken,
    String? search,
    String? bookingDate,
    Map<String, int> seedKnown = const {},
  }) async {
    const statuses = [
      'all',
      'pending',
      'confirmed',
      'delivered',
      'inspected',
      'completed',
      'cancelled',
    ];
    final result = Map<String, int>.from(seedKnown);
    final pendingStatuses = statuses.where((s) => !result.containsKey(s)).toList();
    if (pendingStatuses.isEmpty) return result;

    final normalizedSearch =
        (search == null || search.trim().isEmpty) ? null : search.trim();
    final normalizedDate =
        (bookingDate == null || bookingDate.trim().isEmpty) ? null : bookingDate.trim();

    final entries = await Future.wait(
      pendingStatuses.map((status) async {
        try {
          final res = await _fetchRawBookings(
            accessToken: accessToken,
            page: 1,
            pageSize: 1,
            search: normalizedSearch,
            status: status == 'all' ? null : status,
            bookingDate: normalizedDate,
          );
          return MapEntry<String, int?>(status, res.pagination.total);
        } catch (_) {
          return MapEntry<String, int?>(status, null);
        }
      }),
    );

    for (final entry in entries) {
      if (entry.value != null) {
        result[entry.key] = entry.value!;
      }
    }
    return result;
  }
}
