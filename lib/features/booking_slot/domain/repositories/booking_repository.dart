import 'package:agriflow_admin/features/booking_slot/domain/entities/booking_item.dart';
import 'package:agriflow_admin/features/booking_slot/domain/entities/booking_pagination.dart';
import 'package:agriflow_admin/features/booking_slot/domain/entities/warehouse_item.dart';

abstract class BookingRepository {
  /// Fetches paginated bookings directly from FastAPI
  Future<({List<BookingItem> items, BookingPagination pagination})> getBookings({
    required String accessToken,
    int page = 1,
    int pageSize = 20,
    String? search,
    String? status,
  });

  /// Authoritatively updates booking status on backend
  Future<BookingItem> updateBookingStatus({
    required String accessToken,
    required String bookingId,
    required String newStatus,
    String? notes,
  });

  /// Records crop inspection (good/bad quantities) for a delivered booking.
  Future<void> inspectBooking({
    required String accessToken,
    required String bookingId,
    required double goodQuantityKg,
    required double badQuantityKg,
    String? rejectionReason,
    String? notes,
  });

  /// Fetches warehouses for lookup
  Future<List<WarehouseItem>> getWarehouses({
    required String accessToken,
  });

  /// Fetches farmers map for relationship enrichment
  Future<Map<String, ({String name, String phone})>> getFarmerLookup({
    required String accessToken,
  });
}
